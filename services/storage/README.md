# windra-storage

Service này **chưa triển khai thao tác partition** trong Foundation.

Lý do: resize/format/partition có thể làm mất dữ liệu. Windra sẽ xây API theo hai pha:

1. `Plan*`: chỉ phân tích và trả về kế hoạch, không ghi đĩa.
2. `ApplyPlan`: yêu cầu Polkit, xác nhận fingerprint của plan, sau đó mới gọi UDisks2/libblockdev.

Xem `system/dbus/org.windra.Storage1.xml`.
