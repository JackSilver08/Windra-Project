# Windra System Panels

Tài liệu kiến trúc cho các control hệ thống ở status island và clock pill của
Windra Shell: **Battery, Volume, Wi-Fi, Calendar, Running Apps** và
**Popup Controller** điều phối chúng.

Nguyên tắc xuyên suốt tài liệu này:

> Không có dữ liệu giả. Nếu không đọc được trạng thái thật thì UI nói rõ là
> không khả dụng, chứ không hiển thị 84% hay một danh sách SSID bịa ra.

---

## 1. Mô hình chung

```text
QML popup  (shell/qml/panels/*.qml)
    │  chỉ đọc property, gọi Q_INVOKABLE
    ▼
Service   (shell/src/*Service.{h,cpp})     ← mặt tiền cho QML
    │  chọn backend một lần lúc khởi động
    ▼
Backend   (interface + implementation)     ← nói chuyện với Linux
    │
    ▼
UPower / NetworkManager / PipeWire / sysfs
```

QML **không bao giờ** chạy shell command. Mọi tương tác Linux nằm trong C++.
Các backend dựa trên CLI (wpctl, pactl, nmcli) đều đi qua `ProcessRunner`, một
helper chạy process **bất đồng bộ** để không block UI thread.

Mỗi service đều có ba trạng thái hợp lệ: **có dữ liệu thật**, **đang tải**, và
**không khả dụng**. Popup phải xử lý đủ cả ba.

---

## 2. Battery

| Thành phần | File |
|---|---|
| Service | `shell/src/BatteryService.{h,cpp}` |
| Chế độ nguồn | `shell/src/PowerProfilesService.{h,cpp}` |
| Icon động | `shell/qml/controls/BatteryIcon.qml` |
| Popup | `shell/qml/panels/BatteryPopup.qml` |

### Nguồn dữ liệu (theo thứ tự ưu tiên)

1. **UPower qua D-Bus system bus** — `org.freedesktop.UPower`, object
   `/org/freedesktop/UPower/devices/DisplayDevice`, interface
   `org.freedesktop.UPower.Device`. Đọc `Percentage`, `State`, `TimeToEmpty`,
   `TimeToFull`, `IsPresent`, `Type`.
   Đăng ký `PropertiesChanged` nên cập nhật gần như realtime; thêm timer 30s
   làm lưới an toàn cho các bản UPower không phát signal cho DisplayDevice.
2. **`/sys/class/power_supply/BAT*`** — fallback khi không có UPower daemon.
   Quét thư mục tìm supply có `type == Battery`, đọc `capacity`, `status`,
   `present`. Ước tính thời gian từ `energy_now`/`power_now` (µWh/µW) hoặc
   `charge_now`/`current_now` (µAh/µA) tuỳ driver. Poll 8s.
3. **Không có pin** → `available = false`.

`source` property trả về `upower` | `sysfs` | `none` để debug.

### Mức pin → icon

`BatteryService::level()` trả về một trong:

| Dung lượng | level | Màu |
|---|---|---|
| 0–10% | `critical` | `Theme.danger` |
| 11–25% | `low` | `Theme.accentWarm` |
| 26–50% | `medium` | `Theme.ink` |
| 51–75% | `high` | `Theme.ink` |
| 76–99% | `veryhigh` | `Theme.ink` |
| 100% | `full` | `Theme.ink` |

`BatteryIcon.qml` là một `Canvas` vẽ vỏ pin + mức pin tỉ lệ theo phần trăm
thật, cộng tia sạc khi `charging`. Khi không có pin thì vẽ gạch chéo thay vì
một mức bịa. Canvas rẻ hơn nhiều so với shader/blur và giữ đúng nét của bộ
icon SVG gốc.

Status island hiển thị `[icon] 84%` cạnh nhau, tooltip dạng
`Pin 84% · đang sử dụng`.

### Chế độ nguồn

`PowerProfilesService` nói chuyện với **power-profiles-daemon**, hỗ trợ cả tên
service mới (`org.freedesktop.UPower.PowerProfiles`) và cũ
(`net.hadess.PowerProfiles`). Ba nút Tiết kiệm / Cân bằng / Hiệu năng ánh xạ
tới `power-saver` / `balanced` / `performance`.

