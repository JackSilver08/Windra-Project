# Roadmap Windra

## 0.1 Foundation ✅

- [x] Chốt stack Linux/Debian + Wayland + Qt/QML + C++ + Go.
- [x] Repository structure.
- [x] Windra Shell proof-of-concept.
- [x] Web App Manager CLI.
- [x] System Health CLI.
- [x] D-Bus/systemd/Wayland session skeleton.
- [x] Debian live-build skeleton.
- [x] Chạy shell thành công trên WSL2 Debian + WSLg.

## 0.2 Desktop Alpha 🚧

- [x] UI bám mockup chính thức.
- [x] Motion intro và micro-interaction nhẹ.
- [x] Launcher alpha + app search + web fallback.
- [x] Dock có launch app và running indicator.
- [x] Quick Settings alpha.
- [x] Notification toast.
- [x] Power Menu preview-safe.
- [x] Windra Files duyệt filesystem thật.
- [x] Windra Calc.
- [x] Windra Notes mở/lưu text.
- [x] Windra Settings alpha.
- [ ] Đọc `.desktop` files thật thay cho danh sách app tĩnh.
- [ ] Search file bằng index/service.
- [ ] Persist Reduce Motion/theme.
- [ ] Đo và chốt RAM/CPU budget trên WSL và máy Linux thật.

## 0.3 System Alpha

- NetworkManager backend.
- PipeWire/WirePlumber backend.
- BlueZ backend.
- Battery/power via UPower/systemd-logind.
- Settings nối backend thật.
- zram profile cho máy RAM thấp.

## 0.4 Web-first Alpha

- GUI Web App Manager.
- Nhận diện manifest/PWA.
- Install/uninstall Web App bằng một nút.
- Chromium app mode/profile riêng.
- Tích hợp launcher/search.

## 0.5 Files & Storage Alpha

- This Device storage cards thật.
- UDisks2 + libblockdev + Polkit.
- `+ Add Drive`: Plan → Preview → Authenticate → Apply → Verify.
- Không bật resize/format/partition destructive trước khi có test suite.

## 0.6 Bootable Desktop Preview

- Đóng gói Windra apps thành `.deb`.
- Windra Wayland session.
- ISO bootable có desktop alpha.
- Theme Calamares.

## 0.7 Beta

- Hardware smoke tests.
- Update service.
- fwupd.
- Accessibility + Reduce Motion hoàn chỉnh.
- Crash/logging pipeline.

## 1.0

- Desktop ổn định.
- Web-first workflow hoàn chỉnh.
- Update/rollback plan.
- Documentation + security review.
- Hardware compatibility matrix.
