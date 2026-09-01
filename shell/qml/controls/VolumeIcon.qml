import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Icon loa vẽ động: số vòng sóng đổi theo mức âm lượng, mute thì gạch chéo.
 * Giữ đúng hình dáng của volume.svg gốc.
 */
Canvas {
    id: root

    //! mute | low | medium | high
    property string level: "medium"
    property bool unavailable: false
    property color strokeColor: Theme.ink

    implicitWidth: 30
    implicitHeight: 30

    onLevelChanged: requestPaint()
    onUnavailableChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        // Vẽ trên lưới 64x64 rồi scale, để tỉ lệ giống bộ icon gốc.
        var s = Math.min(width, height) / 64
        ctx.save()
        ctx.scale(s, s)
        ctx.translate((width / s - 64) / 2, (height / s - 64) / 2)

        ctx.fillStyle = root.strokeColor
        ctx.strokeStyle = root.strokeColor
        ctx.lineWidth = 5
        ctx.lineCap = "round"

        // Thân loa
        ctx.beginPath()
        ctx.moveTo(10, 26)
        ctx.lineTo(22, 26)
        ctx.lineTo(36, 14)
        ctx.lineTo(36, 50)
        ctx.lineTo(22, 38)
        ctx.lineTo(10, 38)
        ctx.closePath()
        ctx.fill()

        if (root.unavailable) {
            ctx.beginPath()
            ctx.moveTo(43, 20)
            ctx.lineTo(57, 44)
            ctx.stroke()
            ctx.restore()
            return
        }

        if (root.level === "mute") {
            // Dấu X thay cho sóng.
            ctx.beginPath()
            ctx.moveTo(44, 24)
            ctx.lineTo(58, 40)
            ctx.moveTo(58, 24)
            ctx.lineTo(44, 40)
            ctx.stroke()
            ctx.restore()
            return
        }

        ctx.beginPath()
        ctx.arc(36, 32, 12, -Math.PI / 3, Math.PI / 3, false)
        ctx.stroke()

        if (root.level === "medium" || root.level === "high") {
            ctx.beginPath()
            ctx.arc(36, 32, 21, -Math.PI / 3, Math.PI / 3, false)
            ctx.stroke()
        }

        if (root.level === "high") {
            ctx.beginPath()
            ctx.arc(36, 32, 30, -Math.PI / 3, Math.PI / 3, false)
            ctx.stroke()
        }

        ctx.restore()
    }
}
