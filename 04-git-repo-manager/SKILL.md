---
name: git-repo-manager
description: Git 仓库与代码版本管理。当用户提到 git 拉取、提交、推送、分支、合并、冲突、回滚、打标签、克隆仓库、代理配置、密钥配置、打包代码成 zip、生成下载链接时使用。
version: 1.0
---

# Git 仓库管理

## 一、日常操作

```bash
git status                  # 先看状态
git diff                    # 看未暂存改动
git add 文件 && git commit -m "说明"
git pull --rebase           # 优先 rebase，减少无用合并
git push
```

铁律：
- 提交前必须 `git status` + `git diff` 确认改动内容
- **禁止** `git push --force` 到共享分支，除非用户明确要求
- 涉及服务器配置的仓库，提交信息写清影响范围

## 二、分支管理

```bash
git branch -a               # 全部分支
git checkout -b 新分支       # 建并切
git switch 分支名            # 切换
git merge --no-ff 分支名     # 保留合并记录
git branch -d 分支名         # 删除（已合并）
```

固件项目建议分支约定：
- `main` 稳定可刷版本
- `dev` 日常开发
- `fix/功能名` 单个 Bug 修复

## 三、回滚与标签

```bash
git log --oneline -20                 # 找提交
git revert 提交号                      # 安全回滚（推荐，保留历史）
git reset --hard 提交号                # 危险，会丢弃改动，需确认
git tag -a v1.0 -m "说明" && git push --tags
git checkout v1.0                     # 切到某个版本
```

## 四、代理与密钥（国内访问 GitHub）

```bash
# 走 HTTP 代理（有代理时）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
# 取消
git config --global --unset http.proxy
git config --global --unset https.proxy

# 走镜像加速（无代理时推荐）
git clone https://ghfast.top/https://github.com/用户/仓库.git
git clone https://gh-proxy.com/https://github.com/用户/仓库.git

# SSH 密钥
ssh-keygen -t ed25519 -C "邮箱"
cat ~/.ssh/id_ed25519.pub    # 加到 GitHub
ssh -T git@github.com        # 验证
```

## 五、打包与下载链接（适配 Agent 导入）

```bash
# 打包整个仓库
git archive --format=zip --output=项目.zip HEAD

# 只打包某个子目录（技能包常用）
cd 目录 && zip -r ../技能包.zip . && cd -

# 排除干扰文件
zip -r 项目.zip 项目/ -x "*.git/*" "*/node_modules/*" "*/build/*"
```

生成直链：传到 GitHub Release 后取 `browser_download_url`；无代理时用 `ghfast.top/` 前缀拼原链接。

## 六、技能包打包规范（重要）

Agent 技能导入界面要求 **`SKILL.md` 位于压缩包根目录**：

```bash
cd 技能包目录
zip -r ../包名.zip .        # 注意是 '.'，不要多包一层目录
unzip -l ../包名.zip        # 校验：应直接看到 SKILL.md，而非 目录/SKILL.md
```

多包一层目录会报 `No SKILL.md file was found`。

## 七、输出规范

命令可一键复制；危险的回滚/强推先说明风险并等待确认；失败贴真实报错原文。
