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

    width: root.orb ? 46 : 42
    height: 46
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.97
    transform: Translate { id: introTranslate; y: reduceMotion ? 0 : 6 }

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
        width: 40
        height: 40
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        radius: root.orb ? 20 : 10
        color: mouse.containsMouse
            ? "#19ffffff"
            : (root.orb ? "#111ffffff" : root.tileColor)
        border.width: root.orb ? 1 : 0
        border.color: root.orb ? "#2effffff" : "transparent"
        scale: mouse.pressed ? Theme.pressScale : (mouse.containsMouse ? Theme.hoverScale : 1.0)

        Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
        Behavior on scale { NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic } }

        Image {
            anchors.centerIn: parent
            width: root.orb ? 30 : 29
            height: root.orb ? 30 : 29
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    // Tiny running indicator, deliberately quieter than a glowing app tile.
    Rectangle {
        visible: root.running
        width: 12
        height: 2
        radius: 1
        color: Theme.accent
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
