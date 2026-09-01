# Changelog

## Unreleased

- ISO build năm binary Release rồi cài thẳng vào `includes.chroot`; sau khi dựng,
  script kiểm tra binary, session, service, firmware, bộ gõ và boot image trước
  khi xuất file vào `out/`.
- Thêm SDDM autologin vào phiên Wayland Windra, bật `NetworkManager` cùng graphical
  target, khởi động Fcitx5 và Polkit KDE agent trong cùng session bus.
- Thêm terminal `foot` vào launcher, firmware âm thanh SOF và bộ gõ tiếng Việt
  Fcitx5 Unikey; tắt APT recommends để ISO không kéo cả Plasma desktop ngoài ý muốn.
- `check-wifi.sh` nhận diện WSL2, không còn báo thiếu card/NetworkManager như
  lỗi phần cứng; phân biệt dmesg không có dòng Wi-Fi với dmesg bị từ chối.
- Báo cáo Wi-Fi dùng tên theo effective UID và tự fallback sang `mktemp`, tránh
  `tee: Permission denied` do file cũ khác owner trong `/tmp`.
- Wi-Fi D-Bus dùng `ActivateConnection` cho mạng đã lưu, để NetworkManager đọc
  đúng secret của profile thay vì tạo một profile WPA mới với mật khẩu rỗng.
- Chặn hai yêu cầu kết nối chạy chồng nhau trong `NetworkService`.
- ISO thêm firmware Intel/Realtek, `wireless-regdb`, `rfkill`; thay gói Debian
  trixie không còn tồn tại `policykit-1` bằng `polkitd`.

## 0.2.5 Wi-Fi diagnostics

- Thêm `tools/check-wifi.sh`: chẩn đoán Wi-Fi chạy được trên bất kỳ máy Linux
  nào (live USB, VM, bản cài) mà **không cần build Windra**. Kiểm phần cứng,
  driver, firmware, rfkill, NetworkManager, và thực thi **đúng chuỗi lời gọi
  D-Bus mà `NetworkManagerBackend` dùng** — `GetAllDevices` → `DeviceType`,
  `RequestScan`, `GetAllAccessPoints`, đọc `Ssid`/`Strength`/`WpaFlags`/
  `RsnFlags`, và `ListConnections` → `GetSettings` để xác nhận giải mã được
  kiểu lồng `a{sa{sv}}` (cùng kiểu với `AddAndActivateConnection`).
- Script còn phân loại bảo mật bằng đúng logic `securityFor()` trong C++, nên
  đối chiếu được kết quả thật với code.

## 0.2.4 Audio verified

- **Xác nhận audio chạy thật** qua `pactl` trên WSLg: `available=true`,
  `backend=pulse-cli`, đọc đúng volume/mute và tên thiết bị output. Đoạn
  `readDeviceName()` viết ở 0.2.2 trước đó chưa từng được chạy thử.
- **Sửa lỗi: `QProcess: Destroyed while process is still running`.** Shell thoát
  trong lúc còn lệnh `pactl`/`nmcli` đang chạy sẽ để `~QProcess` in cảnh báo rồi
  chặn shutdown để chờ. `ProcessRunner` giờ dọn process ở `destroyed()` của
  context, lúc đối tượng con vẫn còn sống.
- `tools/dev-run.sh` thêm cờ `--mock-wifi`, và tự nhắc khi phát hiện máy không
  có interface không dây — để "Wi-Fi không khả dụng" không bị tưởng là lỗi.
- Thêm `docs/RUNNING.md`: hướng dẫn chạy, bẫy thường gặp trong WSL2 và xử lý sự cố.

## 0.2.3 WPA3 + ISO packaging

### Wi-Fi: bảo mật đúng chuẩn
- `WifiNetwork` mang kiểu bảo mật thật (`open`/`owe`/`psk`/`sae`/`enterprise`)
  thay vì chỉ một cờ `secured`.
