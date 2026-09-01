# Kiểm tra Windra 0.2

Windra ưu tiên **unit test trước**, rồi mới tới smoke test UI/ISO. Vì code hiện tại là C++/Qt + Go nên framework tương ứng là **Qt Test** và `go test`; NUnit sẽ được dùng nếu sau này dự án có module .NET/C#.

## Chạy trong Debian/WSL

```bash
bash tools/test.sh
```

Lệnh trên thực hiện:

- configure/build test target C++ bằng CMake + Ninja;
- chạy `ctest --output-on-failure`;
- `go test ./...` và `go vet ./...` cho `services/health`;
- `go test ./...` và `go vet ./...` cho `services/webapps`;
- `bash -n` cho toàn bộ script trong `tools/`.

## Chạy trực tiếp từ PowerShell

Không dùng `bash tools/test.sh` trong PowerShell vì lệnh `bash` có thể trỏ tới Git Bash/Windows Bash, nơi không có toolchain Qt/CMake của Debian WSL.

Dùng wrapper WSL:

```powershell
.\tools\test.ps1
.\tools\dev-run.ps1
```

Để bật Wi-Fi mock khi chạy giao diện từ WSL2:

```powershell
.\tools\dev-run.ps1 -MockWifi
```

Mặc định các wrapper dùng distro `Debian`. Có thể đổi distro bằng `-Distro`.

## Unit test C++ hiện có

- `windra-test-popup-controller`
  - trạng thái đóng ban đầu;
  - chỉ một popup được active;
  - toggle đóng/mở đúng;
  - không phát signal thừa khi mở lại cùng popup.
- `windra-test-wifi-model`
  - tách mạng đang kết nối khỏi danh sách mạng khả dụng;
  - filter SSID không phân biệt hoa thường và trim khoảng trắng;
  - mapping cường độ tín hiệu thành 0–4 bars;
  - refresh object path của Access Point sau rescan;
  - không phát `filterChanged` thừa.

## CI

`.github/workflows/ci.yml` chạy bộ unit test trên Debian 13 cho mọi push/PR vào `main`, đồng thời build Windra Shell và chạy QML smoke test headless.

## UI / runtime

Sau khi unit test xanh, build và chạy shell thật trong Debian/Ubuntu:

```bash
./tools/bootstrap-debian.sh
./tools/dev-run.sh
```

Với Wi-Fi mock trong WSL:

```bash
./tools/dev-run.sh --mock-wifi
```

ISO/QEMU chỉ chạy sau khi shell windowed và unit tests đều pass.
