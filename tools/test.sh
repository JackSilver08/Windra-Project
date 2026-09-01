#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${WINDRA_TEST_BUILD_DIR:-$ROOT/build-tests}"

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[Windra] Thiếu '$tool' trong môi trường Bash hiện tại." >&2
    if [[ "${OS:-}" == "Windows_NT" || "$(uname -s 2>/dev/null || true)" =~ MINGW|MSYS|CYGWIN ]]; then
      echo "[Windra] Bạn đang chạy Bash của Windows/Git Bash, không phải Debian WSL." >&2
      echo "[Windra] Từ PowerShell hãy dùng: .\\tools\\test.ps1" >&2
    else
      echo "[Windra] Trên Debian/Ubuntu hãy chạy: ./tools/bootstrap-debian.sh" >&2
    fi
    exit 127
  fi
}

require_tool cmake
require_tool ninja
require_tool ctest
require_tool go


echo "== Windra: Qt unit tests =="
cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
  -DBUILD_TESTING=ON \
  -DWINDRA_BUILD_TESTS=ON \
  -DWINDRA_BUILD_SHELL=OFF \
  -DWINDRA_BUILD_SETTINGS=OFF \
  -DWINDRA_BUILD_FILES=OFF \
  -DWINDRA_BUILD_CALC=OFF \
  -DWINDRA_BUILD_NOTES=OFF
cmake --build "$BUILD_DIR"
ctest --test-dir "$BUILD_DIR" --output-on-failure

echo
echo "== Windra: Go tests + vet =="
(
  cd "$ROOT/services/health"
  go test ./...
  go vet ./...
)
(
  cd "$ROOT/services/webapps"
  go test ./...
  go vet ./...
)

echo
echo "== Windra: shell syntax =="
while IFS= read -r -d '' script; do
  bash -n "$script"
done < <(find "$ROOT/tools" -type f -name '*.sh' -print0)

echo
echo "Windra checks passed."