- **Sửa lỗi: mạng WPA3 luôn kết nối thất bại.** Trước đây `key-mgmt` hardcode
  `wpa-psk`; giờ suy ra từ `RsnFlags`/`WpaFlags` và gửi `sae` cho WPA3 thuần,
  `owe` cho Enhanced Open. Router ở chế độ WPA2/WPA3 transition vẫn dùng
  `wpa-psk` vì tương thích rộng hơn.
- Mạng 802.1X bị từ chối sớm với thông báo rõ ràng thay vì mở sheet mật khẩu
  rồi thất bại khó hiểu.
- Danh sách hiện "Cần mật khẩu · WPA3", "Mạng mở (có mã hoá)", "Mạng doanh
  nghiệp" thay vì chỉ một ổ khoá chung chung.
- `NmcliBackend` ánh xạ cột `SECURITY` sang cùng bộ giá trị.

### ISO: bốn gói thiếu làm shell không chạy được
- `qt6-wayland` — session đặt `QT_QPA_PLATFORM=wayland`, thiếu là không khởi động.
- `libqt6dbus6` — shell link Qt6::DBus (xác nhận bằng `ldd`).
- `qt6-svg-plugins` — mọi icon dock/launcher là `.svg`, thiếu là trắng icon.
- `qml6-module-qtquick-window` — `Main.qml` có `import QtQuick.Window`.
- Thêm `power-profiles-daemon`, `pipewire-pulse`, `pulseaudio-utils`,
  `wpasupplicant`, `fonts-noto-core`. Mỗi mục có chú thích lý do trong package
  list để lần sau không bị gỡ nhầm.

### Dev
- `tools/bootstrap-debian.sh` cài cả runtime, tự nhận diện WSL và bỏ qua
  NetworkManager ở đó (nó giành `eth0` và có thể làm hỏng mạng WSL).
- Mock Wi-Fi phủ đủ 5 kiểu bảo mật để kiểm được cả nhánh WPA3 và 802.1X.

## 0.2.2 Dev Enablement

- Thêm `MockNetworkBackend` cho phát triển UX Wi-Fi trên máy không có card không
  dây (WSL2 chỉ có `eth0`/`lo`). Chỉ bật khi `WINDRA_WIFI_MOCK=1`; popup hiện
  chip **DEV MOCK** nên dữ liệu giả lập không thể bị nhầm là thật. Lắp vừa
  interface `NetworkBackend` sẵn có, không sửa `NetworkService` hay QML.
- `PulseCliBackend` hỏi `pactl get-default-sink` rồi mới tra tên thiết bị, thay
  vì lấy `Description` đầu tiên trong `pactl list sinks` — máy nhiều sink trước
  đây hiện sai thiết bị output.
- Thay emoji 🔒 trong danh sách Wi-Fi bằng `LockIcon` vẽ bằng Canvas: emoji ra ô
  vuông trên Debian tối giản không cài font emoji.
- README: hướng dẫn chạy trong WSL2 (WSLg có sẵn PulseAudio; Wi-Fi cần mock).

## 0.2.1 System Panels

### System panels độc lập
- Tách status island thành **ba control riêng** (Wi-Fi, Volume, Battery), mỗi
  cái có hover, tooltip và popup riêng. Trước đó một MouseArea phủ toàn bộ mở
  chung một Quick Settings.
- Tách clock pill thành **hai vùng click**: mũi tên `^` mở "Ứng dụng đang chạy /
  ứng dụng nền", vùng giờ mở Calendar.
- Thêm `PopupController` (C++): chỉ một popup system mở tại một thời điểm,
  logic open/close nằm một chỗ thay vì lặp ở 5 nơi.

### Backend Linux thật
- **Battery**: `BatteryService` đọc UPower qua D-Bus (có `PropertiesChanged`),
  fallback `/sys/class/power_supply/BAT*`. Icon vẽ động theo 6 mức dung lượng,
  hiện phần trăm cạnh icon, dấu hiệu sạc, ước tính thời gian còn lại.
- **Chế độ nguồn**: `PowerProfilesService` qua power-profiles-daemon
  (Tiết kiệm / Cân bằng / Hiệu năng).
