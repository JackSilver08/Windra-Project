# Windra Project

**Windra 0.2 Desktop Alpha** là mốc phát triển thứ hai của Windra, một hệ điều hành desktop nhẹ, Web-first và Human-first dựa trên Linux/Debian.

> Tên thư mục gốc chuẩn của dự án là **`Windra Project`**.

## Mục tiêu của 0.2

0.1 chứng minh Windra Shell có thể build và chạy bằng Qt/QML trên Linux. 0.2 biến proof-of-concept đó thành một desktop alpha có tương tác thật:

- giao diện bám sát mockup chính thức;
- motion intro: status island, dock, search, icon và clock xuất hiện theo nhịp;
- launcher có tìm kiếm ứng dụng và fallback tìm trên web;
- **system panel độc lập**: Battery, Volume, Wi-Fi, Calendar và Running Apps,
  mỗi cái một popup riêng với backend Linux thật (xem
  [docs/system-panels.md](docs/system-panels.md));
- power menu an toàn trong `--windowed`;
- dock có hover/click/running indicator;
- Windra Files alpha đọc thư mục thật;
- Windra Calc hoạt động;
- Windra Notes có mở/lưu tệp văn bản;
- Windra Settings có System Health UI, Appearance/Reduce Motion UI và các trang hệ thống alpha;
- browser được mở như runtime Web-first;
- giữ các Go services `windra-webapp` và `windra-health` từ Foundation.

## Stack

| Lớp | Công nghệ |
|---|---|
| Nền | Debian Stable / Linux kernel |
| Init | systemd |
| Display | Wayland |
| Compositor giai đoạn đầu | KWin Wayland |
| Desktop UI | Qt 6 + QML |
| Native integration | C++20 |
| System services | Go |
| IPC | D-Bus |
| Web runtime | Chromium / trình duyệt mặc định |
| Network | NetworkManager |
| Audio | PipeWire + WirePlumber |
| Storage | UDisks2 + libblockdev + Polkit (roadmap) |
| Package | APT + Flatpak |
| ISO | Debian live-build |

## Cấu trúc

```text
Windra Project/
├── shell/                 # Desktop shell + motion + launcher + system panels
│   ├── src/               # ShellBackend + Battery/Audio/Network service + model
│   └── qml/
│       ├── controls/      # Windra design system (WindraPopup, icon động...)
│       ├── components/    # status island, dock, clock pill
│       └── panels/        # popup Battery/Volume/Wi-Fi/Calendar/Running Apps
├── common/                # thư viện dùng chung shell <-> apps (WindraSettings)
├── apps/
│   ├── files/             # File manager alpha
│   ├── settings/          # Settings alpha
│   ├── calc/              # Calculator
│   └── notes/             # Notes
├── services/
│   ├── webapps/           # Web App Manager CLI (Go)
│   ├── health/            # System Health CLI (Go)
│   └── storage/           # Storage design / D-Bus skeleton
├── assets/design/         # Mockup chính thức
├── system/                # D-Bus/systemd/session skeleton
├── iso/                   # Debian live-build skeleton
├── tools/                 # bootstrap/build/dev scripts
├── docs/                  # tài liệu kiến trúc/roadmap
└── VERSION
```

## Chạy trên WSL2 Debian

Nếu bạn đang dùng source 0.1 trong `~/Windra-Foundation`, hãy giữ nó làm backup và dùng folder mới:

```bash
cd ~
mkdir -p "Windra Project"
```

Giải nén bản 0.2 sao cho `CMakeLists.txt` nằm trực tiếp trong:

```text
~/Windra Project/
```

Sau đó:

```bash
cd ~/"Windra Project"
chmod +x tools/*.sh
./tools/bootstrap-debian.sh
./tools/dev-run.sh
```

Hoặc build thủ công:

```bash
cd ~/"Windra Project"
cmake -S . -B build -G Ninja -DWINDRA_BUILD_SETTINGS=ON
cmake --build build
./build/shell/windra-shell --windowed
```

> Hướng dẫn chạy đầy đủ, kể cả các bẫy thường gặp trong WSL2 và cách xử lý sự
> cố: **[docs/RUNNING.md](docs/RUNNING.md)**.

## System panels

Góc trên phải và góc dưới phải là các control **độc lập**, mỗi cái có popup
riêng — không gom vào một Quick Settings chung:

