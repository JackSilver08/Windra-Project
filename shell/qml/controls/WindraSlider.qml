import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Slider của Windra.
 *
 * `value` giữ nguyên binding tới backend; `moved` chỉ phát khi **người dùng**
 * kéo, nên volume đổi từ bên ngoài vẫn đẩy được vào UI mà không đá nhau.
 */
Item {
    id: root

    property int from: 0
    property int to: 100
    property int value: 0
    property bool enabled: true
    property bool reduceMotion: false
    property color fillColor: Theme.accent

    //! Phát khi người dùng kéo/nhấn, không phát khi `value` đổi từ code.
    signal moved(int value)

    implicitWidth: 200
    implicitHeight: 28
    opacity: enabled ? 1 : 0.45

    readonly property real span: Math.max(1, to - from)
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / span))
    readonly property real trackWidth: width - handle.width
    readonly property real handleX: ratio * trackWidth

    Rectangle {
        id: groove
        anchors.verticalCenter: parent.verticalCenter
        x: handle.width / 2
        width: root.trackWidth
        height: 6
        radius: 3
        color: Theme.hoverStrong
    }

    Rectangle {
        anchors.verticalCenter: groove.verticalCenter
        x: groove.x
        width: Math.max(0, root.handleX)
        height: groove.height
        radius: groove.radius
        color: root.fillColor
    }

    Rectangle {
        id: handle
        width: 18
        height: 18
        radius: 9
        x: root.handleX
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.surfaceStrong
        border.width: 2
        border.color: root.fillColor
        scale: root.reduceMotion ? 1 : (drag.pressed ? 1.1 : (drag.containsMouse ? 1.05 : 1))

        Behavior on scale {
            NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function apply(mouseX) {
            var position = Math.max(0, Math.min(root.trackWidth,
                                                mouseX - handle.width / 2))
            var next = Math.round(root.from + (position / Math.max(1, root.trackWidth)) * root.span)
            if (next !== root.value)
                root.moved(next)
        }

        onPressed: function(event) { apply(event.x) }
        onPositionChanged: function(event) { if (pressed) apply(event.x) }
    }
}
