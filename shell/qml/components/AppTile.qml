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
    property bool orb: false
    property bool accentTile: false
    signal clicked()

    width: orb ? 58 : 48
    height: 56
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
        width: root.orb ? 54 : 46
        height: root.orb ? 54 : 46
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        radius: root.orb ? width / 2 : 11
        color: root.orb
            ? "#c91b3138"
            : (root.accentTile ? "#6d157fca" : root.tileColor)
        border.width: root.orb || root.accentTile ? 1 : 0
        border.color: root.orb ? Theme.chromeBorder : "#6629b8ff"
        opacity: mouse.containsMouse ? 1.0 : 0.92
        scale: mouse.pressed ? 0.94 : mouse.containsMouse ? 1.055 : 1.0

        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }

        Rectangle {
            visible: root.orb
            anchors.fill: parent
            anchors.margins: 4
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#529be8ff"
        }

        Image {
            anchors.centerIn: parent
            width: root.orb ? parent.width * 0.76 : parent.width * 0.82
            height: root.orb ? parent.height * 0.76 : parent.height * 0.82
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Rectangle {
        visible: root.running
        width: 18
        height: 3
        radius: 2
        color: Theme.chromeGlow
        anchors.horizontalCenter: tile.horizontalCenter
        anchors.bottom: parent.bottom
        opacity: 0.95
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
