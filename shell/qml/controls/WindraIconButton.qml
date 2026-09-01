import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Nút icon của status island / popup.
 *
 * Micro-interaction theo Windra Motion Design: hover scale <= 1.04 trong ~120ms,
 * press hạ nhẹ rồi bật lại. Reduce Motion bỏ hẳn scale.
 *
 * Nội dung (icon) khai báo như child bình thường — cố ý không dùng
 * default-property alias vì nó sẽ nuốt luôn nền và MouseArea của chính file này.
 */
Item {
    id: root

    property string tooltip: ""
    property bool reduceMotion: false
    property bool active: false          //!< popup của nút này đang mở
    property bool showBackground: true
    property real backgroundRadius: Theme.radiusSmall
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias acceptedButtons: mouse.acceptedButtons

    signal clicked()
    signal rightClicked()

    implicitWidth: 44
    implicitHeight: 44

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
        color: root.active ? "#33ffffff" : (mouse.containsMouse ? "#26ffffff" : "transparent")
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
