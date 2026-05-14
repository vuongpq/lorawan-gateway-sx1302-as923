# Bao cao trien khai LoRaWAN Gateway WM1302 + Raspberry Pi 3 B+ (AS923 Viet Nam)

## 1. Muc tieu
Tai lieu nay huong dan tung buoc de trien khai gateway LoRaWAN dung WM1302 cua Seeed Studio voi Raspberry Pi 3 B+, dua tren project sx1302_hal da duoc tuy bien.

Tai lieu cung chi ra cac file can sua/tao moi de gateway hoat dong o bang tan AS923 tai Viet Nam.

## 2. Tom tat cac tuy bien da co trong project
Project hien tai da co cac tuy bien quan trong:

1. Da map chan reset theo phan cung thuc te:
- SX1302_RESET_PIN = 17
- SX1302_POWER_EN_PIN = 18
- SX1261_RESET_PIN = 5
- AD5338R_RESET_PIN = 13

2. Da co script reset moi dung pinctrl:
- packet_forwarder/reset_lgw.sh
- util_chip_id/reset_lgw.sh

3. Da co file cau hinh chay thuc te:
- packet_forwarder/global_conf.json

## 3. Yeu cau phan cung va phan mem

### 3.1. Phan cung
- Raspberry Pi 3 Model B+
- Module WM1302 (SPI variant)
- Anten phu hop AS923
- Nguon on dinh cho Raspberry Pi

### 3.2. He dieu hanh
- Raspberry Pi OS (Bullseye/Bookworm)

### 3.3. Goi phu thuoc can cai
Chay tren Raspberry Pi:

```bash
sudo apt update
sudo apt install -y git build-essential pkg-config
```

Neu dung Raspberry Pi OS moi, nen bao dam co cong cu pinctrl:

```bash
pinctrl -h
```

Neu lenh tren khong ton tai, cap nhat he va cai cac goi GPIO phu hop ban dang dung.

## 4. Bat cac giao tiep can thiet tren Raspberry Pi
Bat SPI bang raspi-config:

```bash
sudo raspi-config
```

- Interface Options -> SPI -> Enable
- Neu co GPS ngoai, bat UART tuy he thong 

Khoi dong lai:

```bash
sudo reboot
```

Sau khi reboot, kiem tra:

```bash
ls -l /dev/spidev0.0 /dev/spidev0.1
```

## 5. Build sx1302_hal
Trong thu muc project:

```bash
make clean
make
```

Sau khi build, binary packet forwarder nam o:
- packet_forwarder/lora_pkt_fwd

## 6. Cac file can sua/tao de gateway chay duoc

### 6.1. File reset chung cho project
File can sua:
- tools/reset_lgw.sh

Vai tro:
- Khong phai file bat buoc cho luong chay packet forwarder hang ngay.
- Chu yeu de tuong thich voi cac util/test trong repo (nhieu chuong trinh goi `./reset_lgw.sh start|stop`).

Noi dung map chan da dung cho bo WM1302 + RPi 3 B+ trong project:

```sh
SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
SX1261_RESET_PIN=5
AD5338R_RESET_PIN=13
```

Script nay dang dung sysfs GPIO. Neu he dieu hanh van ho tro, co the su dung binh thuong.

### 6.2. File reset de chay packet forwarder
File can tao/sua:
- packet_forwarder/reset_lgw.sh

Vai tro:
- Day la file reset ban can dung khi van hanh gateway thuc te voi `lora_pkt_fwd`.
- Neu chi trien khai gateway (khong chay test/util khac), chi can file nay la du.

Ban nen dung phien ban pinctrl (da co san trong project), vi gon va tuong thich tot voi Raspberry Pi OS moi.

Cap quyen thuc thi:

```bash
chmod +x packet_forwarder/reset_lgw.sh
chmod +x tools/reset_lgw.sh
```

### 6.3. File cau hinh packet forwarder cho AS923 Viet Nam
File chinh can su dung:
- packet_forwarder/global_conf.json

Neu can tao moi tu template, co the copy tu mau AS923 roi doi sang SPI:

```bash
cp packet_forwarder/global_conf.json.sx1250.AS923.USB packet_forwarder/global_conf.json
```

Sau do sua cac truong:

1. Giao tiep concentrator (SPI):

```json
"com_type": "SPI",
"com_path": "/dev/spidev0.0",
"spi_speed": 2000000,
```

2. Giao tiep SX1261 (neu dung):

```json
"sx1261_conf": {
  "spi_path": "/dev/spidev0.1",
  ...
}
```

