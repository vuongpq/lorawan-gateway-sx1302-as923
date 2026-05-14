# Tài liệu triển khai LoRaWAN Gateway WM1302 + Raspberry Pi 3 B+ (AS923 Việt Nam)

## 1. Mục tiêu
Tài liệu này hướng dẫn từng bước để triển khai gateway LoRaWAN dùng WM1302 của Seeed Studio với Raspberry Pi 3 B+, dựa trên project sx1302_hal đã được tùy biến.

Tài liệu cũng chỉ ra các file cần sửa/tạo mới để gateway hoạt động ở băng tần AS923 tại Việt Nam.

## 2. Tóm tắt các tùy biến đã có trong project
Project hiện tại đã có các tùy biến quan trọng:

1. Đã map chân reset theo phần cứng thực tế:
- SX1302_RESET_PIN = 17
- SX1302_POWER_EN_PIN = 18
- SX1261_RESET_PIN = 5
- AD5338R_RESET_PIN = 13

2. Đã có script reset mới dùng pinctrl:
- packet_forwarder/reset_lgw.sh
- util_chip_id/reset_lgw.sh

3. Đã có file cấu hình chạy thực tế:
- packet_forwarder/global_conf.json

## 3. Yêu cầu phần cứng và phần mềm

### 3.1. Phần cứng
- Raspberry Pi 3 Model B+
- Module WM1302 (SPI variant)
- Ăng-ten phù hợp AS923
- Nguồn ổn định cho Raspberry Pi

### 3.2. Hệ điều hành
- Raspberry Pi OS (Bullseye/Bookworm)

### 3.3. Gói phụ thuộc cần cài
Chạy trên Raspberry Pi:

```bash
sudo apt update
sudo apt install -y git build-essential pkg-config
```

Nếu dùng Raspberry Pi OS mới, nên bảo đảm có công cụ pinctrl:

```bash
pinctrl -h
```

Nếu lệnh trên không tồn tại, cập nhật hệ và cài các gói GPIO phù hợp bạn đang dùng.

## 4. Bật các giao tiếp cần thiết trên Raspberry Pi
Bật SPI bằng raspi-config:

```bash
sudo raspi-config
```

- Interface Options -> SPI -> Enable
- Nếu có GPS ngoài, bật UART tùy hệ thống

Khởi động lại:

```bash
sudo reboot
```

Sau khi reboot, kiểm tra:

```bash
ls -l /dev/spidev0.0 /dev/spidev0.1
```

## 5. Cài driver WM1302 (sx1302_hal)
Clone repo chính thức:

```bash
git clone https://github.com/Lora-net/sx1302_hal.git
```

Vào thư mục:

```bash
cd sx1302_hal
```

Trong thư mục `sx1302_hal`:

```bash
make clean
make
```

Sau khi build, binary packet forwarder nằm ở:
- packet_forwarder/lora_pkt_fwd

## 6. Các file cần sửa/tạo để gateway chạy được

### 6.1. File reset chung cho project
File cần sửa:
- tools/reset_lgw.sh

Vai trò:
- Không phải file bắt buộc cho luồng chạy packet forwarder hằng ngày.
- Chủ yếu để tương thích với các util/test trong repo (nhiều chương trình gọi `./reset_lgw.sh start|stop`).

Nội dung map chân đã đúng cho bộ WM1302 + RPi 3 B+ trong project:

```sh
SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
SX1261_RESET_PIN=5
AD5338R_RESET_PIN=13
```

Script này đang dùng sysfs GPIO. Nếu hệ điều hành vẫn hỗ trợ, có thể sử dụng bình thường.

### 6.2. File reset để chạy packet forwarder
File cần tạo/sửa:
- packet_forwarder/reset_lgw.sh

Vai trò:
- Đây là file reset bạn cần dùng khi vận hành gateway thực tế với `lora_pkt_fwd`.
- Nếu chỉ triển khai gateway (không chạy test/util khác), chỉ cần file này là đủ.

