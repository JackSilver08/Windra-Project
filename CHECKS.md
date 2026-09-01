# Kiểm tra Windra 0.2

Đã kiểm tra trong gói nguồn này:

- `go test ./...` và `go vet ./...` cho `services/webapps`.
- `go test ./...` và `go vet ./...` cho `services/health`.
- `bash -n` cho các script dev/build/ISO.
- Cấu trúc CMake đã nâng lên 0.2 và build shell + Files + Settings + Calc + Notes mặc định.

Qt/QML cần được compile trên Debian/Ubuntu có Qt 6 development packages. Dùng:

```bash
./tools/bootstrap-debian.sh
./tools/dev-run.sh
```