Không có daemon → ba nút **disabled** kèm dòng giải thích, không phải nút bấm
được mà chẳng làm gì.

---

## 3. Audio

| Thành phần | File |
|---|---|
| Service | `shell/src/AudioService.{h,cpp}` |
| Backend interface + impl | `shell/src/AudioBackend.{h,cpp}` |
| Icon động | `shell/qml/controls/VolumeIcon.qml` |
| Popup | `shell/qml/panels/VolumePopup.qml` |

### Backend

`AudioBackend` là abstract QObject với `probe/refresh/setVolume/setMuted/toggleMuted`
và một signal `stateChanged(available, volume, muted, deviceName)`.

| Implementation | Công cụ | Ghi chú |
|---|---|---|
| `WirePlumberCliBackend` | `wpctl` | PipeWire/WirePlumber — mặc định |
| `PulseCliBackend` | `pactl` | chạy được trên cả PipeWire lẫn PulseAudio |

Cả hai là **prototype dựa trên CLI**. Đây là lý do `AudioBackend` tồn tại:
khi Windra chuyển sang client PipeWire native (libpipewire / WirePlumber API)
thì chỉ thêm một lớp con mới, `AudioService` và toàn bộ QML không đổi một dòng.

### Đồng bộ hai chiều

- Slider bind `value: audioService.volume`; chỉ signal `moved` (do người dùng
  kéo) mới gọi `setVolume()`. Binding không bao giờ bị phá.
- Poll 2.5s (1s khi popup đang mở) bắt thay đổi từ bên ngoài: phím media,
  mixer khác, ứng dụng khác.
- Sau khi người dùng chỉnh, `m_settleGuard` bỏ qua poll trong 700ms để UI
  không bị giật ngược.

### Mức âm lượng → icon

`mute` (hoặc 0%) → gạch chéo · `low` ≤33% → 1 cung · `medium` ≤66% → 2 cung ·
`high` → 3 cung.

Click icon loa **trong popup** = mute/unmute. Click icon ở status island mở
popup; **chuột phải** ở status island là lối tắt mute/unmute.

---

## 4. Wi-Fi

| Thành phần | File |
|---|---|
| Service | `shell/src/NetworkService.{h,cpp}` |
| Backend interface | `shell/src/NetworkBackend.h` |
| Backend chính | `shell/src/NetworkManagerBackend.{h,cpp}` |
| Backend fallback | `shell/src/NmcliBackend.{h,cpp}` |
| Model | `shell/src/WifiNetworkModel.{h,cpp}` |
| Icon động | `shell/qml/controls/WifiIcon.qml`, `SignalBars.qml` |
| Popup | `shell/qml/panels/WifiPopup.qml` |

### Backend chính: NetworkManager D-Bus

| Việc | D-Bus |
|---|---|
| Tìm card Wi-Fi | `GetAllDevices` → `Device.DeviceType == 2` |
| Quét | `Device.Wireless.RequestScan(a{sv})` |
| Danh sách AP | `Device.Wireless.GetAllAccessPoints` |
| Thông tin AP | `AccessPoint.Ssid` (ay), `.Strength` (y), `.Flags/.WpaFlags/.RsnFlags` |
| Đang kết nối | `Device.Wireless.ActiveAccessPoint` |
| Bật/tắt Wi-Fi | property `NetworkManager.WirelessEnabled` |
| Đã lưu | `Settings.ListConnections` → `Connection.GetSettings` |
| Kết nối mạng mới | `AddAndActivateConnection(a{sa{sv}}, device, ap)` |
| Kết nối mạng đã lưu | `ActivateConnection(profile, device, ap)` |
| Kết quả | `Connection.Active.StateChanged(state, reason)` |

Nhiều AP cùng SSID được gộp lại, giữ cái mạnh nhất (ưu tiên cái đang kết nối).
Mạng ẩn (SSID rỗng) bị bỏ qua.

### Kiểu bảo mật

`WifiNetwork::security` mang kiểu thật chứ không chỉ "có khoá hay không", vì
`key-mgmt` gửi xuống NetworkManager khác nhau — đoán đại `wpa-psk` sẽ làm mọi
mạng WPA3 kết nối thất bại.