Bạn nên dùng phiên bản pinctrl (đã có sẵn trong project), vì gọn và tương thích tốt với Raspberry Pi OS mới.

Cấp quyền thực thi:

```bash
chmod +x packet_forwarder/reset_lgw.sh
chmod +x tools/reset_lgw.sh
```

### 6.3. File cấu hình packet forwarder cho AS923 Việt Nam
File chính cần sử dụng:
- packet_forwarder/global_conf.json

Nếu cần tạo mới từ template, có thể copy từ mẫu AS923 rồi đổi sang SPI:

```bash
cp packet_forwarder/global_conf.json.sx1250.AS923.USB packet_forwarder/global_conf.json
```

Sau đó sửa các trường:

1. Giao tiếp concentrator (SPI):

```json
"com_type": "SPI",
"com_path": "/dev/spidev0.0",
"spi_speed": 2000000,
```

2. Giao tiếp SX1261 (nếu dùng):

```json
"sx1261_conf": {
  "spi_path": "/dev/spidev0.1",
  ...
}
```

3. Cấu hình tần số AS923 Việt Nam (khuyến nghị theo file hiện tại):

```json
"radio_0": {
  "freq": 923200000,
  "tx_freq_min": 920000000,
  "tx_freq_max": 925000000
},
"radio_1": {
  "freq": 924200000
},
"chan_multiSF_0": {"enable": true, "radio": 0, "if": -200000},
"chan_multiSF_1": {"enable": true, "radio": 0, "if": 0},
"chan_multiSF_2": {"enable": true, "radio": 0, "if": 200000},
"chan_multiSF_3": {"enable": true, "radio": 0, "if": 400000},
"chan_multiSF_4": {"enable": true, "radio": 1, "if": -200000},
"chan_multiSF_5": {"enable": true, "radio": 1, "if": 0},
"chan_multiSF_6": {"enable": true, "radio": 1, "if": 200000},
"chan_multiSF_7": {"enable": true, "radio": 1, "if": 400000}
```

4. Cấu hình kết nối network server:

```json
"gateway_ID": "<EUI_16_HEX>",
"server_address": "<IP_HOAC_DOMAIN_NS>",
"serv_port_up": 1700,
"serv_port_down": 1700
```

5. Beacon (nếu không dùng Class B, để 0 chu kỳ là ổn):

```json
"beacon_period": 0,
"beacon_freq_hz": 923400000
```

Lưu ý:
- Giữ comments trong JSON là được đối với project này.
- Nếu dùng công cụ JSON strict bên ngoài, comments có thể báo lỗi, nhưng lora_pkt_fwd vẫn parse được.

### 6.4. Phân tích chi tiết 2 file mới

#### 6.4.1. Phân tích packet_forwarder/reset_lgw.sh

Mục tiêu của script:
- Khởi tạo lại trạng thái phần cứng CoreCell trước khi start packet forwarder.
- Bảo đảm SX1302, SX1261 và ADC reset theo đúng thứ tự để tránh treo SPI/radio.

Ý nghĩa các biến chân GPIO:
- `SX1302_RESET_PIN=17`: chân reset chip concentrator SX1302.
- `SX1302_POWER_EN_PIN=18`: chân cấp nguồn cho khối CoreCell.
- `SX1261_RESET_PIN=5`: chân reset SX1261 (LBT/spectral scan).
- `AD5338R_RESET_PIN=13`: chân reset ADC/DAC trên board tham chiếu.

Trình tự xử lý trong script:
1. Đặt tất cả chân về mode output bằng `pinctrl set <pin> op`.
2. Bật nguồn concentrator (`POWER_EN` lên mức cao).
3. Tạo xung reset cho SX1302 (high -> low).
4. Reset SX1261 (low -> high).
5. Reset AD5338R (low -> high).
6. Chờ ổn định 0.5 giây rồi mới khởi động packet forwarder.

