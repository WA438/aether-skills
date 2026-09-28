---
name: docker-container
description: Docker 容器管理。当用户提到 Docker、容器创建启停、镜像拉取构建、docker-compose、容器日志、容器迁移、卷管理、端口映射时使用。
version: 1.0
---

# Docker 容器管理

## 一、环境检查

```bash
docker version
docker info | head -20
systemctl is-active docker
df -h /var/lib/docker     # 容器很吃磁盘
```

## 二、镜像

```bash
docker images
docker pull 镜像:标签
docker build -t 名称:标签 .
docker rmi 镜像ID          # 删除前确认无容器依赖
docker image prune -a      # 清理悬空镜像（会删未使用镜像，先确认）
```

国内拉取慢 → 配镜像加速：
```bash
cat > /etc/docker/daemon.json <<'EOF'
{ "registry-mirrors": ["https://docker.m.daocloud.io"] }
EOF
systemctl restart docker
```

## 三、容器生命周期

```bash
docker run -d --name 名称 --restart=always \
  -p 宿主端口:容器端口 \
  -v 宿主目录:容器目录 \
  镜像:标签

docker ps -a
docker start/stop/restart 名称
docker rm -f 名称          # 高危：会丢容器内未持久化数据，先确认
docker logs 容器 --tail 100 -f
docker exec -it 容器 /bin/bash
docker stats               # 资源占用
```

## 四、数据与迁移

```bash
docker volume ls
docker volume inspect 卷名
# 备份卷
docker run --rm -v 卷名:/data -v $(pwd):/backup alpine tar czf /backup/卷.tar.gz /data
# 恢复
docker run --rm -v 卷名:/data -v $(pwd):/backup alpine tar xzf /backup/卷.tar.gz -C /
```

容器迁移：导出镜像 `docker save 镜像 -o 镜像.tar` → 目标机 `docker load -i 镜像.tar`，卷数据单独备份。

## 五、compose

```bash
docker compose up -d
docker compose ps
docker compose logs -f --tail 100
docker compose config      # 校验 yml 语法
docker compose down        # 高危：会删容器
```

## 六、排错

```bash
docker logs 容器 2>&1 | tail -50      # 看应用日志
docker inspect 容器 | grep -A5 State  # 看退出码
journalctl -u docker -n 50 --no-pager
```
常见：端口被占（`ss -tulnp`）、磁盘满（`df -h` + `docker system df`）、权限（加 `sudo` 或加入 docker 组）、`--restart` 未设导致开机不起。

## 七、输出规范

命令可一键复制；`rm -f` / `down` / `prune` 一类先确认；贴真实输出。