3. Cau hinh tan so AS923 Viet Nam (khuyen nghi theo file hien tai):

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

4. Cau hinh ket noi network server:

```json
"gateway_ID": "<EUI_16_HEX>",
"server_address": "<IP_HOAC_DOMAIN_NS>",
"serv_port_up": 1700,
"serv_port_down": 1700
```

5. Beacon (neu khong dung Class B, de 0 chu ky la on):

```json
"beacon_period": 0,
"beacon_freq_hz": 923400000
```

Luu y:
- Giu comments trong JSON la duoc doi voi project nay.
- Neu dung cong cu JSON strict ben ngoai, comments co the bao loi, nhung lora_pkt_fwd van parse duoc.

### 6.4. Phan tich chi tiet 2 file moi

#### 6.4.1. Phan tich packet_forwarder/reset_lgw.sh

Muc tieu cua script:
- Khoi tao lai trang thai phan cung CoreCell truoc khi start packet forwarder.
- Bao dam SX1302, SX1261 va ADC reset theo dung thu tu de tranh treo SPI/radio.

Y nghia cac bien chan GPIO:
- `SX1302_RESET_PIN=17`: chan reset chip concentrator SX1302.
- `SX1302_POWER_EN_PIN=18`: chan cap nguon cho khoi CoreCell.
- `SX1261_RESET_PIN=5`: chan reset SX1261 (LBT/spectral scan).
- `AD5338R_RESET_PIN=13`: chan reset ADC/DAC tren board tham chieu.

Trinh tu xu ly trong script:
1. Dat tat ca chan ve mode output bang `pinctrl set <pin> op`.
2. Bat nguon concentrator (`POWER_EN` len muc cao).
3. Tao xung reset cho SX1302 (high -> low).
4. Reset SX1261 (low -> high).
5. Reset AD5338R (low -> high).
6. Cho on dinh 0.5 giay roi moi khoi dong packet forwarder.

Tai sao script nay phu hop voi RPi OS moi:
- Dung `pinctrl` thay vi co che `/sys/class/gpio` cu.
- Don gian, de dat vao `ExecStartPre` cua systemd.
- Khong phu thuoc `start|stop`, phu hop luong chay production one-shot.

Rui ro neu cau hinh sai:
- Sai chan GPIO: reset khong co hieu luc, packet forwarder co the khoi dong nhung khong giao tiep duoc concentrator.
- Bo qua buoc power enable/reset sequence: co the gay loi ngat quang khi khoi tao HAL.

#### 6.4.2. Phan tich packet_forwarder/global_conf.json

File nay gom 3 khoi chinh: `SX130x_conf`, `gateway_conf`, `debug_conf`.

A. Khoi SX130x_conf (cau hinh radio + board)
1. Giao tiep phan cung:
- `com_type: SPI`, `com_path: /dev/spidev0.0`, `spi_speed: 2000000`.
- Y nghia: WM1302 dang chay qua SPI tren Raspberry Pi, toc do 2 MHz uu tien do on dinh.

2. Tham so chung LoRa:
- `lorawan_public: true`: dung sync word public LoRaWAN.
- `clksrc: 0`: su dung radio chain 0 lam nguon clock.
- `antenna_gain: 2`: dung de bu cong suat khi tinh EIRP.
- `full_duplex: false`: che do half-duplex (phu hop da so gateway WM1302).

3. Fine timestamp:
- `fine_timestamp.enable: false`.
- Y nghia: dang chay timestamp thuong, khong bat che do fine timestamp.

4. Cau hinh SX1261:
- `spi_path: /dev/spidev0.1`.
- `spectral_scan.enable: false`, `lbt.enable: false`.
- Y nghia: SX1261 da khai bao day du nhung dang tat tinh nang scan/LBT trong profile hien tai.

5. Radio chains:
- `radio_0.freq = 923200000`, `tx_enable = true`.
- `radio_1.freq = 924200000`, `tx_enable = false`.
- Y nghia: radio_0 vua RX/TX, radio_1 chu yeu bo tro RX da kenh.

6. Gioi han tan so phat:
- `radio_0.tx_freq_min = 920000000`, `tx_freq_max = 925000000`.
- `radio_1` cung co gioi han 923-925 MHz (du dang tat TX).
- Y nghia: gioi han mien tan so phat de tranh packet bat hop le.

7. Bang cong suat phat (`tx_gain_lut`):
- Da khai bao nhieu moc tu 12 dBm den 27 dBm.
- Y nghia: server co the yeu cau nhieu muc cong suat, HAL map sang `pa_gain/pwr_idx` tuong ung.
- Luu y van hanh: muc cong suat toi da can doi chieu quy dinh phap ly va thiet ke RF thuc te.

