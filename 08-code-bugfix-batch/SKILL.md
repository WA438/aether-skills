---
name: code-bugfix-batch
description: 代码诊断与批量 Bug 修复。当用户要求批量修 BUG、一次性改多处代码、合并改动一次编译、读源码找缺陷、解析编译报错、语法检查、评估改动是否触发回滚时使用。
version: 1.0
---

# 代码诊断与批量 Bug 修复

## 一、铁律：批量优先，拒绝逐个来回

- 一次读完相关文件，列出**全部**问题点，给出完整修改清单
- 所有改动合并成**一次编译**，禁止改一处刷一次
- 用户中途打断提问 → 简短回答后从断点继续，不丢弃已列出的清单

## 二、诊断流程

```
读源码 → 定位缺陷 → 分析根因 → 批量修改 → 一次性编译 → 读日志验证
```

**禁止** shotgun editing（没搞清根因就到处乱改）。每个改动必须能说清"为什么这样改"。

## 三、读码与定位

```bash
# 搜符号/调用
grep -rn "函数名" --include="*.c" --include="*.h" 项目/
grep -rn "关键字" 项目/ | head -40

# 找定义
grep -rn "#define 宏" 项目/

# 语法检查（不编译）
gcc -fsyntax-only 文件.c
python3 -m py_compile 脚本.py
shellcheck 脚本.sh
```

## 四、批量修改方法

```bash
# 单个文件内批量替换（先备份）
cp 文件 文件.bak.$(date +%F)
sed -i 's/旧/新/g' 文件

# 跨文件批量（先干跑确认范围）
grep -rl "旧内容" 目录/          # 先列出会被改的文件
grep -rl "旧内容" 目录/ | xargs sed -i.bak 's/旧内容/新内容/g'

# 对比确认
diff -u 文件.bak 文件
```

ESP-IDF 项目改动后：
```bash
idf.py build 2>&1 | tee build.log
grep -E "error|Error" build.log
```

## 五、编译报错解析

| 报错 | 根因 |
|---|---|
| `undefined reference to` | 缺实现或没链接对应库，查 CMakeLists 依赖 |
| `implicit declaration of function` | 缺头文件 |
| `error: too few arguments` | API 版本不匹配，查当前 IDF 版本的签名 |
| `region 'flash' overflowed` | 固件超限，减字库/日志/开编译优化 |
| `dram0_0_seg' overflowed` | RAM 不足，减静态缓冲/栈 |
| `conflicting types` | 重复定义或类型不一致 |

原则：贴**完整报错原文**再分析，禁止凭猜测重试。

## 六、改动前风险评估（ESP32 专项）

每次批量改动前必须回答：
1. 会不会触发固件回滚？（破坏性改动 → 高风险）
2. 固件体积是否逼近分区上限？
3. 是否触碰分区表 / NVS？若是，需说明迁移影响
4. 是否改了 ISR / FreeRTOS 优先级 / 共享总线（I2C/SPI）并发？

评估结论写入改动记录。

## 七、改动记录格式

```markdown
| 文件:行号 | 原内容 | 改为 | 根因 | 风险 |
|---|---|---|---|---|
| ui/menu.c:45 | scroll += 2 | scroll += 1 | 一次跳两行 | 低 |
```

## 八、输出规范

先给问题清单（编号），再给完整代码/补丁，最后给验证命令；全程中文，标识符保持英文。
