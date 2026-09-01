# Kiến trúc Windra

## 1. Mô hình tổng thể

```text
                    WINDRA
                       │
          ┌────────────┴────────────┐
          │                         │
     Native Desktop             Web Runtime
      Qt 6 / QML                 Chromium
          │                         │
         C++                 Web Apps / PWA
          │
          ├──────── D-Bus ────────┐
          │                       │
   Windra services (Go)      Linux services
          │                       │
          └──────────┬────────────┘
                     │
                  systemd
                     │
          Debian + Linux kernel
```

## 2. Windra Shell

Windra Shell chịu trách nhiệm cho lớp trải nghiệm người dùng:

- panel/dock;
- launcher;
- tìm kiếm;
- quick settings;
- status island;
- notification center;
- desktop surface.

Giai đoạn Foundation **không tự viết compositor**. KWin Wayland đảm nhiệm window management/compositing.

## 3. Dịch vụ hệ thống

Nguyên tắc: UI không chạy quyền root và không thao tác trực tiếp lên thành phần nhạy cảm.

```text
QML UI
  ↓
C++ Controller
  ↓
D-Bus
  ↓
Windra Service / Linux Service
  ↓
Polkit (nếu cần)
```

### Service đầu tiên

- `windra-webapp`: quản lý launcher Web App.
- `windra-health`: cung cấp số liệu tài nguyên.

### Service dự kiến

- `windra-update`
- `windra-storage`
- `windra-search`
- `windra-device`

## 4. Storage UX

Windra sẽ không yêu cầu người dùng biết GPT, mount point, UUID hay `/etc/fstab` để tạo vùng lưu trữ.

```text
+ Add Drive
   ↓
Plan
   ↓
Preview
   ↓
Polkit authentication
   ↓
UDisks2 / libblockdev
   ↓
Apply
```

Mọi thao tác phá hủy dữ liệu phải có preview rõ ràng và không được thực hiện bởi UI trực tiếp.

## 5. Web-first

Web App được xem như app bình thường trong launcher:

```text
URL
 ↓
windra-webapp
 ↓
.desktop entry + metadata
 ↓
Chromium --app=<URL>
```

Native app và Web App dùng chung launcher, search và notification surface.

## 6. Giới hạn của Foundation

Bản foundation chưa có:

- custom compositor;
- update service hoàn chỉnh;
- installer Windra riêng;
- partition engine;
- Flatpak GUI;
- browser fork riêng;
- driver manager riêng.

Đây là chủ ý để tránh biến Sprint 0 thành một “hố đen hệ điều hành”.
