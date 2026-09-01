#!/usr/bin/env bash
#
# Chẩn đoán Wi-Fi cho Windra.
#
# Chạy trên bất kỳ máy Linux nào (live USB, VM, bản cài thật) để trả lời:
#   1. Card Wi-Fi có được kernel nhận và nạp đúng driver không?
#   2. NetworkManager có thấy nó không?
#   3. Chính xác những lời gọi D-Bus mà Windra dùng có hoạt động không?
#
# Không cần build Windra. Không thay đổi gì trên máy — chỉ đọc.
#
# Trong source tree: sudo ./tools/check-wifi.sh
# Trên Windra Live:  sudo windra-check-wifi
#
# Kết quả được lưu vào một file riêng theo effective UID trong /tmp. Script luôn
# in chính xác đường dẫn ở dòng cuối để không đọc nhầm báo cáo cũ.

set -uo pipefail

DEFAULT_REPORT="${TMPDIR:-/tmp}/windra-wifi-report-${EUID}.txt"
REPORT="${WINDRA_WIFI_REPORT:-$DEFAULT_REPORT}"

# /tmp thường bật fs.protected_regular. Khi file cố định cũ thuộc user khác,
# ngay cả lần chạy qua sudo cũng có thể không truncate được. Không xoá file của
# người dùng; chuyển sang file mktemp do chính tiến trình hiện tại sở hữu.
if ! : >"$REPORT" 2>/dev/null; then
    REPORT=$(mktemp "${TMPDIR:-/tmp}/windra-wifi-report.XXXXXX.txt") || {
        echo "Không tạo được file báo cáo trong ${TMPDIR:-/tmp}." >&2
        exit 1
    }
fi
chmod 0644 "$REPORT" 2>/dev/null || true
exec > >(tee "$REPORT") 2>&1

NM="org.freedesktop.NetworkManager"
NM_PATH="/org/freedesktop/NetworkManager"

section() { printf '\n=== %s ===\n' "$1"; }
ok()   { printf '  [OK]   %s\n' "$1"; }
bad()  { printf '  [LỖI]  %s\n' "$1"; }
info() { printf '         %s\n' "$1"; }

print_report_path() {
    printf '\nBáo cáo đã lưu: %s\n' "$REPORT"
}
trap print_report_path EXIT

IS_WSL=0
if [ -n "${WSL_INTEROP:-}" ] \
   || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    IS_WSL=1
fi

echo "Windra Wi-Fi check — $(date)"
echo "kernel: $(uname -r)"
echo "distro: $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
if [ "$IS_WSL" -eq 1 ]; then
    info "Đang chạy trong WSL2: Windows giữ card Wi-Fi và chỉ đưa mạng ảo vào Linux."
    info "Báo cáo này không thể xác nhận driver/firmware Wi-Fi của laptop."
fi

# --------------------------------------------------------------- 1. phần cứng
section "1. Thiết bị USB"
if command -v lsusb >/dev/null 2>&1; then
    lsusb
else
    info "chưa có lsusb (sudo apt install usbutils)"
    ls /sys/bus/usb/devices/ 2>/dev/null || info "không có bus USB"
fi

