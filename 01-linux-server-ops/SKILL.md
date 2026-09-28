---
name: linux-server-ops
description: Linux 服务器运维。当用户提到磁盘分区、格式化、mount、fstab、debootstrap、chroot、系统迁移、GRUB、启动项、备份恢复、静态IP、网卡、SSH 密钥与端口、宝塔、Nginx、Docker、Python 环境、Cloudflare 隧道、花生壳、Tailscale、systemd 服务排错时使用。
version: 1.0
---

# Linux 服务器运维

## 一、多硬盘安全（最高优先级）

每次涉及磁盘的写操作前必须执行并读出结果：

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL
blkid
```

铁律：
- 凭 `LABEL` / `UUID` / 挂载点确认目标，**禁止凭记忆猜 `/dev/sdX`**
- 有数据盘的盘（本项目为 `sdc`）一律视为只读保护对象
- 格式化、分区、覆盖系统文件 → 先说明对象、风险、影响范围，等待明确批准

**J1900 项目固定拓扑**

| 设备 | 角色 | 规则 |
|---|---|---|
| `sda` | 原系统 | 绝对禁止写入 |
| `sdb` | Ubuntu 22.04 新系统 | 主操作目标 |
| `sdc` | 云数据盘 | 备份存放地，只读保护 |

## 二、磁盘与分区

```bash
# 分区（GPT）
parted -s /dev/sdX mklabel gpt
parted -s /dev/sdX mkpart primary ext4 1MiB 100%
# 格式化
mkfs.ext4 -L 标签 /dev/sdXn
# 挂载
mount /dev/sdXn /mnt/target
# fstab 用 UUID（不用 /dev/sdX）
blkid /dev/sdXn
echo "UUID=xxx /mnt/target ext4 defaults,noatime 0 2" >> /etc/fstab
mount -a   # 验证，失败会报错
```

## 三、debootstrap chroot 部署 / 跨盘迁移

```bash
debootstrap --arch amd64 jammy /mnt/target http://archive.ubuntu.com/ubuntu
mount --bind /dev  /mnt/target/dev
mount --bind /proc /mnt/target/proc
mount --bind /sys  /mnt/target/sys
chroot /mnt/target /bin/bash
```

chroot 内必做：`apt update` → 装 `linux-image-generic` `grub-pc` `openssh-server` → `passwd` → `useradd`。

**GRUB 安装（务必指定目标盘）**
```bash
grub-install --boot-directory=/mnt/target/boot /dev/sdX
update-grub
```
装错盘会覆盖原系统引导，执行前必须口头确认盘符。

## 四、备份与恢复

```bash
# 全量备份（排除虚拟文件系统）
tar --numeric-owner -czpf /备份/系统_$(date +%F).tar.gz \
  --exclude=/proc --exclude=/sys --exclude=/dev \
  --exclude=/run --exclude=/mnt --exclude=/media \
  --exclude=/tmp --exclude=/var/cache/apt/archives /
# 增量备份
rsync -aAXHv --delete --link-dest=/备份/上一次 /源/ /备份/本次/
# 恢复
tar -xzpf 备份.tar.gz -C /mnt/target
```

恢复后必须重做：fstab UUID、GRUB、initramfs（`update-initramfs -u`）。

## 五、网络（静态 IP）

Ubuntu 22.04 用 netplan：
```bash
cat > /etc/netplan/01-net.yaml <<'EOF'
network:
  version: 2
  ethernets:
    网卡名:
      addresses: [192.168.31.71/24]
      routes:
        - to: default
          via: 192.168.31.1
      nameservers:
        addresses: [223.5.5.5, 8.8.8.8]
EOF
netplan try      # 有 120 秒回滚保护，优先用
netplan apply
```
`netplan try` 失败会自动回滚，比 `apply` 安全。

## 六、SSH 全套迁移

```bash
# 迁移前打包
tar -czpf ssh_backup.tar.gz /etc/ssh /root/.ssh /home/*/.ssh
# 新系统恢复
tar -xzpf ssh_backup.tar.gz -C /
chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_*; chmod 644 ~/.ssh/*.pub
# 改端口
sed -i 's/^#\?Port .*/Port 36000/' /etc/ssh/sshd_config
sshd -t          # 无输出才通过
systemctl reload ssh   # reload 而非 restart，保持会话
```

## 七、内网穿透三件套

```bash
systemctl is-active cloudflared phddns tailscaled   # 状态
systemctl enable --now cloudflared phddns tailscaled # 开机自启
journalctl -u cloudflared -n 50 --no-pager           # 排错
tailscale status; tailscale up --ssh                 # Tailscale
```

## 八、服务管理速查

| 目标 | 命令 |
|---|---|
| 宝塔 | `systemctl status bt`；`/etc/init.d/bt status` |
| Nginx | `nginx -t` → `systemctl reload nginx` |
| Docker | `docker ps -a`；`docker logs 容器 --tail 100` |
| Python | `python3 -m venv venv && source venv/bin/activate` |
| 通用排错 | `systemctl status X` + `journalctl -u X -n 100 --no-pager` |

## 九、输出规范

先结论后证据（贴真实输出）；记录改动位置/内容/风险/预期效果；标记【已完成】【待验证】【阻塞项】；全程中文。

## 十、附带脚本

`scripts/verify.sh` — 一键巡检：磁盘、网络、SSH、穿透、宝塔、备份完整性。