8. Kenh thu/phat LoRa:
- 8 kenh `chan_multiSF_0..7` dang bat, IF trai tu -200k den +400k tren 2 radio.
- `chan_Lora_std` dang bat voi BW125/SF7 tai IF=0.
- `chan_FSK` dang tat.
- Y nghia: profile tap trung cho LoRa uplink da SF, khong su dung FSK.

B. Khoi gateway_conf (ket noi len network server)
1. Dinh danh va dich vu:
- `gateway_ID`: EUI cua gateway.
- `server_address`: IP/domain cua network server.
- `serv_port_up/down`: 1700/1700 (kieu Semtech UDP packet forwarder).

2. Chu ky van hanh:
- `keepalive_interval: 10`, `stat_interval: 30`, `push_timeout_ms: 100`.
- Y nghia: can bang giua do tre mang va tan suat gui thong ke/keepalive.

3. Loc goi uplink:
- `forward_crc_valid: true`, `forward_crc_error: false`, `forward_crc_disabled: false`.
- Y nghia: chi day packet hop le CRC len server, giam nhieu.

4. GPS + beacon:
- `gps_tty_path: /dev/ttyS0` (neu co GPS).
- `beacon_period: 0` => tat Class B beacon.
- `beacon_freq_hz: 923400000` chi co y nghia khi bat beacon.

C. Khoi debug_conf
1. `ref_payload` dung cho debug tham chieu payload.
2. `log_file: loragw_hal.log` la file log debug tu packet forwarder.

Nhan xet tong hop cho profile AS923 Viet Nam hien tai:
1. Cau hinh huong toi van hanh thuc te: SPI on dinh, reset script rieng, server/port da set.
2. Da uu tien uplink LoRa va tat cac tinh nang khong can thiet (FSK, beacon, LBT).
3. Can xac minh cuoi voi Network Server:
- Channel plan AS923 dang dung tren server co khop cac kenh gateway hay khong.
- RX2/data-rate policy co dong bo voi profile node va gateway hay khong.

## 7. Quy trinh khoi dong gateway thu cong
Tu thu muc project:

```bash
# 1) Reset concentrator
./packet_forwarder/reset_lgw.sh

# 2) Chay packet forwarder voi file cau hinh chinh
./packet_forwarder/lora_pkt_fwd -c packet_forwarder/global_conf.json
```

Neu khoi dong thanh cong, log se bao da parse duoc SX130x_conf va gateway_conf, dong thoi in thong tin server/port.

## 8. Tao service systemd de tu dong chay
Tao file:
- /etc/systemd/system/lora-pkt-fwd.service

Noi dung tham khao:

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

Nap lai daemon va enable service:

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

## 9. Kiem tra va nghiem thu

### 9.1. Checklist nhanh
1. SPI da enable, thay /dev/spidev0.0 va /dev/spidev0.1.
2. Script reset chay thanh cong, khong bao loi pinctrl.
3. lora_pkt_fwd parse duoc global_conf.json.
4. Gateway push du lieu len server (co PUSH_ACK/PULL_ACK).
5. Uplink tu node trong vung AS923 duoc nhan.

### 9.2. Loi thuong gap
1. Khong thay /dev/spidev0.0:
- Chua bat SPI hoac loi ket noi phan cung.

2. Script reset loi permission:
- Chua chmod +x hoac dang chay bang user khong du quyen.

3. Khong ket noi duoc server:
- Sai server_address/port, firewall chan UDP, gateway_ID chua dang ky tren network server.

4. Co uplink nhung khong downlink:
- Kiem tra clock, RX2 settings va profile khu vuc AS923 ben network server.

## 10. Khuyen nghi van hanh
1. Chot duy nhat mot file dang chay: packet_forwarder/global_conf.json.
2. Dat gateway_ID theo EUI that cua gateway de tranh xung dot.
3. Ghi lai version phan mem va backup config truoc moi lan doi tan so/kenh.
4. Neu chi van hanh packet forwarder, cap nhat packet_forwarder/reset_lgw.sh la du; neu van dung cac util/test trong repo thi cap nhat them tools/reset_lgw.sh de dong bo mapping chan.

---

Tai lieu nay duoc viet theo hien trang project da tuy bien de dung WM1302 (Seeed Studio) + Raspberry Pi 3 B+ va duy tri comments trong file JSON cau hinh.
