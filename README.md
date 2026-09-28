# Aether 技能包仓库

面向 **J1900 服务器运维 + ESP32 掠夺者固件开发** 的 Aether（扶摇）Agent Skills 集合。

## 快速导入

### 方式一：Zip（推荐）

`_zips/` 目录下有 11 个独立 zip。在 Aether 中进入
**Agent 技能 → 选 Zip → 选中对应文件 → 确认**，每个包重复一次。

### 方式二：文件夹

把本仓库克隆到手机，进入 **Agent 技能 → 选文件夹 → 选中编号目录 → 确认**。

> 若报 `No SKILL.md file was found`，说明选错了层级（多包了一层目录），
> 请直接选到含 `SKILL.md` 的那一层。

## 技能包清单

### 核心必备（建议全装）

| 目录 | 名称 | 用途 |
|---|---|---|
| `01-linux-server-ops` | linux-server-ops | 磁盘分区/格式化/fstab、debootstrap chroot 部署、跨盘迁移、GRUB 引导修复、备份恢复、静态 IP、SSH 全套迁移、穿透三件套、服务排错。含 `scripts/verify.sh` |
| `02-esp32-raider-firmware` | esp32-raider-firmware | ST7789 240×240 屏幕与 UI、中文 UTF-8 渲染、按键/SD 引脚冲突、WiFi 扫描与 Deauth、BLE 主动扫描、编译烧录回滚、Telnet+串口双路调试。含 `scripts/detect.sh` |
| `03-shell-automation` | shell-automation | 脚本规范、批量执行、nohup/tmux 后台任务挂起恢复、日志分级解析、定时任务 |
| `04-git-repo-manager` | git-repo-manager | 分支管理、安全回滚、无代理镜像克隆、SSH 密钥、打包与下载直链 |
| `05-project-doc-task` | project-doc-task | 任务三态清单（已完成/待验证/阻塞）、版本变更四要素、精简版+完整版双报告 |
| `06-risk-safety-check` | risk-safety-check | 高危操作二次确认、磁盘设备三重校验、SSH 防锁死、结果真实性零容忍 |
| `07-network-diagnosis` | network-diagnosis | 六层排障法、穿透三件套专项、SSH 与 ESP32 网络分支诊断 |
| `08-code-bugfix-batch` | code-bugfix-batch | 批量定位缺陷、合并改动一次编译、编译报错对照表、回滚风险评估 |

### 可选扩展

| 目录 | 名称 | 用途 |
|---|---|---|
| `09-docker-container` | docker-container | 容器/镜像/数据卷/迁移/排错 |
| `10-nginx-reverse-proxy` | nginx-reverse-proxy | 反向代理模板、SSL、404/502/504 定位 |
| `11-archive-package` | archive-package | zip/tar 规范、技能包打包校验、加速直链生成 |

## 技能包结构

```
包名/
├── SKILL.md        # 必需，必须在包根目录
└── scripts/        # 可选，附带的脚本
```

`SKILL.md` 顶部 YAML 的 `description` 决定触发时机。若某个包未被唤起，
在对话中使用更明确的关键词（如直接说「磁盘」「Deauth」「回滚」）。

## 前置依赖

技能包是行为说明书，不含可执行程序。Alpine 环境需先装好工具：

```bash
apk add openssh-client python3 py3-pip git tmux rsync
pip3 install esptool
```

## 配套自定义指令

仓库中的 `CUSTOM_INSTRUCTION.md` 是配套的 Aether 自定义指令（系统提示词），
粘贴到 **个性化 → 自定义指令** 中使用，与技能包配合效果最佳。
