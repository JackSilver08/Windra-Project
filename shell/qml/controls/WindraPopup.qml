import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Bề mặt chuẩn cho mọi system popup của Windra.
 *
 * Lo ba việc mà 5 popup không nên tự viết lại:
 *   - motion: fade + slide 10px, 140-180ms, tôn trọng Reduce Motion;
 *   - định vị theo icon tương ứng, tự kẹp trong màn hình (không hardcode toạ độ);
 *   - visual identity: nền sáng bán trong, bo góc, viền mảnh, bóng rất nhẹ.
 */
Item {
    id: root

    property bool open: false
    property bool reduceMotion: false

    //! Icon mà popup này thuộc về. Popup canh giữa theo icon và nằm dưới/trên nó.
    property Item anchorItem: null
    //! "below" = popup nằm dưới anchor (status island); "above" = nằm trên (clock pill).
    property string preferredSide: "below"
    property int gap: 12
    property int screenMargin: 14

    //! Popup trượt từ phía nó xuất hiện: dưới thì trượt xuống, trên thì trượt lên.
    readonly property real hiddenOffset: preferredSide === "above"
        ? Theme.slideFor(reduceMotion)
        : -Theme.slideFor(reduceMotion)

    property alias radius: surface.radius
    property alias surfaceColor: surface.color

    /*!
     * Lề nội dung chuẩn. Popup con khai báo nội dung như child bình thường và
     * dùng `anchors.margins: padding` — không dùng default-property alias vì
     * nó sẽ nuốt cả những item nền bên trong file này.
     */
    readonly property int padding: 20

    implicitWidth: 320
    implicitHeight: 200
    width: implicitWidth
    height: implicitHeight

    visible: opacity > 0.01
    enabled: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.popupMs(root.reduceMotion)
            easing.type: Easing.OutCubic
        }
    }

    transform: Translate {
        y: root.open ? 0 : root.hiddenOffset
        Behavior on y {
            NumberAnimation {
                duration: Theme.popupMs(root.reduceMotion)
                easing.type: Easing.OutCubic
            }
        }
    }

    // --- định vị ------------------------------------------------------------
    onOpenChanged: if (open) reposition()
    onWidthChanged: reposition()
    onHeightChanged: reposition()
    Component.onCompleted: reposition()

    Connections {
        target: root.parent
        ignoreUnknownSignals: true
        function onWidthChanged() { root.reposition() }
        function onHeightChanged() { root.reposition() }
    }

    /*!
     * Canh popup theo anchorItem, ưu tiên `preferredSide`, lật sang phía kia nếu
     * tràn, rồi kẹp trong vùng cha. Hoạt động ở mọi độ phân giải và HiDPI vì mọi
     * thứ đều tính từ kích thước thật lúc chạy.
     */
    function reposition() {
        if (!parent)
            return

        if (!anchorItem) {
            x = Math.max(screenMargin, parent.width - width - screenMargin)
            y = screenMargin
            return
        }

        var point = anchorItem.mapToItem(parent, 0, 0)
        var below = point.y + anchorItem.height + gap
        var above = point.y - height - gap

        var targetY = preferredSide === "above" ? above : below
        if (targetY + height > parent.height - screenMargin)
            targetY = above
        if (targetY < screenMargin)
            targetY = below

        var targetX = point.x + anchorItem.width / 2 - width / 2

        x = Math.max(screenMargin, Math.min(targetX, parent.width - width - screenMargin))
        y = Math.max(screenMargin, Math.min(targetY, parent.height - height - screenMargin))
    }

    // --- bề mặt -------------------------------------------------------------
    // Bóng giả bằng một rectangle lệch nhẹ: rẻ hơn nhiều so với blur shader.
    Rectangle {
        anchors.fill: surface
        anchors.topMargin: 3
        anchors.bottomMargin: -3
        radius: surface.radius
        color: Theme.popupShadow
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.popupSurface
        border.width: 1
        border.color: Theme.popupBorder
    }
}
