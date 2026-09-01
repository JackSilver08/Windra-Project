import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Shared icon button for desktop chrome and popups.
 * Feedback is intentionally restrained: a faint hover surface and tiny scale.
 */
Item {
    id: root

    property string tooltip: ""
    property bool reduceMotion: false
    property bool active: false
    property bool showBackground: true
    property real backgroundRadius: Theme.radiusSmall
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias acceptedButtons: mouse.acceptedButtons

    signal clicked()
    signal rightClicked()

    implicitWidth: 40
    implicitHeight: 40

    scale: reduceMotion
        ? 1.0
        : (mouse.pressed ? Theme.pressScale : (mouse.containsMouse ? Theme.hoverScale : 1.0))

    Behavior on scale {
        NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.backgroundRadius
        visible: root.showBackground
        color: root.active ? "#20ffffff" : (mouse.containsMouse ? "#12ffffff" : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: function(event) {
            if (event.button === Qt.RightButton)
                root.rightClicked()
            else
                root.clicked()
        }
    }

    WindraTooltip {
        text: root.tooltip
        show: mouse.containsMouse && !root.active
        reduceMotion: root.reduceMotion
    }
}