Tại sao script này phù hợp với RPi OS mới:
- Dùng `pinctrl` thay vì cơ chế `/sys/class/gpio` cũ.
- Đơn giản, dễ đặt vào `ExecStartPre` của systemd.
- Không phụ thuộc `start|stop`, phù hợp luồng chạy production one-shot.

Rủi ro nếu cấu hình sai:
- Sai chân GPIO: reset không có hiệu lực, packet forwarder có thể khởi động nhưng không giao tiếp được concentrator.
- Bỏ qua bước power enable/reset sequence: có thể gây lỗi ngắt quãng khi khởi tạo HAL.

#### 6.4.2. Phân tích packet_forwarder/global_conf.json

File này gồm 3 khối chính: `SX130x_conf`, `gateway_conf`, `debug_conf`.

A. Khối SX130x_conf (cấu hình radio + board)
1. Giao tiếp phần cứng:
- `com_type: SPI`, `com_path: /dev/spidev0.0`, `spi_speed: 2000000`.
- Ý nghĩa: WM1302 đang chạy qua SPI trên Raspberry Pi, tốc độ 2 MHz ưu tiên độ ổn định.

2. Tham số chung LoRa:
- `lorawan_public: true`: dùng sync word public LoRaWAN.
- `clksrc: 0`: sử dụng radio chain 0 làm nguồn clock.
- `antenna_gain: 2`: dùng để bù công suất khi tính EIRP.
- `full_duplex: false`: chế độ half-duplex (phù hợp đa số gateway WM1302).

3. Fine timestamp:
- `fine_timestamp.enable: false`.
- Ý nghĩa: đang chạy timestamp thường, không bật chế độ fine timestamp.

4. Cấu hình SX1261:
- `spi_path: /dev/spidev0.1`.
- `spectral_scan.enable: false`, `lbt.enable: false`.
- Ý nghĩa: SX1261 đã khai báo đầy đủ nhưng đang tắt tính năng scan/LBT trong profile hiện tại.

5. Radio chains:
- `radio_0.freq = 923200000`, `tx_enable = true`.
- `radio_1.freq = 924200000`, `tx_enable = false`.
- Ý nghĩa: radio_0 vừa RX/TX, radio_1 chủ yếu bổ trợ RX đa kênh.

6. Giới hạn tần số phát:
- `radio_0.tx_freq_min = 920000000`, `tx_freq_max = 925000000`.
- `radio_1` cũng có giới hạn 923-925 MHz (dù đang tắt TX).
- Ý nghĩa: giới hạn miền tần số phát để tránh packet bất hợp lệ.

7. Bảng công suất phát (`tx_gain_lut`):
- Đã khai báo nhiều mốc từ 12 dBm đến 27 dBm.
- Ý nghĩa: server có thể yêu cầu nhiều mức công suất, HAL map sang `pa_gain/pwr_idx` tương ứng.
- Lưu ý vận hành: mức công suất tối đa cần đối chiếu quy định pháp lý và thiết kế RF thực tế.

8. Kênh thu/phát LoRa:
- 8 kênh `chan_multiSF_0..7` đang bật, IF trải từ -200k đến +400k trên 2 radio.
- `chan_Lora_std` đang bật với BW125/SF7 tại IF=0.
- `chan_FSK` đang tắt.
- Ý nghĩa: profile tập trung cho LoRa uplink đa SF, không sử dụng FSK.

B. Khối gateway_conf (kết nối lên network server)
1. Định danh và dịch vụ:
- `gateway_ID`: EUI của gateway.
- `server_address`: IP/domain của network server.
- `serv_port_up/down`: 1700/1700 (kiểu Semtech UDP packet forwarder).

2. Chu kỳ vận hành:
- `keepalive_interval: 10`, `stat_interval: 30`, `push_timeout_ms: 100`.
- Ý nghĩa: cân bằng giữa độ trễ mạng và tần suất gửi thống kê/keepalive.

