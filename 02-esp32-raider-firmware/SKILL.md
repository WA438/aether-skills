---
name: esp32-raider-firmware
description: ESP32 掠夺者固件（小老虎终端）开发。当用户提到 ESP32、WROOM-32、ST7789、240x240、开机画面、锁屏、菜单、中文 SSID、按键、SD 卡、WiFi 扫描、Deauth、数据包监听、BLE 蓝牙扫描、esptool、idf.py、PlatformIO、固件回滚、Telnet 调试、远程截图、模拟按键时使用。
version: 1.0
---

# ESP32 掠夺者固件（小老虎终端）

## 一、硬件基线

- 主控：ESP32-WROOM-32
- 屏幕：ST7789 240×240
- 电平：3.3V，任何 5V 接线立即告警
- 调试：Telnet(23) + USB 串口双链路，最高底层权限

操作前先识别，禁止假设端口：
```bash
esptool.py chip_id -p PORT
esptool.py flash_id -p PORT
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```

## 二、屏幕驱动与 UI（240×240 强制）

1. 绘制前核验坐标落在 `0..239`，超出即裁剪报错
2. 禁止：错位、挤压、跳行、重影
3. 菜单**单步滚动**，一次只移一行
4. 开机画面 / 锁屏 / 菜单栏 / 功能页统一用一套布局常量，禁止散写魔数

**中文渲染（UTF-8 → Unicode 码点）**
```c
uint32_t utf8_to_unicode(const uint8_t* s, int* len) {
    uint8_t b0 = s[0];
    if (b0 < 0x80) { *len = 1; return b0; }
    if ((b0 & 0xE0) == 0xC0) { *len = 2; return ((b0 & 0x1F) << 6)  | (s[1] & 0x3F); }
    if ((b0 & 0xF0) == 0xE0) { *len = 3; return ((b0 & 0x0F) << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F); }
    *len = 1; return 0xFFFD;
}
```
字库**按需子集化**（常用 3500 字），全字库放不进 flash。

## 三、按键与 SD 卡（引脚冲突）

- 按键：GPIO 上拉输入 + 消抖，禁止在 ISR 里做耗时操作
- SD 卡与屏幕 RST 引脚存在硬件冲突 → 改引脚分配或分时复用，改前列出当前引脚表
- 所有引脚集中在一个 `pins.h`，禁止散落各处

## 四、WiFi 底层（真实数据）

扫描、Deauth、监听、防御统计——必须调用真实底层接口返回真实采集数据。
**禁止**伪造、模拟、硬编码假数据。

- 扫描：`esp_wifi_scan_start` + `esp_wifi_scan_get_ap_records`
- Deauth：目标可选，真实发包注入
- 监听：promiscuous 模式统计包量

## 五、BLE 蓝牙扫描（主动模式）

```c
esp_ble_scan_params_t p = {
    .scan_type          = BLE_SCAN_TYPE_ACTIVE,   // 原为 PASSIVE
    .own_addr_type      = BLE_ADDR_TYPE_PUBLIC,
    .scan_filter_policy = BLE_SCAN_FILTER_ALLOW_ALL,
    .scan_interval      = 0x50,
    .scan_window        = 0x30,
    .scan_duplicate     = BLE_SCAN_DUPLICATE_DISABLE
};
esp_ble_gap_set_scan_params(&p);
esp_ble_gap_start_scanning(0);   // 0 = 持续扫描
```
设备枚举走 `ESP_GAP_BLE_SCAN_RESULT_EVT` 回调，去重后再入列表。

## 六、编译 / 烧录 / 回滚

```bash
# ESP-IDF
idf.py set-target esp32 && idf.py menuconfig && idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
# PlatformIO
pio run -t upload && pio device monitor
```
两套工具链**不得混用**。

- 编译校验通过才允许刷写
- 刷写失败**自动回滚旧版本**，任何改动不得破坏此机制
- 每次改代码前评估：会不会触发回滚？尽量规避反复回滚
- 记录版本变更日志

## 七、双路调试与高级调试

- USB 串口：115200，`idf.py monitor` / `pio device monitor`
- Telnet(23)：网络调试，最高权限，可读写底层参数
- 待实现模块：远程屏幕截图、远程模拟按键（上/下/确认/退出）、代码模拟启动预览

## 八、故障排查（先读日志再下结论）

```bash
idf.py -p PORT monitor | tee boot.log
```
绝大多数"变砖"可恢复，没看日志前不得判定板子损坏。

| 日志关键字 | 根因 |
|---|---|
| `Brownout detector was triggered` | 供电不足，非代码问题 |
| `Guru Meditation Error` | 栈溢出 / 非法访问 |
| `Task watchdog got triggered` | 任务阻塞未喂狗 |
| `rst:0x7 (TG0WDT_SYS_RST)` | 看门狗复位 |
| `rst:0x3 (SW_RESET)` | 软件复位，正常 |
| strapping 引脚异常 | GPIO0/2/12/15 电平错误 |
| 分区相关报错 | partitions.csv 不匹配 |

## 九、资源约束

改动时显式考虑：RAM / flash 预算、分区表、任务栈大小、ISR 安全、FreeRTOS 优先级、I2C/SPI 总线并发。
涉及存储改动必须说明 NVS / 分区迁移影响。

## 十、输出规范

结论先行，贴真实日志或改动行；结构为「问题 → 改动 → 验证」；批量修改合并成一次编译；全程中文。

## 十一、附带脚本

`scripts/detect.sh` — 硬件识别 + 串口日志抓取 + panic 关键字对照。
