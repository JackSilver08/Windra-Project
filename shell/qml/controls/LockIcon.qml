import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Ổ khoá nhỏ cho mạng Wi-Fi có mật khẩu.
 *
 * Vẽ bằng Canvas thay vì emoji 🔒: emoji phụ thuộc font hệ thống và ra ô vuông
 * trên bản Debian tối giản không cài font emoji.
 */
Canvas {
    id: root

    property color strokeColor: Theme.textMuted

    implicitWidth: 12
    implicitHeight: 14

    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var bodyW = width * 0.86
        var bodyH = height * 0.56
        var bodyX = (width - bodyW) / 2
        var bodyY = height - bodyH
        var radius = Math.max(1, bodyW * 0.16)

        ctx.strokeStyle = root.strokeColor
        ctx.fillStyle = root.strokeColor
        ctx.lineWidth = Math.max(1, width * 0.14)

        // Quai khoá
        var shackleR = bodyW * 0.30
        ctx.beginPath()
        ctx.arc(width / 2, bodyY - shackleR * 0.15, shackleR, Math.PI, 0, false)
        ctx.stroke()

        // Thân khoá
        ctx.beginPath()
        ctx.moveTo(bodyX + radius, bodyY)
        ctx.lineTo(bodyX + bodyW - radius, bodyY)
        ctx.quadraticCurveTo(bodyX + bodyW, bodyY, bodyX + bodyW, bodyY + radius)
        ctx.lineTo(bodyX + bodyW, bodyY + bodyH - radius)
        ctx.quadraticCurveTo(bodyX + bodyW, bodyY + bodyH, bodyX + bodyW - radius, bodyY + bodyH)
        ctx.lineTo(bodyX + radius, bodyY + bodyH)
        ctx.quadraticCurveTo(bodyX, bodyY + bodyH, bodyX, bodyY + bodyH - radius)
        ctx.lineTo(bodyX, bodyY + radius)
        ctx.quadraticCurveTo(bodyX, bodyY, bodyX + radius, bodyY)
        ctx.closePath()
        ctx.fill()
    }
}
