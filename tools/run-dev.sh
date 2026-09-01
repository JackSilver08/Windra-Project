#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"

cmake -S "$ROOT" -B "$BUILD" -G Ninja \
  -DWINDRA_BUILD_SHELL=ON \
  -DWINDRA_BUILD_SETTINGS=ON \
  -DWINDRA_BUILD_FILES=ON \
  -DWINDRA_BUILD_CALC=ON \
  -DWINDRA_BUILD_NOTES=ON
cmake --build "$BUILD"
exec "$BUILD/shell/windra-shell" --windowed
