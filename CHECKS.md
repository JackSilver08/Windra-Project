# Kiểm tra Windra 0.2

Windra ưu tiên **unit test trước**, rồi mới tới smoke test UI/ISO. Vì code hiện tại là C++/Qt + Go nên framework tương ứng là **Qt Test** và `go test`; NUnit sẽ được dùng nếu sau này dự án có module .NET/C#.

## Một lệnh cho vòng lặp dev

```bash
bash tools/test.sh
```

Lệnh trên thực hiện:

- configure/build test target C++ bằng CMake + Ninja;
- chạy `ctest --output-on-failure`;
- `go test ./...` và `go vet ./...` cho `services/health`;
- `go test ./...` và `go vet ./...` cho `services/webapps`;
- `bash -n` cho toàn bộ script trong `tools/`.

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

`.github/workflows/ci.yml` chạy cùng bộ test trên Debian 13 cho mọi push/PR vào `main`.

## UI / runtime

Sau khi unit test xanh, build và chạy shell thật:

```bash
./tools/bootstrap-debian.sh
./tools/dev-run.sh
```

Với Wi-Fi mock trong WSL:

```bash
WINDRA_WIFI_MOCK=1 ./build/shell/windra-shell --windowed
```

ISO/QEMU chỉ chạy sau khi shell windowed và unit tests đều pass.
