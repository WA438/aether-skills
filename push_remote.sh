#!/bin/bash
# 把本仓库推送到你自己的远程 Git 仓库
# 用法:
#   bash push_remote.sh https://github.com/你的用户名/仓库名.git
# 无代理时，脚本会自动尝试加速镜像前缀
#
# 安全提示：不要在聊天窗口、截图或代码注释里粘贴你的 Token。

set -euo pipefail

REMOTE_URL="${1:-}"

if [ -z "$REMOTE_URL" ]; then
    echo "用法: bash push_remote.sh <远程仓库地址>"
    echo "示例: bash push_remote.sh https://github.com/xiaomiao/aether-skills.git"
    exit 1
fi

cd "$(dirname "$0")"

echo "==> 配置远程地址"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"
git branch -M main

echo "==> 尝试直连推送"
if git push -u origin main 2>/tmp/push_err.log; then
    echo "推送成功：$REMOTE_URL"
    exit 0
fi

echo "直连失败，错误如下："
tail -3 /tmp/push_err.log
echo
echo "==> 尝试国内加速镜像"

# 把 https://github.com/用户/仓库.git 改写成镜像前缀形式
BODY="${REMOTE_URL#https://}"
for MIRROR in "https://ghfast.top/https://" "https://gh-proxy.com/https://" "https://mirror.ghproxy.com/https://" "https://gh.llkk.cc/https://"; do
    ALT="${MIRROR}${BODY}"
    echo "尝试: $ALT"
    git remote set-url origin "$ALT"
    if git push -u origin main 2>/tmp/push_err2.log; then
        echo "推送成功（走镜像 $MIRROR）"
        echo "提示：后续日常推送建议仍用原地址，镜像仅用于首次上传"
        exit 0
    fi
done

echo
echo "全部镜像均失败。最后错误："
tail -5 /tmp/push_err2.log
echo
echo "备选方案："
echo "  1. 用 Gitee 中转：在 Gitee 新建空仓库，然后"
echo "     bash push_remote.sh https://gitee.com/你的用户名/仓库名.git"
echo "     再在 Gitee 仓库里点「导入 GitHub」或用其同步功能"
echo "  2. 直接在网页端手动上传本目录文件"
exit 1
