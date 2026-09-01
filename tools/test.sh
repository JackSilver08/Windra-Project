#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${WINDRA_TEST_BUILD_DIR:-$ROOT/build-tests}"

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
