---
name: nginx-reverse-proxy
description: Nginx 反向代理与站点配置。当用户提到 Nginx、反向代理、站点配置、SSL 证书、404/502/504 排错、负载均衡、域名绑定、location 规则时使用。
version: 1.0
---

# Nginx 反向代理与站点配置

## 一、铁律：改前校验，改后 reload

```bash
nginx -t                       # 语法校验，无输出才通过
cp 配置 配置.bak.$(date +%F)    # 备份
systemctl reload nginx         # reload 而非 restart，不断连接
```
校验失败立即还原备份，**禁止**在校验未通过时重载。

## 二、反向代理模板

```nginx
server {
    listen 80;
    server_name 域名;

    location / {
        proxy_pass http://127.0.0.1:后端端口;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_read_timeout    300s;
        proxy_send_timeout    300s;
    }
}
```

WebSocket 需额外加：
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## 三、SSL

```bash
# 证书（certbot）
certbot --nginx -d 域名
certbot renew --dry-run
```
```nginx
listen 443 ssl http2;
ssl_certificate     /etc/letsencrypt/live/域名/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/域名/privkey.pem;
```

## 四、常见故障定位

| 现象 | 原因与排查 |
|---|---|
| 404 | location 未匹配 / root 路径错；`nginx -T` 看生效配置 |
| 502 | 后端没起来或端口错；`ss -tulnp \| grep 端口` + 后端日志 |
| 504 | 后端超时；加大 `proxy_read_timeout` |
| 403 | 目录权限或 `autoindex` 未开；`namei -l 路径` 查权限链 |
| 证书报错 | 证书链不全/过期；`openssl x509 -in 证书 -noout -dates` |
| 改了不生效 | 没 reload，或有多个 conf 冲突；`nginx -T \| grep server_name` |

## 五、日志

```bash
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
awk '{print $9}' access.log | sort | uniq -c | sort -rn | head   # 状态码统计
```

## 六、宝塔环境注意

宝塔面板托管的站点配置在 `/www/server/panel/vhost/nginx/`，**不要直接改主配置**，改了可能被面板覆盖。改完用面板重载或 `nginx -t` 后 reload。

## 七、输出规范

配置块完整可复制；先 `nginx -t` 再 reload；贴真实输出；全程中文。