| security | Suy ra từ | key-mgmt gửi xuống NM | Hỏi mật khẩu |
|---|---|---|---|
| `open` | không cờ bảo mật | (không có section) | không |
| `owe` | `KEY_MGMT_OWE` / `OWE_TM` | `owe` | không |
| `psk` | `KEY_MGMT_PSK` | `wpa-psk` | có |
| `sae` | chỉ `KEY_MGMT_SAE` | `sae` | có |
| `enterprise` | `KEY_MGMT_802_1X` / `EAP_SUITE_B` | — | không hỗ trợ |

Thứ tự kiểm quan trọng: router ở **chế độ WPA2/WPA3 transition** bật cả PSK lẫn
SAE cùng lúc. Ưu tiên `psk` trong trường hợp đó vì tương thích rộng hơn; chỉ
mạng WPA3 thuần (chỉ có SAE) mới dùng `sae`.

Mạng 802.1X bị từ chối sớm với thông báo *"Windra chưa hỗ trợ mạng doanh nghiệp
(802.1X)"* thay vì mở sheet mật khẩu rồi thất bại khó hiểu. Đây là giới hạn đã
biết của v0.2.

Backend `nmcli` ánh xạ cột `SECURITY` (`"WPA2"`, `"WPA2 WPA3"`, `"WPA2 802.1X"`,
`"OWE"`, `"--"`) sang đúng bộ giá trị trên.

### Mật khẩu

Mật khẩu **không bao giờ** được ghi vào source hay file cấu hình của Windra.

1. Người dùng nhập vào ô password của popup.
2. Với mạng mới, chuỗi đi thẳng vào `AddAndActivateConnection` dưới key
   `802-11-wireless-security.psk`.
3. NetworkManager lưu vào kho riêng của nó
   (`/etc/NetworkManager/system-connections/`, quyền root-only).
4. Popup xoá ngay ô nhập sau khi gửi.
5. **Kết nối thất bại → Windra xoá luôn connection profile vừa tạo**
   (`Settings.Connection.Delete`), để một mật khẩu sai không nằm lại trong
   danh sách mạng đã lưu.

Mạng đã lưu (`known`) hoặc mạng mở được kết nối thẳng, không hỏi lại mật khẩu.
Mạng đã lưu được kích hoạt lại bằng chính object path của profile; Windra không
tạo một profile thứ hai với mật khẩu rỗng.

### Lỗi bằng ngôn ngữ người dùng

`NMActiveConnectionStateReason` được dịch, không bao giờ show raw D-Bus error:

| reason | Thông báo |
|---|---|
| 9 no-secrets, 10 login-failed | "Không thể kết nối. Hãy kiểm tra mật khẩu và thử lại." |
| 6 connect-timeout | "Mạng không phản hồi. Hãy thử lại." |
| 3/14 device gone | "Card Wi-Fi đã ngắt kết nối." |
| 5 ip-config-invalid | "Kết nối được nhưng không nhận được địa chỉ IP." |

### Fallback: nmcli

`NmcliBackend` parse `nmcli -t` (có xử lý escape `\:`). Chỉ dùng khi không nói
chuyện được với NetworkManager qua D-Bus.

> **Lưu ý bảo mật:** ở nhánh nmcli, mật khẩu đi qua argv của tiến trình nên có
> thể thấy trong `ps` trong khoảnh khắc kết nối. Đây là lý do D-Bus luôn được
> ưu tiên và nmcli chỉ là prototype.

### Mock backend cho phát triển

`MockNetworkBackend` (`shell/src/MockNetworkBackend.{h,cpp}`) chỉ được chọn khi:

```bash
WINDRA_WIFI_MOCK=1 ./build/shell/windra-shell --windowed
```

Lý do tồn tại: máy dev chạy WSL2 chỉ có `eth0`/`lo`, không có interface không
dây nào (`/sys/class/net/*/wireless` rỗng), và kernel WSL không build
`mac80211_hwsim` để tạo card ảo. Nếu không có lớp này thì toàn bộ UX Wi-Fi —
quét, lọc SSID, sheet mật khẩu, lỗi sai mật khẩu, kết nối thành công — sẽ không
bao giờ chạy được một lần nào trước khi lên phần cứng thật.

