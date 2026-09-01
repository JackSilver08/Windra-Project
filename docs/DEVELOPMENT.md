# Phát triển Windra

## Môi trường khuyên dùng

- Debian 13 hoặc Ubuntu LTS.
- Qt 6 / Qt Quick / QML.
- CMake + Ninja.
- Go 1.23+.
- KWin Wayland để test session về sau.

## Vòng lặp phát triển

### UI

```bash
cmake -S . -B build -G Ninja
cmake --build build
./build/shell/windra-shell --windowed
```

`--windowed` cho phép test desktop shell như một app bình thường, không cần VM.

### Fullscreen prototype

```bash
./build/shell/windra-shell
```

### Go services

```bash
make go
./build/bin/windra-health --json
```

### ISO

Chỉ cần VM khi test boot/session/installer/driver:

```bash
sudo apt install live-build xorriso squashfs-tools qemu-system-x86
./tools/build-iso.sh
```

Script build năm binary ở chế độ Release, cài chúng vào `includes.chroot`, dựng
Debian Live và kiểm tra binary, session, dịch vụ, firmware cùng boot image trước
khi xuất file:

```text
out/windra-0.2-desktop-alpha-amd64.iso
```

Boot thử bằng QEMU/KVM:

```bash
./tools/run-qemu.sh "$PWD/out/windra-0.2-desktop-alpha-amd64.iso"
```

Trong WSL2 thường không có `/dev/kvm`, vì vậy QEMU dùng giả lập CPU và khởi động
chậm hơn đáng kể. Card mạng trong QEMU là Ethernet ảo; danh sách Wi-Fi trống
không nói lên điều gì về firmware/card Wi-Fi vật lý của laptop.
