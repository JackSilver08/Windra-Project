#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Script này dành cho Debian/Ubuntu." >&2
  exit 1
fi

is_wsl() {
  grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

sudo apt-get update

# --- Build ------------------------------------------------------------------
sudo apt-get install -y \
  build-essential cmake ninja-build pkg-config \
  qt6-base-dev qt6-declarative-dev \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-window qml6-module-qtquick-dialogs \
  golang-go

# --- Runtime của shell ------------------------------------------------------
# Thiếu những gói này thì shell vẫn build và chạy, nhưng icon SVG không hiện
# và các popup hệ thống sẽ báo "không khả dụng".
sudo apt-get install -y \
  qt6-svg-plugins \
  qt6-wayland \
  upower \
  power-profiles-daemon \
  pulseaudio-utils

# --- Audio ------------------------------------------------------------------
# WSLg đã có sẵn PulseAudio server (/mnt/wslg/PulseServer) nên chỉ cần pactl ở
# trên là popup Âm lượng chạy được. Cài PipeWire vào WSL là thừa và dễ xung đột.
if ! is_wsl; then
  sudo apt-get install -y pipewire pipewire-pulse wireplumber
fi

# --- Mạng -------------------------------------------------------------------
# Cố ý KHÔNG cài NetworkManager trong WSL: nó sẽ giành quyền quản lý eth0 và có
# thể làm hỏng mạng của WSL, trong khi WSL không có card Wi-Fi nên cũng chẳng
# test được gì. Dùng mock backend để làm việc trên UX Wi-Fi (xem bên dưới).
if is_wsl; then
  cat <<'EOF'

Phát hiện WSL — bỏ qua NetworkManager.
WSL2 không có card Wi-Fi (chỉ eth0/lo) nên popup Wi-Fi sẽ báo không khả dụng.
Để làm việc trên giao diện Wi-Fi, chạy shell với mock backend dành cho dev:

    WINDRA_WIFI_MOCK=1 ./build/shell/windra-shell --windowed

EOF
else
  sudo apt-get install -y network-manager wpasupplicant
fi

echo "Môi trường dev Windra đã sẵn sàng."