| Control | Click mở | Backend Linux |
|---|---|---|
| Wi-Fi | popup mạng (quét, lọc, kết nối) | NetworkManager D-Bus → `nmcli` |
| Volume | popup âm lượng | PipeWire `wpctl` → `pactl` |
| Battery | popup pin + chế độ nguồn | UPower D-Bus → `/sys/class/power_supply` |
| Đồng hồ | popup lịch | đồng hồ hệ thống |
| Mũi tên `^` | ứng dụng đang chạy / chạy nền | Windra ApplicationModel |

Chỉ một popup mở tại một thời điểm; click ra ngoài hoặc `Esc` để đóng.

Thiếu service nào thì popup tương ứng nói rõ là không khả dụng — Windra không
bao giờ hiển thị pin, SSID hay âm lượng giả. Chi tiết kiến trúc:
[docs/system-panels.md](docs/system-panels.md).

### Phụ thuộc tuỳ chọn

Không có cái nào bắt buộc để shell chạy:

```bash
sudo apt install network-manager upower pipewire wireplumber power-profiles-daemon
```

### Phát triển trong WSL2

WSLg đã có sẵn PulseAudio server (`/mnt/wslg/PulseServer`), nên popup Âm lượng
chạy được với âm thanh thật chỉ với:

```bash
sudo apt install pulseaudio-utils
```

WSL2 **không có card Wi-Fi** (chỉ `eth0`/`lo`), nên popup Wi-Fi sẽ luôn báo không
khả dụng — đó là hành vi đúng. Để làm việc trên UX Wi-Fi mà không cần phần cứng,
bật mock backend dành riêng cho dev:

```bash
./tools/dev-run.sh --mock-wifi
```

Popup sẽ hiện chip **DEV MOCK** để không bao giờ nhầm dữ liệu giả lập là thật.
Mật khẩu đúng của mọi mạng giả lập là `windra123`. Chi tiết:
[docs/system-panels.md](docs/system-panels.md).

## Motion Design 0.2

Intro desktop được thiết kế ngắn để không cản thao tác:

1. status island trượt xuống + fade;
2. dock trượt từ trái;
3. nút nguồn và search xuất hiện;
4. app icons stagger lần lượt;
5. clock pill trượt lên sau cùng.

Mục tiêu tổng thể dưới khoảng 0,6 giây. Không dùng blur/particle nặng.

System popup dùng fade + slide 10px trong 160ms, hover icon scale tối đa 1.04.

`Reduce Motion` trong Windra Settings **đã hoạt động thật**: shell theo dõi
`~/.config/Windra/windra.ini` bằng `QFileSystemWatcher`, nên gạt công tắc có
hiệu lực ngay, không cần đăng nhập lại. Khi bật, popup bỏ hẳn slide và chỉ fade
ngắn.

## Phím dev

- `Ctrl+Space`: mở launcher.
- `Esc`: đóng popup/panel đang mở.
- Chuột phải lên icon loa: tắt/bật tiếng nhanh.

## An toàn

Khi shell chạy với `--windowed`, Power Menu **không thực hiện shutdown/reboot/suspend thật**. Nó chỉ hiển thị thông báo preview. Trong chế độ này Windra cũng **không buộc dừng (SIGKILL)** ứng dụng nào; đóng ứng dụng luôn bắt đầu bằng SIGTERM.

`+ Thêm ổ đĩa` trong Windra Files hiện chỉ là UX alpha. Windra 0.2 không tự resize, format hoặc partition ổ đĩa. Tính năng phá hủy dữ liệu chỉ được triển khai sau mô hình:

```text
Plan → Preview → Polkit authentication → Apply → Verify
```

## Tình trạng phiên bản

**0.2.5-wifi-diagnostics**

Đây là bản dành cho phát triển và demo UI. Chưa phải bản cài đặt sử dụng hằng ngày.

**Đã xác nhận chạy thật:** pin (sysfs), âm lượng (`pactl` trên WSLg — đọc và
chỉnh được volume/mute, hiện đúng tên thiết bị), lịch, theo dõi ứng dụng do
Windra launch, Reduce Motion.

**Chưa xác nhận trên phần cứng:** đường D-Bus tới NetworkManager. Giao diện Wi-Fi
đã hoàn chỉnh và chạy đủ luồng qua mock backend, nhưng chưa lần nào kết nối một
mạng thật. Cần máy Linux có card Wi-Fi để kiểm.

**Còn là prototype:** backend audio/Wi-Fi dựa trên CLI (`wpctl`/`pactl`/`nmcli`)
khi D-Bus không dùng được, và `activate()` chưa raise được cửa sổ vì Windra chưa
nối window management.
