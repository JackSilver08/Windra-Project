import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Icon pin vẽ động theo dung lượng thật.
 *
 * Thay cho battery.svg tĩnh: mức pin, màu cảnh báo và dấu hiệu sạc đều phản ánh
 * trạng thái thật. Giữ đúng nét của bộ icon gốc (viền dày, bo góc nhẹ).
 */
Canvas {
    id: root

    //! 0..100, hoặc -1 khi không đọc được.
    property int percent: -1
    //! critical | low | medium | high | veryhigh | full | unknown
    property string level: "unknown"
    property bool charging: false
    property bool unavailable: false
    property color strokeColor: Theme.ink

    implicitWidth: 40
    implicitHeight: 22

    onPercentChanged: requestPaint()
    onLevelChanged: requestPaint()
    onChargingChanged: requestPaint()
    onUnavailableChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var stroke = Math.max(1.5, height * 0.1)
        var capWidth = width * 0.06
        var bodyWidth = width - capWidth - stroke
        var radius = Math.max(2, height * 0.16)

        ctx.lineWidth = stroke
        ctx.strokeStyle = root.strokeColor
        ctx.fillStyle = root.strokeColor

        // Vỏ pin
        var x = stroke / 2
        var y = stroke / 2
        var w = bodyWidth
        var h = height - stroke
        ctx.beginPath()
        ctx.moveTo(x + radius, y)
        ctx.lineTo(x + w - radius, y)
        ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
        ctx.lineTo(x + w, y + h - radius)
        ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
        ctx.lineTo(x + radius, y + h)
        ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
        ctx.lineTo(x, y + radius)
        ctx.quadraticCurveTo(x, y, x + radius, y)
        ctx.closePath()
        ctx.stroke()

        // Đầu cực dương
        ctx.beginPath()
        ctx.rect(x + w + stroke * 0.6, height * 0.32, capWidth, height * 0.36)
        ctx.fill()

        if (root.unavailable || root.percent < 0) {
            // Không có pin: gạch chéo thay vì vẽ mức giả.
            ctx.beginPath()
            ctx.moveTo(x + w * 0.22, y + h * 0.78)
            ctx.lineTo(x + w * 0.78, y + h * 0.22)
            ctx.stroke()
            return
        }

        // Mức pin
        var innerPad = stroke * 1.4
        var innerX = x + innerPad
        var innerY = y + innerPad
        var innerW = w - innerPad * 2
        var innerH = h - innerPad * 2
        var fillW = Math.max(0, innerW * Math.min(100, root.percent) / 100)

        ctx.fillStyle = Theme.batteryColor(root.level)
        if (fillW > 0.5) {
            ctx.beginPath()
            ctx.rect(innerX, innerY, fillW, innerH)
            ctx.fill()
        }

        if (root.charging) {
            // Tia sạc nằm đè lên mức pin, tô ngược màu để luôn đọc được.
            var cx = x + w / 2
            var cy = y + h / 2
            var bw = w * 0.16
            var bh = h * 0.62
            ctx.fillStyle = "#ffffff"
            ctx.strokeStyle = root.strokeColor
            ctx.lineWidth = Math.max(1, stroke * 0.55)
            ctx.beginPath()
            ctx.moveTo(cx + bw * 0.35, cy - bh / 2)
            ctx.lineTo(cx - bw * 0.75, cy + bh * 0.12)
            ctx.lineTo(cx - bw * 0.05, cy + bh * 0.12)
            ctx.lineTo(cx - bw * 0.35, cy + bh / 2)
            ctx.lineTo(cx + bw * 0.85, cy - bh * 0.10)
            ctx.lineTo(cx + bw * 0.10, cy - bh * 0.10)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()
        }
    }
}
