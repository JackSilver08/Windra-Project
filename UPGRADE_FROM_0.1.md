# Nâng cấp từ Windra 0.1 Foundation

## 1. Giữ bản 0.1 làm backup

Trên WSL Debian:

```bash
cd ~
if [ -d "Windra Project" ]; then mv "Windra Project" "Windra Project.backup"; fi
```

Nếu source cũ vẫn là `~/Windra-Foundation`, có thể giữ nguyên. Không cần xóa.

## 2. Đưa source mới vào WSL

Sau khi giải nén gói 0.2 trên Windows thành `C:\Windra Project`:

```bash
cp -a "/mnt/c/Windra Project" "$HOME/Windra Project"
cd "$HOME/Windra Project"
```

Tên folder chuẩn phải là:

```text
Windra Project
```

## 3. Build sạch

```bash
rm -rf build
chmod +x tools/*.sh
./tools/bootstrap-debian.sh
./tools/dev-run.sh
```

Lần sau chỉ cần:

```bash
cd "$HOME/Windra Project"
./tools/dev-run.sh
```

## 4. Test app riêng

```bash
./build/apps/files/windra-files
./build/apps/settings/windra-settings
./build/apps/calc/windra-calc
./build/apps/notes/windra-notes
```

Trong Windra Shell, các icon tương ứng cũng sẽ mở những binary trên.
