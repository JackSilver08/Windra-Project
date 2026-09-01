import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme

Item {
    id: root
    property string label: "App"
    property url iconSource
    property color tileColor: "transparent"
    property int introDelay: 0
    property bool reduceMotion: false
    property bool running: false
    signal clicked()

    width: 48
    height: 54
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.92
    transform: Translate { id: introTranslate; y: reduceMotion ? 0 : 9 }

    function playIntro() { intro.start() }

    SequentialAnimation {
        id: intro
        running: false
        PauseAnimation { duration: root.reduceMotion ? 0 : root.introDelay }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "scale"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: introTranslate; property: "y"; to: 0; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: tile
        width: 48
        height: 48
        anchors.top: parent.top
        radius: 10
        color: root.tileColor
        opacity: mouse.containsMouse ? 0.95 : 1.0
        scale: mouse.pressed ? 0.94 : mouse.containsMouse ? 1.055 : 1.0

        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.82
            height: parent.height * 0.82
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Rectangle {
        visible: root.running
        width: 16
        height: 3
        radius: 2
        color: Theme.ink
        anchors.horizontalCenter: tile.horizontalCenter
        anchors.bottom: parent.bottom
        opacity: 0.78
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        ToolTip.visible: containsMouse
        ToolTip.text: root.label
        ToolTip.delay: 420
    }
}
