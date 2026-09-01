# Chẩn đoán màn hình đen của Windra ISO

Tài liệu này ghi lại đường khởi động phiên Windra và cách chẩn đoán khi ISO boot tới màn hình đen.

## Đường khởi động đúng

```text
SDDM
  -> /usr/bin/windra-session
       -> dbus-run-session
            -> kwin_wayland --xwayland --exit-with-session /usr/bin/windra-session-start
                 -> KWin tạo Wayland server/socket
                 -> /usr/bin/windra-session-start
                      -> QT_QPA_PLATFORM=wayland
                      -> fcitx5 + Polkit agent
                      -> /usr/bin/windra-shell
```

### Quy tắc QPA

`QT_QPA_PLATFORM` không được ép thành `wayland` trước khi khởi động KWin.
KWin Wayland có QPA nội bộ riêng (`wayland-org.kde.kwin.qpa`) cho compositor.
Sau khi KWin đã dựng Wayland server, `windra-session-start` mới đặt
`QT_QPA_PLATFORM=wayland` cho Windra Shell và các Qt client.

Đây là ranh giới quan trọng giữa **compositor** và **Wayland client**.

## Log phiên Windra

`windra-session-start` ghi log tối thiểu vào:

```bash
$XDG_RUNTIME_DIR/windra-session.log
```

Nếu màn hình đen, chuyển sang TTY bằng `Ctrl+Alt+F2`, đăng nhập rồi chạy:

```bash
cat "$XDG_RUNTIME_DIR/windra-session.log"
```

Nếu biến runtime của TTY khác phiên đồ họa, tìm log bằng:

```bash
find /run/user -maxdepth 2 -name windra-session.log -print -exec cat {} \; 2>/dev/null
```

Log cố ý chỉ ghi thông tin khởi động cần thiết, không dump toàn bộ environment và không ghi secret.

## Kiểm tra tiến trình

```bash
ps -ef | grep -E 'sddm|kwin_wayland|windra-session|windra-shell' | grep -v grep
```

Kỳ vọng có `kwin_wayland` và `windra-shell`.

Nếu có KWin nhưng không có shell, đọc `windra-session.log`.
Nếu không có KWin, xem log display manager:

```bash
journalctl -b -u sddm --no-pager
```

và log KWin trong journal:

```bash
journalctl -b --no-pager | grep -iE 'kwin|wayland|drm|egl|opengl|windra'
```

## Kiểm tra Wayland socket

Trong log phải có `WAYLAND_DISPLAY`, thường là `wayland-0`.
Socket tương ứng phải tồn tại:

```bash
ls -l "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
```

`windra-session-start` sẽ dừng với mã 78 nếu KWin gọi session mà không truyền
`WAYLAND_DISPLAY`, hoặc nếu socket được chỉ định không tồn tại. Mục tiêu là biến
"màn hình đen im lặng" thành lỗi có thể đọc được.

## QEMU

Build và chạy:

```bash
./tools/build-iso.sh
./tools/run-qemu.sh "$PWD/out/windra-0.2-desktop-alpha-amd64.iso"
```

Trong WSL2 thường không có KVM, nên boot chậm là bình thường. Wi-Fi trong QEMU là
Ethernet ảo và không dùng để xác nhận driver Wi-Fi vật lý.

## Không phải lỗi

- `foot` kéo dependency terminal/terminfo của Debian theo dependency graph: không cần tự nhét thêm `ncurses-term` chỉ vì terminal dùng terminfo.
- Wi-Fi list trống trong QEMU/WSL2 không chứng minh Wi-Fi backend hỏng.

## Khi vẫn còn màn hình đen

Thu thập bốn đầu ra sau:

```bash
cat /run/user/*/windra-session.log 2>/dev/null
journalctl -b -u sddm --no-pager
journalctl -b --no-pager | grep -iE 'kwin|wayland|drm|egl|opengl|windra'
ps -ef | grep -E 'sddm|kwin_wayland|windra-session|windra-shell' | grep -v grep
```

Từ đó có thể phân biệt ba lớp lỗi: display manager, compositor/graphics, hay Windra Shell/QML.
