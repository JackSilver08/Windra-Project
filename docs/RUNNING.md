# Hướng dẫn chạy Windra

Tài liệu này chỉ nói về **cách build và chạy** Windra Shell. Kiến trúc các panel
hệ thống nằm ở [system-panels.md](system-panels.md).

---

## 1. Yêu cầu

| Thứ | Ghi chú |
|---|---|
| Debian 12/13 hoặc Ubuntu 22.04+ | Windra phát triển trên Debian trixie |
| Qt 6.5 trở lên | trixie có sẵn 6.8 |
| CMake 3.22+, Ninja, g++ | C++20 |
| Máy Linux thật, VM, hoặc WSL2 + WSLg | WSL2 chạy được nhưng có giới hạn, xem §5 |

Kiểm tra nhanh:

```bash
cmake --version && ninja --version && g++ --version
```

---

## 2. Cài phụ thuộc

Một lệnh duy nhất:

```bash
cd "Windra Project"
chmod +x tools/*.sh
./tools/bootstrap-debian.sh
```

Script cài cả **build deps** lẫn **runtime deps**, và tự nhận diện WSL để bỏ qua
những gói không nên cài ở đó (xem §5).

Nếu muốn cài tay:

```bash
sudo apt install build-essential cmake ninja-build pkg-config \
  qt6-base-dev qt6-declarative-dev \
  qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts qml6-module-qtquick-window \
  qt6-svg-plugins qt6-wayland \
  upower power-profiles-daemon pulseaudio-utils
```

> `qt6-svg-plugins` không phải tuỳ chọn: **toàn bộ** icon dock và launcher là
> `.svg`. Thiếu nó thì shell vẫn chạy nhưng trắng trơn không có icon.

---

## 3. Build

```bash
cd "Windra Project"
cmake -S . -B build -G Ninja -DWINDRA_BUILD_SETTINGS=ON
cmake --build build
```

Hoặc dùng shortcut có sẵn:

```bash
make desktop      # configure + build
./tools/dev-run.sh   # build rồi chạy luôn
```

Build lại từ đầu khi đổi cấu trúc CMake:

```bash
rm -rf build && cmake -S . -B build -G Ninja -DWINDRA_BUILD_SETTINGS=ON && cmake --build build
```

Build xong phải có 5 binary:

```text
build/shell/windra-shell
build/apps/files/windra-files
build/apps/calc/windra-calc
build/apps/notes/windra-notes
build/apps/settings/windra-settings
```

---

## 4. Chạy

```bash
./build/shell/windra-shell --windowed
```

`--windowed` chạy trong một cửa sổ 1280×720 thay vì fullscreen, và bật
**preview-safe mode**: Power Menu không tắt/khởi động lại máy thật, và Windra
không buộc dừng (SIGKILL) ứng dụng nào.

Bỏ `--windowed` để chạy fullscreen (dùng cho session thật trên ISO).

### Boot bản ISO Windra

Tạo ISO và mở bằng QEMU:

```bash
./tools/build-iso.sh
./tools/run-qemu.sh "$PWD/out/windra-0.2-desktop-alpha-amd64.iso"
```

SDDM tự đăng nhập user live `windra` vào phiên Wayland **Windra**; không cần chọn
session hay chạy shell bằng tay. Trong QEMU, `nmcli device status` chỉ thấy card
Ethernet ảo (thường là `ens3`) và `nmcli device wifi list` trống là bình thường.
Muốn kiểm Wi-Fi thật, ghi ISO ra USB, boot trực tiếp laptop rồi chạy:

```bash
sudo windra-check-wifi
```

### Phím và thao tác

| Thao tác | Kết quả |
|---|---|
| `Ctrl+Space` | mở launcher |
| `Esc` | đóng popup/panel đang mở |
| Click icon Wi-Fi / loa / pin (góc trên phải) | mở popup riêng của từng cái |
| Click vùng giờ (góc dưới phải) | mở lịch |
| Click mũi tên `^` | ứng dụng đang chạy / chạy nền |
| Chuột phải lên icon loa | tắt/bật tiếng nhanh |
| Click ra ngoài | đóng popup |

Chỉ **một** popup hệ thống mở tại một thời điểm.