section "2. Interface không dây"
FOUND_WLAN=0
for path in /sys/class/net/*/wireless; do
    [ -e "$path" ] || continue
    iface=$(basename "$(dirname "$path")")
    FOUND_WLAN=1
    driver=$(basename "$(readlink -f "/sys/class/net/$iface/device/driver" 2>/dev/null)" 2>/dev/null)
    ok "$iface  (driver: ${driver:-không rõ})"
done
if [ "$FOUND_WLAN" -eq 0 ]; then
    if [ "$IS_WSL" -eq 1 ]; then
        info "Không có interface không dây — đây là trạng thái bình thường trong WSL2."
        info "Hãy chạy script sau khi boot Debian/Windra trực tiếp trên laptop."
    else
        bad "Không có interface không dây nào."
        info "Kernel chưa nạp được driver cho card Wi-Fi."
        info "Xem mục 3 để biết có phải thiếu firmware không."
    fi
fi

section "3. Driver / firmware trong dmesg"
if DMESG_OUTPUT=$(dmesg 2>&1); then
    DMESG_WIFI=$(printf '%s\n' "$DMESG_OUTPUT" \
        | grep -iE "firmware|iwlwifi|rtl|rtw|mt7|ath" | tail -25 || true)
    if [ -n "$DMESG_WIFI" ]; then
        printf '%s\n' "$DMESG_WIFI"
    elif [ "$IS_WSL" -eq 1 ]; then
        info "không có log driver Wi-Fi — WSL2 không sở hữu card Wi-Fi vật lý"
    else
        info "đọc được dmesg nhưng không thấy log driver/firmware Wi-Fi"
    fi
else
    info "kernel từ chối đọc dmesg: ${DMESG_OUTPUT:-không rõ lý do}"
    info "Nếu chưa dùng quyền root, chạy lại bằng sudo."
fi

section "4. rfkill (Wi-Fi có bị chặn cứng/mềm không?)"
if command -v rfkill >/dev/null 2>&1; then
    rfkill list
    if rfkill list 2>/dev/null | grep -q "yes"; then
        bad "Có thiết bị đang bị chặn — bỏ chặn bằng: sudo rfkill unblock all"
    fi
else
    if [ "$IS_WSL" -eq 1 ]; then
        info "không có rfkill — bình thường trong WSL2"
    else
        info "chưa có rfkill (sudo apt install rfkill)"
    fi
fi

# --------------------------------------------------------- 5. NetworkManager
section "5. NetworkManager"
if ! command -v nmcli >/dev/null 2>&1; then
    if [ "$IS_WSL" -eq 1 ]; then
        info "NetworkManager không được cài trong WSL theo chủ đích để tránh giành eth0."
    else
        bad "Chưa cài NetworkManager (sudo apt install network-manager)"
    fi
else
    ok "nmcli: $(nmcli --version)"
    echo
    nmcli device status || true
    echo
    echo "--- nmcli device wifi list ---"
    nmcli device wifi list 2>&1 | head -20 || true
fi

if command -v wpa_supplicant >/dev/null 2>&1; then
    ok "wpa_supplicant có"
elif [ "$IS_WSL" -eq 1 ]; then
    info "wpasupplicant không cần trong WSL2 vì không có radio Wi-Fi"
else
    bad "thiếu wpasupplicant — NetworkManager không nối được Wi-Fi"
fi

# ------------------------------------- 6. D-Bus: đúng những gì Windra gọi
section "6. D-Bus — chính xác các lời gọi Windra dùng"

if ! command -v busctl >/dev/null 2>&1; then
    bad "không có busctl, bỏ qua phần này"
    exit 0
fi

prop() { busctl --system get-property "$NM" "$1" "$2" "$3" 2>/dev/null; }

# 6.1 NetworkManager có trên bus không
if version=$(prop "$NM_PATH" "$NM" Version); then
    ok "NetworkManager trên system bus — Version $version"
else
    if [ "$IS_WSL" -eq 1 ]; then
        info "Không có NetworkManager trên system bus — đúng với cấu hình dev WSL2."
        info "Dùng tools/dev-run.sh --mock-wifi để kiểm giao diện trong WSL."
    else
        bad "Không nói chuyện được với NetworkManager qua D-Bus."
        info "Windra sẽ rơi về backend nmcli, hoặc báo 'Wi-Fi không khả dụng'."
    fi
    exit 0
fi

# 6.2 WirelessEnabled — Windra dùng để bật/tắt công tắc Wi-Fi
enabled=$(prop "$NM_PATH" "$NM" WirelessEnabled)
info "WirelessEnabled = ${enabled:-?}"

# 6.3 GetAllDevices -> tìm device có DeviceType == 2 (Wi-Fi)
devices=$(busctl --system call "$NM" "$NM_PATH" "$NM" GetAllDevices 2>/dev/null \
          | grep -oE '"/org/freedesktop/NetworkManager/Devices/[0-9]+"' | tr -d '"')
if [ -z "$devices" ]; then
    bad "GetAllDevices không trả về gì."
    exit 0
fi
ok "GetAllDevices trả về $(echo "$devices" | wc -l) thiết bị"

WIFI_DEV=""
for dev in $devices; do
    dtype=$(prop "$dev" "$NM.Device" DeviceType | awk '{print $2}')
    iface=$(prop "$dev" "$NM.Device" Interface | sed 's/^s //; s/"//g')
    info "$iface  DeviceType=$dtype"
    [ "$dtype" = "2" ] && WIFI_DEV="$dev"
done

if [ -z "$WIFI_DEV" ]; then
    bad "Không có thiết bị nào DeviceType == 2 (Wi-Fi)."
    info "Windra sẽ báo 'Wi-Fi không khả dụng' — đúng như trên WSL."
    exit 0
fi
ok "Tìm thấy thiết bị Wi-Fi: $WIFI_DEV"

# 6.4 RequestScan + GetAllAccessPoints — trái tim của popup Wi-Fi
busctl --system call "$NM" "$WIFI_DEV" "$NM.Device.Wireless" \
       RequestScan 'a{sv}' 0 >/dev/null 2>&1 \
    && ok "RequestScan chấp nhận" \
    || bad "RequestScan bị từ chối (có thể do quyền Polkit)"

sleep 4

aps=$(busctl --system call "$NM" "$WIFI_DEV" "$NM.Device.Wireless" \
      GetAllAccessPoints 2>/dev/null \
      | grep -oE '"/org/freedesktop/NetworkManager/AccessPoint/[0-9]+"' | tr -d '"')

if [ -z "$aps" ]; then
    bad "GetAllAccessPoints trả về rỗng."
    exit 0
fi
ok "GetAllAccessPoints: $(echo "$aps" | wc -l) access point"

echo
printf '  %-28s %-8s %-10s %s\n' SSID SIGNAL SECURITY "(cờ)"
for ap in $aps; do
    # Ssid là 'ay' — busctl in ra dãy số byte, đổi lại thành chữ.
    ssid=$(prop "$ap" "$NM.AccessPoint" Ssid \
           | sed 's/^ay [0-9]* //' \
           | tr ' ' '\n' | grep -E '^[0-9]+$' \
           | while read -r b; do printf "\\$(printf '%03o' "$b")"; done)
    strength=$(prop "$ap" "$NM.AccessPoint" Strength | awk '{print $2}')
    wpa=$(prop "$ap" "$NM.AccessPoint" WpaFlags | awk '{print $2}')
    rsn=$(prop "$ap" "$NM.AccessPoint" RsnFlags | awk '{print $2}')

    # Cùng logic securityFor() trong NetworkManagerBackend.cpp
    combined=$(( ${wpa:-0} | ${rsn:-0} ))
    if   (( combined & 0x2200 )); then sec="enterprise"
    elif (( combined & 0x1800 )); then sec="owe"
    elif (( combined & 0x100  )); then sec="psk"
    elif (( combined & 0x400  )); then sec="sae"
    elif (( combined != 0 ));     then sec="psk"
    else                               sec="open"
    fi

    printf '  %-28s %-8s %-10s wpa=%s rsn=%s\n' \
           "${ssid:-<ẩn>}" "${strength:-?}" "$sec" "${wpa:-0}" "${rsn:-0}"
done

# 6.5 ListConnections + GetSettings — dùng cùng kiểu lồng a{sa{sv}} với
#     AddAndActivateConnection, nên chạy được ở đây là tín hiệu rất tốt.
section "7. Kiểu dữ liệu lồng nhau (a{sa{sv}})"
conns=$(busctl --system call "$NM" "$NM_PATH/Settings" "$NM.Settings" \
        ListConnections 2>/dev/null \
        | grep -oE '"/org/freedesktop/NetworkManager/Settings/[0-9]+"' | tr -d '"')
if [ -z "$conns" ]; then
    info "Chưa có connection profile nào đã lưu (máy mới thì bình thường)."
else
    ok "ListConnections: $(echo "$conns" | wc -l) profile"
    first=$(echo "$conns" | head -1)
    if busctl --system call "$NM" "$first" "$NM.Settings.Connection" \
              GetSettings >/dev/null 2>&1; then
        ok "GetSettings giải mã được a{sa{sv}} — cùng kiểu với AddAndActivateConnection"
    else
        bad "GetSettings thất bại"
    fi
fi

section "KẾT LUẬN"
echo "Nếu mục 2 có interface và mục 6 liệt kê được SSID thật,"
echo "thì adapter chạy tốt trên Linux và đường D-Bus của Windra là đúng."
