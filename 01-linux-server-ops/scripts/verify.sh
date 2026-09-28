#!/bin/bash
# J1900 新系统一键巡检脚本
# 用法: bash verify.sh
# 说明: 只读检查，不修改任何系统状态

echo "===== 一、主机身份 ====="
hostname; whoami; uname -a
grep PRETTY /etc/os-release

echo
echo "===== 二、磁盘挂载（确认 sda 未被误操作）====="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL

echo
echo "===== 三、网络（应有 .71 有线 / .240 无线）====="
ip -brief addr show
echo "--- 默认路由 ---"
ip route | grep default
echo "--- 外网连通 ---"
ping -c2 -W2 223.5.5.5 2>&1 | tail -2

echo
echo "===== 四、SSH（端口 36000）====="
ss -tulnp 2>/dev/null | grep -E '36000|:22'
systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null

echo
echo "===== 五、穿透三件套 ====="
for s in cloudflared phddns tailscaled; do
    printf "%-12s %s\n" "$s:" "$(systemctl is-active $s 2>/dev/null || echo '未运行/未安装')"
done
echo "--- Tailscale 节点 ---"
tailscale status 2>/dev/null | head -5

echo
echo "===== 六、宝塔面板 ====="
systemctl is-active bt 2>/dev/null || echo "宝塔服务: 未运行"
[ -f /www/server/panel/BT-Panel ] && echo "面板文件: 已安装" || echo "面板文件: 未安装"

echo
echo "===== 七、备份完整性（sdc）====="
ls -lhd /mnt/*/system_backup_20260929 /media/*/system_backup_20260929 2>/dev/null || echo "未找到备份目录，请确认 sdc 是否已挂载"

echo
echo "===== 八、资源占用 ====="
df -h | grep -vE 'tmpfs|udev'
echo "--- 内存 ---"
free -h
echo "--- 负载 ---"
uptime