3. Lọc gói uplink:
- `forward_crc_valid: true`, `forward_crc_error: false`, `forward_crc_disabled: false`.
- Ý nghĩa: chỉ đẩy packet hợp lệ CRC lên server, giảm nhiễu.

4. GPS + beacon:
- `gps_tty_path: /dev/ttyS0` (nếu có GPS).
- `beacon_period: 0` => tắt Class B beacon.
- `beacon_freq_hz: 923400000` chỉ có ý nghĩa khi bật beacon.

C. Khối debug_conf
1. `ref_payload` dùng cho debug tham chiếu payload.
2. `log_file: loragw_hal.log` là file log debug từ packet forwarder.

Nhận xét tổng hợp cho profile AS923 Việt Nam hiện tại:
1. Cấu hình hướng tới vận hành thực tế: SPI ổn định, reset script riêng, server/port đã set.
2. Đã ưu tiên uplink LoRa và tắt các tính năng không cần thiết (FSK, beacon, LBT).
3. Cần xác minh cuối với Network Server:
- Channel plan AS923 đang dùng trên server có khớp các kênh gateway hay không.
- RX2/data-rate policy có đồng bộ với profile node và gateway hay không.

## 7. Quy trình khởi động gateway thủ công
Từ thư mục project:

```bash
# 1) Reset concentrator
./packet_forwarder/reset_lgw.sh

# 2) Chạy packet forwarder với file cấu hình chính
./packet_forwarder/lora_pkt_fwd -c packet_forwarder/global_conf.json
```

Nếu khởi động thành công, log sẽ báo đã parse được SX130x_conf và gateway_conf, đồng thời in thông tin server/port.

## 8. Tạo service systemd để tự động chạy
Tạo file:
- /etc/systemd/system/lora-pkt-fwd.service

Nội dung tham khảo:

```ini
[Unit]
Description=SX1302 LoRa Packet Forwarder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/pi/sx1302_hal
ExecStartPre=/home/pi/sx1302_hal/packet_forwarder/reset_lgw.sh
ExecStart=/home/pi/sx1302_hal/packet_forwarder/lora_pkt_fwd -c /home/pi/sx1302_hal/packet_forwarder/global_conf.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Nạp lại daemon và enable service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable lora-pkt-fwd
sudo systemctl start lora-pkt-fwd
sudo systemctl status lora-pkt-fwd
```

Xem log realtime:

```bash
sudo journalctl -u lora-pkt-fwd -f
```

## 9. Kiểm tra và nghiệm thu

### 9.1. Checklist nhanh
1. SPI đã enable, thấy /dev/spidev0.0 và /dev/spidev0.1.
2. Script reset chạy thành công, không báo lỗi pinctrl.
3. lora_pkt_fwd parse được global_conf.json.
4. Gateway push dữ liệu lên server (có PUSH_ACK/PULL_ACK).
5. Uplink từ node trong vùng AS923 được nhận.

### 9.2. Lỗi thường gặp
1. Không thấy /dev/spidev0.0:
- Chưa bật SPI hoặc lỗi kết nối phần cứng.

2. Script reset lỗi permission:
- Chưa chmod +x hoặc đang chạy bằng user không đủ quyền.

3. Không kết nối được server:
- Sai server_address/port, firewall chặn UDP, gateway_ID chưa đăng ký trên network server.

4. Có uplink nhưng không downlink:
- Kiểm tra clock, RX2 settings và profile khu vực AS923 bên network server.

## 10. Khuyến nghị vận hành
Nếu chỉ vận hành packet forwarder, cập nhật packet_forwarder/reset_lgw.sh là đủ; nếu vẫn dùng các util/test trong repo thì cập nhật thêm tools/reset_lgw.sh để đồng bộ mapping chân.

---

Tài liệu này được viết theo hiện trạng project đã tùy biến để dùng WM1302 (Seeed Studio) + Raspberry Pi 3 B+.
