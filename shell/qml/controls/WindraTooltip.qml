import QtQuick
import QtQuick.Window
import "../design/Theme.js" as Theme

/*!
 * Tooltip nhẹ theo phong cách Windra.
 *
 * Đặt bên trong item cần tooltip và bind `show`. Tự canh trong màn hình nên
 * icon sát mép phải không bị tràn.
 */
Item {
    id: root

    property string text: ""
    property bool show: false
    property bool reduceMotion: false
    //! "below" hoặc "above" so với item cha.
    property string side: "below"
    property int gap: 8

    z: 100
    width: bubble.width
    height: bubble.height
    visible: opacity > 0.01
    opacity: show && text.length > 0 ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.reduceMotion ? 70 : Theme.hoverDuration
            easing.type: Easing.OutCubic
        }
    }

    // Canh giữa theo cha, kẹp lại nếu tràn khỏi cửa sổ.
    x: {
        var centered = (parent ? parent.width / 2 : 0) - width / 2
        if (!parent || !parent.parent)
            return centered
        var origin = parent.mapToItem(null, 0, 0)
        var absolute = origin.x + centered
        var limit = Screen.width - width - 8
        if (absolute < 8)
            return centered + (8 - absolute)
        if (absolute > limit)
            return centered - (absolute - limit)
        return centered
    }
    y: side === "above" ? -height - gap : (parent ? parent.height + gap : 0)

    Rectangle {
        id: bubble
        width: label.implicitWidth + 20
        height: label.implicitHeight + 12
        radius: 9
        color: "#e6111517"

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: "#ffffff"
            font.pixelSize: 12
        }
    }
}