Mock giả lập sát hành vi thật: quét mất ~1.6s, cường độ sóng nhấp nhô ±3 mỗi
5s, mạng đã lưu kết nối thẳng không hỏi mật khẩu, mật khẩu sai trả lỗi sau
~1.9s. Mật khẩu đúng của mọi mạng có khoá là `windra123`.

Ba lớp bảo vệ để dữ liệu giả không lọt ra bản thật:

1. chỉ bật khi có biến môi trường, không bao giờ mặc định;
2. `backendId` trả về `mock`;
3. popup hiện chip **DEV MOCK** màu cam ở header khi backend là mock.

Đây chính là lý do `NetworkBackend` được tách thành interface: lớp này lắp vừa
mà `NetworkService`, `WifiNetworkModel` và toàn bộ QML không đổi một dòng.

> Mock **không thay thế** kiểm thử trên phần cứng thật. Nó chốt UX; đường D-Bus
> tới NetworkManager vẫn phải được xác nhận trên máy Linux có card Wi-Fi.

### Lọc danh sách

`WifiNetworkModel` là `QAbstractListModel` giữ danh sách đầy đủ + một view đã
lọc theo property `filter`. Lọc nằm ở model chứ không ở QML để delegate không
phải dựng rồi ẩn đi. Mạng đang kết nối bị loại khỏi view vì đã hiển thị riêng
ở mục "Đã kết nối".

---

## 5. Calendar

| Thành phần | File |
|---|---|
| Popup | `shell/qml/panels/CalendarPopup.qml` |
| Helper định dạng | `shell/qml/design/Format.js` |

Đây **không phải** app Calendar, chỉ là popup của đồng hồ hệ thống.

- Ngày giờ lấy từ `new Date()` — đồng hồ hệ thống thật, không hardcode.
- Đồng hồ `HH:mm:ss` chỉ chạy `Timer` **khi popup mở**, để không tốn nhịp vẽ.
- Lưới 6×7 dựng bằng `Format.monthGrid()`, tuần bắt đầu **Thứ Hai** (T2…CN),
  Chủ Nhật tô đỏ.
- Ngày hôm nay được highlight bằng chip tròn màu accent.
- Lật tháng trước/sau, nút "Hôm nay" tự disable khi đang xem tháng hiện tại.
- `Format.js` dùng tên thứ/tháng tiếng Việt, khớp với phần còn lại của giao
  diện Windra; `Format.isVietnamese()` cho phép chuyển sang Qt locale khi hệ
  thống chạy `vi_VN`. Clock pill dùng
  `Qt.locale().timeFormat(Locale.ShortFormat)` nên tôn trọng định dạng giờ của
  hệ thống.

---

## 6. Application tracking

| Thành phần | File |
|---|---|
| Registry + model | `shell/src/ApplicationModel.{h,cpp}` |
| Popup | `shell/qml/panels/RunningAppsPopup.qml` |

Mũi tên `^` cạnh đồng hồ có ý nghĩa chính thức là
**"Ứng dụng đang chạy / ứng dụng nền"** — không phải Quick Settings.

### Cố ý không liệt kê process Linux

Model **chỉ** chứa ứng dụng cấp người dùng do Windra launch. Người dùng không
bao giờ thấy `systemd`, `dbus-daemon`, `pipewire` ở đây.

### Catalog

`ApplicationModel::catalogItems()` là nguồn sự thật duy nhất về app Windra
biết (web, files, notes, calc, settings). Launcher, dock và popup này đều đọc
từ đó qua `appModel.catalog()`, nên không còn ba danh sách app rời rạc.

### Mỗi entry

| Trường | Ý nghĩa |
|---|---|
| `appId` | định danh ứng dụng |
| `name` | tên hiển thị |
| `iconName` | tên icon, QML map sang `assets/icons/<name>.svg` |
| `pid` | PID nếu theo dõi được |
| `executable` | đường dẫn nhị phân đã resolve |
| `state` | `foreground` / `running` / `background` / `closing` |
| `background` | true cho web app |
| `windows` | số cửa sổ nếu xác định được (v0.2: chưa) |
| `tracked` | Windra có biết PID và theo dõi được vòng đời không |

### Vòng đời

