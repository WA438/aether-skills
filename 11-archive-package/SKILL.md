---
name: archive-package
description: 压缩打包与分发。当用户要求打包目录成 zip/tar、生成下载链接、适配 Agent 技能导入格式、排除无关文件、校验压缩包结构时使用。
version: 1.0
---

# 压缩打包与分发

## 一、zip

```bash
# 打包整个目录
zip -r 包名.zip 目录/

# 打包目录内容（不含外层目录）——技能包必须用这个
cd 目录 && zip -r ../包名.zip .

# 排除文件
zip -r 包名.zip 目录/ -x "*.git/*" "*/node_modules/*" "*/build/*" "*.DS_Store"

# 校验（关键）
unzip -l 包名.zip
```

## 二、tar

```bash
tar -czf 包名.tar.gz 目录/
tar -cjf 包名.tar.bz2 目录/     # 压缩率更高，慢
tar -tzf 包名.tar.gz | head     # 先看内容再解
tar -xzf 包名.tar.gz -C 目标目录
```

## 三、Agent 技能包打包规范（最重要）

导入界面要求 **`SKILL.md` 位于压缩包根目录**。

```bash
# 正确：在包内目录执行
cd 技能包目录
zip -r ../包名.zip .
unzip -l ../包名.zip
# 应看到: SKILL.md        ← 正确
# 若看到: 技能包目录/SKILL.md   ← 错误，会报 No SKILL.md file was found
```

**错误示范**：`zip -r 包名.zip 技能包目录/`（多包一层）。

最小技能包结构：
```
包名.zip
├── SKILL.md          # 必需，根目录
└── scripts/          # 可选
    └── xxx.sh
```

## 四、下载链接

```bash
# 本地起临时服务（同局域网可下）
python3 -m http.server 8000 -d 目录

# GitHub Release 直链格式
https://github.com/用户/仓库/releases/download/标签/文件名.zip

# 无代理加速前缀（拼在原链接前）
https://ghfast.top/https://github.com/...
https://gh-proxy.com/https://github.com/...
```

## 五、完整性校验

```bash
md5sum 包名.zip
sha256sum 包名.zip
unzip -t 包名.zip       # zip 完整性测试
```

## 六、输出规范

给出可直接复制的命令；打完包必须 `unzip -l` 校验结构；链接要完整可点。
