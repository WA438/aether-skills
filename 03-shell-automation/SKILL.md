---
name: shell-automation
description: Shell 脚本与自动化。当用户要求写脚本、批量执行、一键部署、自动化任务、日志提取过滤、批量拷贝、批量改权限、配置文件 diff、后台任务挂起、nohup、tmux、定时执行时使用。
version: 1.0
---

# Shell 命令与脚本自动化

## 一、脚本编写规范（硬性）

每个脚本开头必须带安全头：

```bash
#!/bin/bash
set -euo pipefail    # 出错即停、未定义变量报错、管道失败可捕获
IFS=$'\n\t'
```

其他要求：
1. **绝对路径**，不依赖当前工作目录
2. 关键操作前 `echo` 说明即将做什么
3. 涉及删除/覆盖，先 `cp f f.bak.$(date +%F)`
4. 输出结构化分段，便于复制结果
5. 变量加引号：`"$var"`，防空格截断
6. 只读检查与写操作分成不同脚本，方便先干跑

## 二、批量执行

```bash
# 批量改权限
find /目标 -type f -name "*.sh" -exec chmod +x {} \;
find /目标 -type d -exec chmod 755 {} \;

# 批量拷贝（保留属性）
rsync -aAXv /源/ /目标/

# 批量替换（先备份再改）
grep -rl "旧内容" /目录 | xargs sed -i.bak 's/旧内容/新内容/g'

# 配置对比
diff -u 旧.conf 新.conf
diff -rq 目录A 目录B
```

## 三、后台任务管理

```bash
# 方式一：nohup
nohup 命令 > /tmp/任务.log 2>&1 &
echo $! > /tmp/任务.pid

# 方式二：tmux（可随时切回查看，推荐长任务）
tmux new -s 任务名 -d '命令'
tmux ls                    # 列任务
tmux attach -t 任务名       # 进入
tmux kill-session -t 任务名 # 结束

# 查看进度
tail -f /tmp/任务.log
ps -p $(cat /tmp/任务.pid) >/dev/null && echo "运行中" || echo "已结束"

# 暂停 / 恢复
kill -STOP $(cat /tmp/任务.pid)
kill -CONT $(cat /tmp/任务.pid)
```

铁律：长任务**绝不自行中断**。用户打断提问时，简短回答后从断点继续。

## 四、日志解析

```bash
# 提取错误段
grep -nE "error|fail|panic|refused|timeout" 日志 -i
# 上下文（报错前后 5 行）
grep -nE "error" 日志 -i -A5 -B5
# 时间段过滤
journalctl --since "2026-09-29 01:00" --until "02:00"
journalctl -u 服务 -n 100 --no-pager
# 统计高频错误
grep -oE "error[^,]*" 日志 | sort | uniq -c | sort -rn | head -20
# 只看最新
tail -f -n 200 日志
```

分级原则：**致命**（服务退出、panic、拒绝连接）→ **警告**（重试、降级）→ **可忽略**（INFO 噪声）。报告时分开列。

## 五、定时执行

```bash
# crontab
crontab -l
crontab -e
# 每天 3 点备份
0 3 * * * /脚本/backup.sh >> /var/log/backup.log 2>&1
# systemd timer（更推荐，可查状态）
systemctl list-timers
```

## 六、输出规范

脚本必须一键可复制、可直接运行，不出现省略号占位；运行前说明会改动什么；运行后贴真实输出。
