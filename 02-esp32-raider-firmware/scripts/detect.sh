#!/bin/bash
# ESP32 硬件识别与环境检测
# 用法: bash detect.sh [串口]
# 说明: 只读检测，不刷写任何内容

PORT="${1:-/dev/ttyUSB0}"

echo "===== 一、串口设备列表 ====="
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "未发现串口设备，检查数据线与驱动"

echo
echo "===== 二、工具链检测 ====="
for t in esptool.py idf.py pio; do
    printf "%-12s %s\n" "$t:" "$(command -v $t || echo '未安装')"
done

echo
echo "===== 三、芯片信息（端口 $PORT）====="
if command -v esptool.py >/dev/null 2>&1; then
    esptool.py -p "$PORT" chip_id 2>&1 | tail -6
    echo "--- Flash ID ---"
    esptool.py -p "$PORT" flash_id 2>&1 | tail -6
else
    echo "esptool.py 未安装，执行: pip3 install esptool"
fi

echo
echo "===== 四、串口日志（10 秒，Ctrl+C 可提前退出）====="
echo "提示: 观察是否有 brownout / panic / rst cause 等关键字"
timeout 10 cat "$PORT" 2>/dev/null | head -60 || echo "无法读取串口，端口可能被占用或权限不足"

echo
echo "===== 五、常用排错关键字对照 ====="
cat <<'EOF'
Brownout detector was triggered  -> 供电不足，换电源/加电容，不是代码问题
Guru Meditation Error            -> 看 Core 号与寄存器，多为栈溢出或非法访问
Task watchdog got triggered      -> 任务阻塞未喂狗
rst:0x7 (TG0WDT_SYS_RST)         -> 看门狗复位
rst:0x3 (SW_RESET)               -> 软件复位，正常
partition table                  -> 分区表不匹配，检查 partitions.csv
heap / out of memory             -> 堆耗尽
EOF
