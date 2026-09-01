#!/usr/bin/env bash
set -euo pipefail
check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "[OK]   %-18s %s\n" "$1" "$(command -v "$1")"
  else
    printf "[MISS] %-18s\n" "$1"
  fi
}
check cmake
check ninja
check g++
check go
check qmake6
check qml6
check lb
check qemu-system-x86_64
