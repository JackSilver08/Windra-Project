#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"

MOCK_WIFI=0
for arg in "$@"; do
  case "$arg" in
    --mock-wifi) MOCK_WIFI=1 ;;
    -h|--help)
      cat <<'EOF'
Cách dùng: tools/dev-run.sh [--mock-wifi]

  --mock-wifi   Bật backend Wi-Fi giả lập dành cho phát triển.
                Dùng khi máy không có card không dây (ví dụ WSL2).
                Popup sẽ hiện chip DEV MOCK; mật khẩu mọi mạng là windra123.
EOF
      exit 0 ;;
  esac
done

cmake -S "$ROOT" -B "$BUILD" -G Ninja \
  -DWINDRA_BUILD_SHELL=ON \
  -DWINDRA_BUILD_SETTINGS=ON \
  -DWINDRA_BUILD_FILES=ON \
  -DWINDRA_BUILD_CALC=ON \
  -DWINDRA_BUILD_NOTES=ON
cmake --build "$BUILD"

# Máy không có interface không dây thì popup Wi-Fi sẽ luôn báo "không khả dụng".
# Nhắc một lần cho khỏi tưởng là lỗi.
if [ "$MOCK_WIFI" -eq 0 ] && ! compgen -G "/sys/class/net/*/wireless" >/dev/null; then
  cat <<'EOF'

[Windra] Máy này không có card Wi-Fi nên popup Wi-Fi sẽ báo "không khả dụng".
         Đó là hành vi đúng, không phải lỗi.
         Muốn làm việc trên giao diện Wi-Fi: tools/dev-run.sh --mock-wifi

EOF
fi

if [ "$MOCK_WIFI" -eq 1 ]; then
  echo "[Windra] Wi-Fi mock BẬT — dữ liệu giả lập, mật khẩu: windra123"
  export WINDRA_WIFI_MOCK=1
fi

exec "$BUILD/shell/windra-shell" --windowed