- Launch bằng `QProcess::startDetached(..., &pid)` để lấy PID thật.
- Poll 2s kiểm tra `/proc/<pid>` (Linux) hoặc `kill(pid, 0)`; app tự thoát thì
  biến mất khỏi model và running indicator ở dock cũng tắt theo.
- Resolve nhị phân: build tree (dev) → `PATH` → thư mục cạnh shell (bản cài).

### Web app

Windra thử spawn trực tiếp `x-www-browser` / `chromium` / `google-chrome` /
`firefox` để có PID theo dõi được (khác `xdg-open`, vốn thoát ngay). Nếu không
tìm được trình duyệt nào thì rơi về `QDesktopServices::openUrl()` và entry
được đánh dấu `tracked = false`, hiển thị đúng dòng "Windra không theo dõi
được cửa sổ này".

### Đóng ứng dụng

- `requestClose()` gửi **SIGTERM** — luôn ưu tiên đóng nhẹ nhàng.
- Sau 5s mà process còn sống thì báo "chưa đóng, chọn lại để buộc dừng".
- `forceClose()` mới gửi SIGKILL, và **bị chặn hoàn toàn trong chế độ
  `--windowed`** (dev preview không buộc dừng gì cả).
- Entry `tracked = false` chỉ bị bỏ khỏi danh sách, không đụng vào process nào.

### Giới hạn đã biết của v0.2

`activate()` chưa raise được cửa sổ vì Windra chưa nối window management
(KWin / foreign-toplevel protocol). Nó hiển thị thông báo nói đúng như vậy
thay vì im lặng không làm gì. AppRegistry/ApplicationModel đã sạch sẵn để nối
vào protocol thật ở mốc sau — chỉ cần điền `windows` và cài đặt `activate()`.

---

## 7. Popup Controller

| Thành phần | File |
|---|---|
| Controller | `shell/src/PopupController.{h,cpp}` |
| Bề mặt popup | `shell/qml/controls/WindraPopup.qml` |

`PopupController` giữ **một** string `active`. Chỉ một popup system mở tại một
thời điểm; không nơi nào phải tự viết logic "đóng cái kia".

```qml
// mở/đóng
onWifiClicked: popupController.toggle("wifi")

// popup tự biết mình có đang mở không
WifiPopup { open: popupController.active === "wifi" }
```

Tên đang dùng: `wifi`, `volume`, `battery`, `calendar`, `apps`, `launcher`,
`power`. Click ra ngoài → một `MouseArea` duy nhất trong `Main.qml` gọi
`close()`. `Esc` cũng vậy.

> **Bẫy đã tránh:** controller cố ý **không** có `Q_INVOKABLE isOpen(name)`.
> Binding gọi hàm sẽ không đăng ký phụ thuộc vào `activeChanged` nên không bao
> giờ chạy lại — popup sẽ không bao giờ mở. Luôn so sánh property `active`.

`main.cpp` nối signal `opened(name)` để service tương ứng tăng nhịp cập nhật
khi popup của nó mở và nghỉ khi đóng.

### Định vị

`WindraPopup` nhận `anchorItem` (chính là icon tương ứng) và `preferredSide`
(`below` cho status island, `above` cho clock pill). `reposition()`:

1. `anchorItem.mapToItem(parent, 0, 0)` — toạ độ thật lúc chạy;
2. canh giữa theo icon;
3. lật sang phía đối diện nếu tràn;
4. kẹp trong vùng cha với lề 14px.

Không có toạ độ nào hardcode, nên popup hoạt động đúng ở 1366×768, 1600×900,
1920×1080 và HiDPI.

---

## 8. Motion

Hằng số trong `shell/qml/design/Theme.js`:

| Token | Giá trị | Dùng cho |
|---|---|---|
| `popupDuration` | 160ms | fade + slide của system popup |
| `popupSlide` | 10px | quãng trượt |
| `popupFadeReduced` | 90ms | khi Reduce Motion bật |
| `hoverDuration` | 120ms | hover/press icon |
| `hoverScale` | 1.04 | scale hover tối đa |
| `pressScale` | 0.965 | scale khi nhấn |

Popup trượt từ phía nó xuất hiện: neo dưới thì trượt xuống, neo trên thì trượt
lên. Không blur nặng, không particle, không bounce, không animation >300ms.
Bóng popup là một rectangle lệch 3px chứ không phải shader blur.

