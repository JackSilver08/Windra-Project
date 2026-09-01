import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Nút chữ của Windra.
 *
 * `primary` cho hành động chính (Kết nối), `selected` cho chip đang chọn
 * (chế độ nguồn), còn lại là nút phụ nền sáng.
 */
Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool selected: false
    property bool enabled: true
    property bool reduceMotion: false
    property int horizontalPadding: 14

    signal clicked()

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: 34
    radius: Theme.radiusSmall
    opacity: enabled ? 1 : 0.42

    color: {
        if (primary) return mouse.containsMouse ? "#1c95c8" : Theme.accent
        if (selected) return "#2622a7df"
        return mouse.containsMouse ? Theme.hoverStrong : Theme.hover
    }
    border.width: selected && !primary ? 1 : 0
    border.color: Theme.accent

    scale: reduceMotion || !enabled ? 1 : (mouse.pressed ? Theme.pressScale : 1)

    Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
    Behavior on scale {
        NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 13
        font.bold: root.primary || root.selected
        color: root.primary ? "#ffffff" : (root.selected ? Theme.accent : Theme.ink)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