- **Audio**: `AudioService` + interface `AudioBackend` với hai implementation
  `wpctl` (PipeWire) và `pactl`. Slider đổi volume hệ thống, volume đổi từ bên
  ngoài đẩy ngược vào UI, mute/unmute, icon theo 4 mức.
- **Wi-Fi**: `NetworkService` + interface `NetworkBackend` với backend chính
  NetworkManager qua D-Bus và fallback `nmcli`. Quét thật, hiển thị SSID +
  cường độ, mạng đang kết nối, bật/tắt Wi-Fi, refresh, lọc SSID, sheet nhập mật
  khẩu có "Hiện mật khẩu", lỗi bằng ngôn ngữ người dùng.
- **Calendar**: popup lịch của đồng hồ hệ thống, đồng hồ realtime, lật tháng,
  nút "Hôm nay", lưới tuần bắt đầu Thứ Hai, tên thứ/tháng tiếng Việt.
- Không hardcode pin, volume, SSID, ngày giờ hay tên thiết bị ở bất kỳ đâu.
  Thiếu service thì UI báo không khả dụng thay vì hiện dữ liệu giả.

### Application tracking
- Thêm `ApplicationModel`: registry + `QAbstractListModel` cho app cấp người
  dùng do Windra launch. Cố ý không liệt kê process Linux.
- Theo dõi PID thật (`QProcess::startDetached` + poll `/proc`), running
  indicator ở dock tự tắt khi app thoát.
- Đóng ứng dụng ưu tiên SIGTERM; SIGKILL chỉ sau khi graceful thất bại và bị
  chặn hoàn toàn trong `--windowed`.
- Launcher, dock và popup dùng chung một catalog app duy nhất.

### Design system
- Thêm `shell/qml/controls/`: `WindraPopup`, `WindraIconButton`, `WindraButton`,
  `WindraSlider`, `WindraToggle`, `WindraListItem`, `WindraSectionTitle`,
  `WindraTooltip`, `WindraTextField` và các icon vẽ động `BatteryIcon`,
  `VolumeIcon`, `WifiIcon`, `SignalBars`.
- Popup định vị theo icon tương ứng lúc chạy và tự kẹp trong màn hình — không
  hardcode toạ độ, hoạt động ở 1366×768 → 1920×1080 và HiDPI.
- Token motion mới cho system popup: fade + slide 10px, 160ms.

### Reduce Motion
- Thêm `common/WindraSettings` dùng chung giữa shell và Windra Settings.
- Công tắc Reduce Motion trong Settings **đã hoạt động thật**: shell theo dõi
  `~/.config/Windra/windra.ini` và áp dụng ngay, không cần restart.

### Bỏ
- Gỡ `QuickSettingsPanel.qml`. Wi-Fi/Volume/Battery giờ có popup riêng với dữ
  liệu thật; các mục Bluetooth/Night Light/độ sáng trong panel cũ chỉ là
  prototype dữ liệu giả nên không được mang sang.

## 0.2.0 Desktop Alpha

### Desktop
- Thay wallpaper placeholder bằng phong cảnh lấy từ mockup giao diện chính thức.
- Thêm motion intro nhẹ cho status island, dock, search, app icons và clock pill.
- Thêm hover/click micro-interaction cho icon.
- Thêm app running indicator.

### Shell UX
- Launcher alpha với app grid, tìm kiếm và web-search fallback.
- Quick Settings alpha: Wi-Fi/Bluetooth/Night Light prototype, volume/brightness slider.
- Power Menu với preview-safe mode khi chạy `--windowed`.
- Notification toast.
- `Ctrl+Space` mở launcher.

### Native Apps
- Windra Files: duyệt thư mục thật, Home, root, double-click mở thư mục/tệp.
- Windra Calc: phép tính cơ bản.
- Windra Notes: New/Open/Save text files.
- Windra Settings: UI hệ thống, System Health, Appearance/Reduce Motion.

### Developer Experience
- Folder chuẩn: `Windra Project`.
- `tools/dev-run.sh` build và chạy toàn bộ desktop alpha.
- CMake build app alpha mặc định.
