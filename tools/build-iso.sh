#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_SOURCE_DIR="$ROOT/iso"
OUTPUT_DIR="$ROOT/out"
OUTPUT_ISO="$OUTPUT_DIR/windra-0.2-desktop-alpha-amd64.iso"

for command_name in cmake ninja lb xorriso unsquashfs; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Thiếu $command_name. Cài công cụ build bằng:" >&2
    echo "  sudo apt install cmake ninja-build live-build xorriso squashfs-tools" >&2
    exit 1
  fi
done

if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
  echo "live-build cần quyền root, nhưng máy chưa có sudo." >&2
  exit 1
fi

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

# live-build tạo symlink, device node và file thuộc root. Dựng trên filesystem
# Linux thay vì /mnt/c để WSL không làm sai quyền hoặc kiểu file trong chroot.
WORK_DIR="$(mktemp -d /var/tmp/windra-iso.XXXXXXXX)"
APP_BUILD_DIR="$WORK_DIR/app-build"
LIVE_BUILD_DIR="$WORK_DIR/live-build"
BUILD_SUCCEEDED=0

cleanup() {
  if (( BUILD_SUCCEEDED == 1 )); then
    case "$WORK_DIR" in
      /var/tmp/windra-iso.*) as_root rm -rf -- "$WORK_DIR" ;;
      *) echo "Không xoá thư mục tạm bất thường: $WORK_DIR" >&2 ;;
    esac
  else
    echo "Giữ thư mục build để chẩn đoán: $WORK_DIR" >&2
  fi
}
trap cleanup EXIT

echo "[1/5] Build Windra Shell và ứng dụng..."
cmake -S "$ROOT" -B "$APP_BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$APP_BUILD_DIR" --parallel

echo "[2/5] Chuẩn bị filesystem live..."
mkdir -p "$LIVE_BUILD_DIR"
cp -a "$ISO_SOURCE_DIR/auto" "$ISO_SOURCE_DIR/config" "$LIVE_BUILD_DIR/"
DESTDIR="$LIVE_BUILD_DIR/config/includes.chroot" cmake --install "$APP_BUILD_DIR"
install -m 0755 "$ROOT/tools/check-wifi.sh" \
  "$LIVE_BUILD_DIR/config/includes.chroot/usr/bin/windra-check-wifi"

for binary_name in windra-shell windra-files windra-calc windra-notes windra-settings; do
  binary_path="$LIVE_BUILD_DIR/config/includes.chroot/usr/bin/$binary_name"
  if [[ ! -x "$binary_path" ]]; then
    echo "Thiếu binary trong ISO: /usr/bin/$binary_name" >&2
    exit 1
  fi
done

chmod 0755 \
  "$LIVE_BUILD_DIR/config/includes.chroot/usr/bin/windra-session" \
  "$LIVE_BUILD_DIR/config/includes.chroot/usr/bin/windra-session-start" \
  "$LIVE_BUILD_DIR/config/hooks/live/0100-enable-windra.hook.chroot"

echo "[3/5] Cấu hình live-build..."
cd "$LIVE_BUILD_DIR"
./auto/config

echo "[4/5] Dựng ISO Debian Live..."
as_root lb build

built_iso="$(find "$LIVE_BUILD_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "$built_iso" ]]; then
  echo "Build hoàn tất nhưng không tìm thấy file ISO." >&2
  exit 1
fi

squashfs="$(find "$LIVE_BUILD_DIR/binary/live" -maxdepth 1 -type f -name 'filesystem.squashfs' -print -quit)"
if [[ -z "$squashfs" ]]; then
  echo "ISO không có filesystem.squashfs để kiểm tra." >&2
  exit 1
fi

required_paths=(
  usr/bin/windra-shell
  usr/bin/windra-files
  usr/bin/windra-calc
  usr/bin/windra-notes
  usr/bin/windra-settings
  usr/bin/windra-session
  usr/bin/windra-session-start
  usr/bin/windra-check-wifi
  usr/bin/kwin_wayland
  usr/bin/sddm
  usr/bin/foot
  usr/bin/fcitx5
  usr/sbin/NetworkManager
  usr/sbin/wpa_supplicant
  usr/share/wayland-sessions/windra.desktop
  etc/sddm.conf.d/windra.conf
  etc/skel/.config/fcitx5/profile
  etc/systemd/system/display-manager.service
  etc/systemd/system/multi-user.target.wants/NetworkManager.service
)

for required_path in "${required_paths[@]}"; do
  if ! unsquashfs -ll "$squashfs" "$required_path" 2>/dev/null | grep -Fq "$required_path"; then
    echo "Kiểm tra thất bại: /$required_path không nằm trong filesystem live." >&2
    exit 1
  fi
done

package_status="$WORK_DIR/package-status"
unsquashfs -cat "$squashfs" var/lib/dpkg/status > "$package_status"

package_is_installed() {
  awk -v target="$1" '
    BEGIN { RS=""; FS="\n" }
    {
      package = ""
      status = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^Package: /) package = substr($i, 10)
        if ($i ~ /^Status: /) status = substr($i, 9)
      }
      if (package == target && status == "install ok installed") {
        found = 1
        exit
      }
    }
    END { exit found ? 0 : 1 }
  ' "$package_status"
}

required_packages=(
  sddm
  kwin-wayland
  network-manager
  wpasupplicant
  firmware-iwlwifi
  firmware-realtek
  firmware-sof-signed
  polkitd
  polkit-kde-agent-1
  libpam-systemd
  foot
  fcitx5
  fcitx5-unikey
  chromium
  chromium-sandbox
  qt6-wayland
  qml6-module-qtquick-dialogs
  usbutils
)

for package_name in "${required_packages[@]}"; do
  if ! package_is_installed "$package_name"; then
    echo "Kiểm tra thất bại: gói $package_name chưa được cài trong filesystem live." >&2
    exit 1
  fi
done

if ! xorriso -indev "$built_iso" -report_el_torito plain 2>&1 | grep -q 'El Torito boot img'; then
  echo "Kiểm tra thất bại: ISO không có boot image El Torito." >&2
  exit 1
fi

echo "[5/5] Xuất ISO đã kiểm tra..."
mkdir -p "$OUTPUT_DIR"
install -m 0644 "$built_iso" "$OUTPUT_ISO.tmp"
mv -f "$OUTPUT_ISO.tmp" "$OUTPUT_ISO"

BUILD_SUCCEEDED=1
echo "ISO: $OUTPUT_ISO"
