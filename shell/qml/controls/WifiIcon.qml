import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Icon Wi-Fi vẽ động: cung sóng mờ dần theo cường độ tín hiệu thật.
 * `off` gạch chéo, `none` chỉ còn chấm — không bao giờ vẽ full sóng giả.
 */
Canvas {
    id: root

    //! off | none | weak | fair | good
    property string level: "none"
    property color strokeColor: Theme.ink

    implicitWidth: 30
    implicitHeight: 30

    onLevelChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function arcAlpha(index) {
        // index 1 = cung trong cùng, 3 = cung ngoài cùng.
        if (level === "good") return 1.0
        if (level === "fair") return index <= 2 ? 1.0 : 0.22
        if (level === "weak") return index <= 1 ? 1.0 : 0.22
        return 0.22
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var s = Math.min(width, height) / 64
        ctx.save()
        ctx.scale(s, s)
        ctx.translate((width / s - 64) / 2, (height / s - 64) / 2)

        ctx.lineWidth = 5
        ctx.lineCap = "round"
        ctx.strokeStyle = root.strokeColor
        ctx.fillStyle = root.strokeColor

        var arcs = [
            { r: 30, from: -Math.PI * 0.86, to: -Math.PI * 0.14, index: 3 },
            { r: 20, from: -Math.PI * 0.82, to: -Math.PI * 0.18, index: 2 },
            { r: 10, from: -Math.PI * 0.76, to: -Math.PI * 0.24, index: 1 }
        ]

        for (var i = 0; i < arcs.length; ++i) {
            ctx.globalAlpha = root.level === "off" ? 0.22 : root.arcAlpha(arcs[i].index)
            ctx.beginPath()
            ctx.arc(32, 51, arcs[i].r, arcs[i].from, arcs[i].to, false)
            ctx.stroke()
        }

        ctx.globalAlpha = 1
        ctx.beginPath()
        ctx.arc(32, 51, 3.5, 0, Math.PI * 2, false)
        ctx.fill()

        if (root.level === "off") {
            ctx.beginPath()
            ctx.moveTo(14, 52)
            ctx.lineTo(50, 16)
            ctx.stroke()
        }

        ctx.restore()
    }
}
