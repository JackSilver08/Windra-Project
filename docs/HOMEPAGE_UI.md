# Windra Homepage UI

## Mục tiêu

Homepage của Windra dùng ngôn ngữ **glass HUD nhẹ**: lấy cảm hứng từ giao diện game nhưng vẫn là desktop dùng hằng ngày. Thiết kế ưu tiên cảm giác thoáng, gió, bầu trời và chuyển động nhẹ; không dùng blur/particle nặng để giữ mục tiêu máy yếu.

## Nhận diện

- Màu thương hiệu: xanh cyan → royal blue.
- `windra-mark.svg`: biểu tượng globe + ba luồng gió xoáy.
- `windra-waves.svg`: motif gió dùng ở status island và đuôi dock.
- Wallpaper vẫn là asset Windra hiện tại; chrome được thiết kế để đọc được trên cả nền sáng và tối.

## Chrome homepage

### Dock

- Nằm nổi ở góc trái dưới, không chạm mép màn hình.
- Bề mặt tối bán trong suốt, viền cyan mảnh, glow chân dock.
- Logo Windra nằm trong orb tròn.
- Search box nhỏ, kính sáng.
- App đang chạy có gạch cyan bên dưới.
- Đuôi dock giữ cạnh xiên và wind motif để không biến thành clone Windows/macOS.

### Status island

- Nằm nổi ở góc phải trên.
- Wi-Fi, âm lượng và pin vẫn là ba control độc lập.
- Dùng divider mỏng giữa từng control.
- Pin hiển thị dữ liệu thật và phần trăm như trước.

### Clock pill

- Nằm nổi ở góc phải dưới.
- Mũi tên ứng dụng nền và vùng thời gian vẫn là hai vùng click riêng.
- Giờ lớn, ngày nhỏ, nền glass tối, cyan rim.

## Hiệu năng

Không thêm Gaussian blur, shader, particle hoặc drop-shadow effect đắt GPU. Cảm giác kính được tạo bằng:

- alpha surface;
- border bán trong suốt;
- cyan highlight 1–2 px;
- motion translate/opacity hiện có.

`Reduce Motion` tiếp tục được tôn trọng.

## Các file chính

- `shell/qml/Main.qml`
- `shell/qml/design/Theme.js`
- `shell/qml/components/BottomDock.qml`
- `shell/qml/components/StatusIsland.qml`
- `shell/qml/components/ClockPill.qml`
- `shell/qml/components/SearchBox.qml`
- `shell/qml/components/AppTile.qml`
- `shell/qml/controls/BatteryIcon.qml`

## Kiểm thử

```bash
cmake -S . -B build -G Ninja -DWINDRA_BUILD_SETTINGS=ON
cmake --build build
./build/shell/windra-shell --windowed
```

Kiểm tra tối thiểu ở 1280×720 preview và các màn hình 1366×768, 1600×900, 1920×1080.
