# Windra 0.1 Foundation Notes

Repository foundation này được tạo từ tài liệu dự án và mockup UI đã chốt của Windra.

Các phần đã hoạt động độc lập với Qt:

- `windra-webapp`: CLI cài/gỡ/liệt kê Web Apps.
- `windra-health`: CLI đọc RAM và dung lượng root.

Phần Qt/QML cần cài Qt 6 trên máy Linux để build. Môi trường tạo artifact hiện tại không có Qt 6 dev packages nên shell chưa được compile tại đây.

Storage partitioning chỉ có interface/spec, chưa có code ghi đĩa.
