#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$ROOT/out/windra-0.2-desktop-alpha-amd64.iso}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "Thiếu qemu-system-x86_64." >&2
  exit 1
fi
if [[ ! -f "$ISO" ]]; then
  echo "Không tìm thấy ISO: $ISO" >&2
  exit 1
fi

ACCEL=()
[[ -r /dev/kvm ]] && ACCEL=(-enable-kvm)
exec qemu-system-x86_64 "${ACCEL[@]}" -m 4096 -smp 4 -cdrom "$ISO" -boot d