### Reduce Motion

`Theme.popupMs(reduceMotion)` và `Theme.slideFor(reduceMotion)` là hai hàm duy
nhất cần gọi: khi Reduce Motion bật, slide về 0 và fade rút còn 90ms.

Nguồn: `common/WindraSettings` đọc `~/.config/Windra/windra.ini` (INI) với hai
khoá `appearance/motionEnabled` và `appearance/reduceMotion`.
`effectiveReduceMotion = reduceMotion || !motionEnabled`.

Cùng một class được compile vào **cả** Windra Shell và Windra Settings, và
shell theo dõi file bằng `QFileSystemWatcher` — gạt công tắc trong Settings có
hiệu lực ngay trên desktop, không cần restart shell và không cần thêm daemon.

---

## 9. Design system

`shell/qml/controls/`:

| Component | Vai trò |
|---|---|
| `WindraPopup` | bề mặt + motion + định vị cho mọi system popup |
| `WindraIconButton` | nút icon có hover/press/tooltip/active |
| `WindraButton` | nút chữ (primary / selected / phụ) |
| `WindraSlider` | slider giữ được binding hai chiều |
| `WindraToggle` | công tắc pill |
| `WindraListItem` | dòng danh sách có slot `leading`/`trailing` |
| `WindraSectionTitle` | tiêu đề nhóm |
| `WindraTooltip` | tooltip tự kẹp trong màn hình |
| `WindraTextField` | ô nhập |
| `BatteryIcon` / `VolumeIcon` / `WifiIcon` / `SignalBars` | icon vẽ động theo trạng thái thật |

> **Bẫy đã tránh:** không component nào dùng `default property alias content:`
> trỏ vào một child. Trong QML, alias đó sẽ nuốt luôn các item nền và
> `MouseArea` khai báo trong chính file component. `WindraPopup` và
> `WindraIconButton` để nội dung làm child bình thường (vẽ đè lên nền vì khai
> báo sau); `WindraListItem` dùng `property Component leading/trailing` + `Loader`.

Các file QML có delegate tham chiếu id của component ngoài đều đặt
`pragma ComponentBehavior: Bound` và dùng `required property`.

---

## 10. Phụ thuộc Linux

| Tính năng | Bắt buộc | Thiếu thì sao |
|---|---|---|
| Battery | UPower **hoặc** `/sys/class/power_supply` | "Máy này không có pin", icon gạch chéo |
| Chế độ nguồn | power-profiles-daemon | ba nút disabled + giải thích |
| Audio | `wpctl` (PipeWire) hoặc `pactl` | "Không tìm thấy dịch vụ âm thanh" |
| Wi-Fi | NetworkManager (D-Bus) hoặc `nmcli` | "Wi-Fi không khả dụng" + lý do |
| Calendar | không có | — |
| App tracking | `/proc` (Linux) | — |

Không có phụ thuộc nào là bắt buộc để shell khởi động. Mọi nhánh thiếu service
đều đã được chạy thử thật (môi trường dev Debian trixie/WSL không có UPower,
NetworkManager lẫn PipeWire) và nhánh "không có pin" được kiểm bằng fault
injection.

### Gói bắt buộc trên ISO

Ngoài các service ở trên, `iso/config/package-lists/windra.list.chroot` phải giữ
bốn gói mà **thiếu là shell không chạy được**, dễ bị bỏ sót vì chúng không phải
"tính năng":

| Gói | Thiếu thì sao |
|---|---|
| `qt6-wayland` | `windra-session` đặt `QT_QPA_PLATFORM=wayland` → shell không khởi động |
| `libqt6dbus6` | shell link Qt6::DBus cho UPower/NetworkManager |
| `qt6-svg-plugins` | mọi icon dock/launcher là `.svg` → trắng icon |
| `qml6-module-qtquick-window` | `Main.qml` có `import QtQuick.Window` |

Kiểm tra lại sau mỗi lần đổi dependency:

```bash
ldd build/shell/windra-shell | grep -oE "libQt6[A-Za-z]+" | sort -u
```

Không có Go service mới nào được thêm: Qt/C++ làm trực tiếp được những việc
này qua D-Bus, thêm daemon chỉ tạo thêm một lớp phải bảo trì.
