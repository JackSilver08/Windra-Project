import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo
import "../controls"

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

    width: 42
    height: 48
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.97
    transform: Translate { id: introTranslate; y: reduceMotion ? 0 : 6 }

    function playIntro() { intro.start() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : root.introDelay }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "scale"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: introTranslate; property: "y"; to: 0; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
        }
    }

    WindraCutSurface {
        id: tile
        width: 38
        height: 38
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        cut: 9
        fillColor: mouse.containsMouse
            ? (root.accentTile ? "#2f91ff" : "#f8fbff")
            : (root.accentTile ? root.tileColor : "#d9e1e8")
        borderColor: mouse.containsMouse ? "#ffffff80" : "#aebbc7"
        borderWidth: 1
        shadowColor: "#30000000"
        shadowOffsetX: 3
        shadowOffsetY: 3
        scale: mouse.pressed ? Geo.pressScale : (mouse.containsMouse ? Geo.hoverScale : 1.0)

        Behavior on fillColor { ColorAnimation { duration: Geo.motionFast } }
        Behavior on scale { NumberAnimation { duration: Geo.motionFast; easing.type: Easing.OutCubic } }

        Image {
            anchors.centerIn: parent
            width: 28
            height: 28
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: root.accentTile ? 1.0 : 0.92
        }
    }

    Rectangle {
        visible: root.running
        width: 9
        height: 3
        color: Geo.sapphire
        anchors.horizontalCenter: tile.horizontalCenter
        anchors.bottom: parent.bottom
        rotation: -12
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
