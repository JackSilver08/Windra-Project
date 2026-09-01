import QtQuick
import "../design/Theme.js" as Theme

Rectangle {
    id: root
    property string message: ""
    property bool reduceMotion: false
    width: Math.min(430, Math.max(260, label.implicitWidth + 46))
    height: 58
    radius: 18
    color: Qt.rgba(0.08, 0.09, 0.10, 0.91)
    opacity: 0
    visible: opacity > 0.01

    Text {
        id: label
        anchors.centerIn: parent
        text: root.message
        color: "white"
        font.pixelSize: 14
    }

    SequentialAnimation {
        id: animation
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 70 : 150 }
        PauseAnimation { duration: 1800 }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: root.reduceMotion ? 70 : 170 }
    }

    function show(text) {
        message = text
        animation.restart()
    }
}
