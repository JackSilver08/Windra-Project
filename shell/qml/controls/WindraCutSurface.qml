import QtQuick

Item {
    id: root

    property color fillColor: "#ffffff"
    property color borderColor: "transparent"
    property color shadowColor: "transparent"
    property real borderWidth: 0
    property int cut: 14
    property bool cutTopLeft: false
    property bool cutTopRight: true
    property bool cutBottomLeft: true
    property bool cutBottomRight: false
    property real shadowOffsetX: 0
    property real shadowOffsetY: 0

    Canvas {
        id: shadowCanvas
        anchors.fill: parent
        visible: root.shadowColor.a > 0 && (root.shadowOffsetX !== 0 || root.shadowOffsetY !== 0)
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.translate(root.shadowOffsetX, root.shadowOffsetY)
            drawPath(ctx, root.shadowColor, "transparent", 0)
        }
    }

    Canvas {
        id: surfaceCanvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            drawPath(ctx, root.fillColor, root.borderColor, root.borderWidth)
        }
    }

    function drawPath(ctx, fill, stroke, strokeWidth) {
        const c = Math.max(0, Math.min(root.cut, Math.min(width, height) / 2))

        ctx.beginPath()
        ctx.moveTo(root.cutTopLeft ? c : 0, 0)
        ctx.lineTo(root.cutTopRight ? width - c : width, 0)
        ctx.lineTo(width, root.cutTopRight ? c : 0)
        ctx.lineTo(width, root.cutBottomRight ? height - c : height)
        ctx.lineTo(root.cutBottomRight ? width - c : width, height)
        ctx.lineTo(root.cutBottomLeft ? c : 0, height)
        ctx.lineTo(0, root.cutBottomLeft ? height - c : height)
        ctx.lineTo(0, root.cutTopLeft ? c : 0)
        ctx.closePath()

        if (root.cutTopLeft) {
            ctx.moveTo(c, 0)
            ctx.lineTo(0, c)
        }

        ctx.fillStyle = fill
        ctx.fill()

        if (strokeWidth > 0 && stroke !== "transparent") {
            ctx.lineWidth = strokeWidth
            ctx.strokeStyle = stroke
            ctx.stroke()
        }
    }

    onWidthChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onHeightChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onFillColorChanged: surfaceCanvas.requestPaint()
    onBorderColorChanged: surfaceCanvas.requestPaint()
    onShadowColorChanged: shadowCanvas.requestPaint()
    onBorderWidthChanged: surfaceCanvas.requestPaint()
    onCutChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onCutTopLeftChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onCutTopRightChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onCutBottomLeftChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onCutBottomRightChanged: { shadowCanvas.requestPaint(); surfaceCanvas.requestPaint() }
    onShadowOffsetXChanged: shadowCanvas.requestPaint()
    onShadowOffsetYChanged: shadowCanvas.requestPaint()
}