---
name: risk-safety-check
description: 风险校验与安全检查。在执行格式化、系统覆盖、删除核心文件、修改底层代码、刷写固件、重启关键服务前使用；也用于校验命令输出真实性、磁盘设备名核对、变更风险评估。
version: 1.0
---

# 风险校验与安全检查

## 一、高危操作二次确认（硬性）

以下命令**执行前必须停下**，说明对象、风险、影响范围，等待明确批准：

| 类别 | 命令 |
|---|---|
| 磁盘 | `mkfs.*`、`parted/ fdisk` 写操作、`dd of=/dev/sdX`、`wipefs` |
| 删除 | `rm -rf`（尤其带变量或通配）、`find -delete` |
| 系统 | 重装、覆盖 `/etc` 核心配置、`update-initramfs`、`grub-install` 到非目标盘 |
| 权限 | 批量 `chmod -R` / `chown -R` 于系统路径 |
| 服务 | `systemctl stop/disable` 关键服务（ssh、网络、面板） |
| 固件 | `idf.py flash`、`esptool.py write_flash`、分区表改写 |

确认话术模板：
> 即将执行：`命令原文`
> 目标对象：`具体盘符/路径/端口`
> 影响范围：`会破坏什么`
> 是否可逆：`是/否，回滚方案`
> 请确认后我再执行。

## 二、磁盘设备名校验

任何磁盘操作前必须跑完这三条并读出结果：

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL
blkid
df -h | grep -vE 'tmpfs|udev'
```

校验规则：
- 用 **UUID / LABEL / 挂载点**三重确认，不靠 `/dev/sdX` 序号
- 盘序可能在重启后变化，硬编码 `sda/sdb` 是重大风险源
- 目标盘上有数据 → 视为只读，先备份再动

## 三、SSH 防锁死校验

修改 sshd 或防火墙的强制流程：

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F)
# 修改后
sshd -t                      # 无输出才通过，有报错立即回滚
systemctl reload ssh         # reload 而非 restart
```
**保持当前会话不断开** → 另开新连接验证 → 能进才算完成 → 失败立即从备份还原。

防火墙同理：`iptables-restore -t 规则文件` 先测试，或 `firewall-cmd --check-config`。

## 四、代码修改风险评估

改底层代码前必须回答：

1. 会不会触发 ESP32 固件回滚？
2. 会不会导致服务器服务离线？
3. 改动是否可逆？回滚方案是什么？
4. 涉及哪些资源约束（分区表、栈大小、RAM/flash 预算）？
5. 是否需要重新编译整个固件还是局部改动？

风险等级：低 / 中 / 高。高风险必须走二次确认。

## 五、结果真实性校验（零容忍）

- **禁止**编造命令输出、编译日志、测试结果
- 执行失败 → 贴**真实报错原文**，再分析根因
- 无法执行 → 说明原因（权限/网络/硬件限制），不伪装成功
- 硬件或系统限制导致无法实现 → 如实说明并给替代方案

## 六、批量操作前的干跑

```bash
# 先干跑看影响范围
rsync -aAXvn /源/ /目标/          # -n 只显示不改
find 目录 -name "*.log"           # 先列再删
tar -tzf 备份.tar.gz | head       # 先看内容再解
```

## 七、输出规范

风险提示放在最前面；确认前不执行；失败如实上报，附原始报错。
