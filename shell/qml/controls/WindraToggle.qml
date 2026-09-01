import QtQuick
import "../design/Theme.js" as Theme

//! Công tắc dạng pill (Wi-Fi ON/OFF).
Item {
    id: root

    property bool checked: false
    property bool enabled: true
    property bool reduceMotion: false

    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    opacity: enabled ? 1 : 0.4

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.hoverStrong
        border.width: 1
        border.color: root.checked ? Theme.accent : Theme.divider

        Behavior on color { ColorAnimation { duration: root.reduceMotion ? 0 : Theme.hoverDuration } }
    }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: Theme.surfaceStrong

        Behavior on x {
            NumberAnimation {
                duration: root.reduceMotion ? 0 : Theme.popupDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
