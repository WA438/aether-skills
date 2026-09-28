---
name: network-diagnosis
description: 网络连通性诊断。当用户提到网络不通、SSH 连不上、隧道掉线、端口不通、DNS 解析失败、路由异常、网卡掉线、Tailscale/Cloudflare/花生壳连不上、ESP32 连不上 WiFi 时使用。
version: 1.0
---

# 网络诊断

## 一、分层排查法（严格自下而上）

```
物理/链路 → IP 地址 → 路由 → DNS → 端口 → 应用层
```
**禁止跳步**。上层通了就不用往下查，上层不通必须回到下层定位。

## 二、逐层命令

```bash
# 1. 网卡与地址
ip -brief addr show
ip link show              # 看是否 UP / NO-CARRIER
ethtool 网卡名 | head     # 物理链路

# 2. 路由
ip route
ip route get 8.8.8.8      # 看实际走哪条

# 3. 连通
ping -c4 -W2 网关IP       # 先内网
ping -c4 -W2 223.5.5.5    # 再外网（绕过 DNS）
ping -c2 -W2 www.baidu.com # 最后域名（验 DNS）

# 4. DNS
cat /etc/resolv.conf
nslookup 域名
dig 域名 +short

# 5. 端口
ss -tulnp                 # 本机监听
ss -tulnp | grep 36000
nc -zv 目标IP 端口        # 远程端口
telnet 目标IP 端口
curl -v telnet://IP:端口

# 6. 路径
traceroute -n 目标        # 或 tracepath
mtr -n -c 20 目标
```

判定逻辑：
- 内网通、外网不通 → 网关/路由/运营商问题
- IP 通、域名不通 → DNS 问题
- 端口不通 → 服务未监听或被防火墙拦

## 三、防火墙检查

```bash
iptables -L -n -v | head -30
iptables -L -n -v | grep -E 'DROP|REJECT'
ufw status verbose
firewall-cmd --list-all
```

## 四、穿透三件套专项

```bash
# 状态
systemctl is-active cloudflared phddns tailscaled

# 日志
journalctl -u cloudflared -n 50 --no-pager
journalctl -u phddns -n 50 --no-pager

# Cloudflare 隧道
cloudflared tunnel list
cloudflared tunnel info 隧道名

# Tailscale
tailscale status
tailscale ping 对端IP
tailscale netcheck        # 查 NAT 类型与 DERP
```

## 五、SSH 连不上专项

```bash
# 服务端
systemctl status ssh sshd
ss -tulnp | grep -E '36000|:22'
journalctl -u ssh -n 50 --no-pager
sshd -t                   # 配置语法

# 客户端
ssh -vvv -p 36000 用户@IP   # 详细握手过程
ssh -o ConnectTimeout=5 用户@IP
```

常见原因：端口错、服务未起、防火墙拦、密钥权限（`.ssh` 700 / 私钥 600）、`AllowUsers` 限制、SELinux。

## 六、ESP32 网络

```bash
# 串口看 WiFi 状态
idf.py -p PORT monitor | grep -iE 'wifi|ip|disconnect|reason'
```
常见：`WIFI_REASON_AUTH_FAIL`（密码错）、`NO_AP_FOUND`（找不到热点/信道）、`ASSOC_LEAVE`（被踢）。
先确认 2.4GHz（ESP32 不支持 5G）、信道 1-11、供电足（brownout 会导致 WiFi 反复掉线）。

## 七、断线处理原则

SSH 或网络中断时：**如实上报状态，等恢复，不要反复重连消耗资源**。

## 八、输出规范

按层给结论（哪一层断的）；贴真实命令输出；修复方案注明影响范围与是否可逆。