---

## 5. Chạy trong WSL2

WSL2 + WSLg chạy được Windra, nhưng có ba điều cần biết trước.

### 5.1 Đang ở Windows hay đang ở trong WSL?

Nhìn prompt:

```text
PS C:\Users\ban>              ← Windows PowerShell, cần tiền tố "wsl -d Debian --"
ban@may:~/Windra Project$     ← đã ở trong WSL, gõ lệnh Linux thẳng
```

Gõ `wsl` khi đang ở trong WSL sẽ báo `wsl: command not found`. Đó không phải
lỗi cài đặt — chỉ là gõ nhầm chỗ.

Từ PowerShell:

```powershell
wsl -d Debian -- bash -lc "cd ~/'Windra Project' && ./build/shell/windra-shell --windowed"
```

### 5.2 Coi chừng có hai bản source

Rất dễ có một bản trong ổ Windows (`/mnt/c/...`) và một bản trong home của WSL
(`~/Windra Project`) rồi sửa bản này nhưng build bản kia. Kiểm tra:

```bash
cat VERSION
```

Nếu số version không khớp với bản bạn đang sửa thì bạn đang đứng nhầm thư mục.

Cách gộp về một mối — giữ bản trên ổ Windows làm chính, biến bản trong home
thành symlink:

```bash
mv ~/"Windra Project" ~/"Windra Project.backup"
ln -s "/mnt/c/duong/dan/toi/Windra Project" ~/"Windra Project"
```

### 5.3 Build ra ext4 cho nhanh

`/mnt/c` là drvfs nên build chậm hơn nhiều. Để source trên ổ Windows nhưng build
ra filesystem của Linux:

```bash
cmake -S ~/"Windra Project" -B ~/windra-build -G Ninja -DWINDRA_BUILD_SETTINGS=ON
cmake --build ~/windra-build
~/windra-build/shell/windra-shell --windowed
```

### 5.4 Cái gì chạy, cái gì không trong WSL

| Popup | Trong WSL2 |
|---|---|
| Pin | ✅ **số thật** — WSL expose pin của máy host qua `/sys/class/power_supply` |
| Lịch | ✅ giờ hệ thống thật |
| Ứng dụng đang chạy | ✅ PID thật của app do Windra mở |
| Âm lượng | ✅ sau khi `sudo apt install pulseaudio-utils` — WSLg đã có sẵn PulseAudio server |
| Wi-Fi | ❌ WSL2 chỉ có `eth0`/`lo`, không có card không dây |
| Chế độ nguồn | ❌ không có power-profiles-daemon trong WSL |

Popup báo "không khả dụng" trong các trường hợp trên là **hành vi đúng** —
Windra không bao giờ hiển thị pin, SSID hay âm lượng giả.

---

## 6. Mock Wi-Fi cho phát triển

Vì WSL2 không có card Wi-Fi, dùng backend giả lập để làm việc trên giao diện:

```bash
./tools/dev-run.sh --mock-wifi
```

Hoặc tự đặt biến môi trường:

```bash
WINDRA_WIFI_MOCK=1 ./build/shell/windra-shell --windowed
```

> Chạy shell **không có** biến này trên máy không card Wi-Fi thì popup sẽ báo
> "Wi-Fi không khả dụng". Đó là hành vi đúng, không phải shell bị hỏng.
> `tools/dev-run.sh` sẽ nhắc bạn điều này khi phát hiện máy không có card.

- Mật khẩu đúng của mọi mạng giả lập: **`windra123`**
- Popup hiện chip **DEV MOCK** màu cam để không nhầm là dữ liệu thật
- Phủ đủ các kiểu bảo mật: mạng mở, OWE, WPA2, WPA3, 802.1X

Biến môi trường này **không bao giờ** được đặt ở bản chạy thật.

> Mock chỉ chốt được giao diện. Đường D-Bus tới NetworkManager vẫn phải kiểm
> trên máy Linux có card Wi-Fi thật trước khi coi tính năng Wi-Fi là xong.

---

## 7. Xử lý sự cố

### `wsl: command not found`
Bạn đang ở trong WSL rồi. Bỏ tiền tố `wsl -d Debian --` đi.

### Icon dock/launcher trắng trơn
Thiếu plugin ảnh SVG của Qt:
```bash
sudo apt install qt6-svg-plugins
```

### Shell không khởi động, màn hình đen (trên ISO/session thật)
Session đặt `QT_QPA_PLATFORM=wayland` nhưng thiếu plugin:
```bash
sudo apt install qt6-wayland
```

### `module "QtQuick.Window" is not installed`
```bash
sudo apt install qml6-module-qtquick-window
```

### Popup Âm lượng: "Không có thiết bị âm thanh"
```bash
sudo apt install pulseaudio-utils    # hoặc wireplumber nếu dùng PipeWire
```
Kiểm tra lại:
```bash
pactl get-sink-volume @DEFAULT_SINK@
```
Ra một dòng có `%` là được. Khởi động lại shell, không cần build lại.

### Popup Wi-Fi: "Wi-Fi không khả dụng"
Máy không có NetworkManager, hoặc không có card Wi-Fi. Trong WSL2 là bình
thường — dùng mock ở §6. Trên máy thật, chạy chẩn đoán:

```bash
sudo ./tools/check-wifi.sh
```

Script kiểm phần cứng, driver, firmware, rfkill, NetworkManager **và chính xác
những lời gọi D-Bus mà Windra dùng** — không cần build Windra. Dòng cuối của
script in đường dẫn báo cáo, mặc định là
`/tmp/windra-wifi-report-<effective-uid>.txt` (chạy bằng `sudo` thường là
`/tmp/windra-wifi-report-0.txt`). Đừng đọc lại file
`/tmp/windra-wifi-report.txt` cũ.

Trong WSL2, script chỉ xác nhận giới hạn môi trường: Windows giữ card Wi-Fi vật
lý nên WSL không thể kiểm driver, firmware hay D-Bus NetworkManager cho radio.
Muốn xác nhận phần cứng phải chạy cùng script sau khi boot Debian/Windra trực
tiếp trên laptop.

Sửa nhanh thường gặp:
```bash
sudo apt install network-manager wpasupplicant
sudo rfkill unblock all
systemctl status NetworkManager
```

### Popup Pin: "Máy này không có pin"
Máy bàn hoặc VM không có pin. Kiểm tra:
```bash
ls /sys/class/power_supply/
```

### Ba nút chế độ nguồn bị mờ
```bash
sudo apt install power-profiles-daemon
```

### Sửa code rồi mà chạy vẫn ra giao diện cũ
Đang chạy nhầm binary. Kiểm tra thời gian build:
```bash
ls -la build/shell/windra-shell
```

---

## 8. Kiểm thử nhanh sau khi build

Chạy qua danh sách này để chắc chắn bản build lành lặn:

1. Shell khởi động, intro animation chạy mượt (status island → dock → clock).
2. Click **pin** → chỉ popup Pin mở, hiện phần trăm thật.
3. Click **loa** → popup Pin đóng, popup Âm lượng mở.
4. Kéo slider âm lượng → âm lượng hệ thống đổi theo.
5. Click **Wi-Fi** → popup Âm lượng đóng, popup Wi-Fi mở.
6. Click **vùng giờ** → lịch mở, lật tháng trước/sau được, nút "Hôm nay" hoạt động.
7. Click **mũi tên `^`** → danh sách ứng dụng.
8. Mở Files/Calc/Notes từ dock → hiện trong danh sách kèm PID, dock có gạch dưới.
9. Đóng app từ popup → biến khỏi danh sách, gạch dưới ở dock tắt theo.
10. Click ra ngoài → popup đóng.
11. Bật **Reduce Motion** trong Windra Settings → popup bỏ slide ngay, không cần
    khởi động lại shell.

---

## 9. An toàn

Khi chạy với `--windowed`:

- Power Menu **không** shutdown/reboot/suspend thật, chỉ hiện thông báo preview.
- Windra **không** buộc dừng (SIGKILL) ứng dụng nào.

Đóng ứng dụng luôn bắt đầu bằng SIGTERM. Windra chỉ tác động lên process do
chính nó mở, không bao giờ đụng vào process khác của hệ thống.
