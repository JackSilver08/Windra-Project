import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Một dòng trong danh sách popup (mạng Wi-Fi, ứng dụng đang chạy).
 *
 * `leading` / `trailing` nhận Component để nhét icon hoặc nút phụ vào mà không
 * cần default-property alias (alias đó sẽ nuốt luôn các item nền của file này).
 */
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool highlighted: false
    property bool reduceMotion: false
    property alias hovered: mouse.containsMouse

    property Component leading: null
    property Component trailing: null
    property int leadingWidth: leading ? 26 : 0
    property int trailingWidth: trailing ? 26 : 0

    signal clicked()

    implicitHeight: 44
    radius: Theme.radiusSmall
    color: highlighted
        ? "#1a22a7df"
        : (mouse.containsMouse ? Theme.hover : "transparent")

    Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Loader {
        id: leadingSlot
        active: root.leading !== null
        sourceComponent: root.leading
        width: root.leadingWidth
        anchors.left: parent.left
        anchors.leftMargin: root.leadingWidth > 0 ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
    }

    Loader {
        id: trailingSlot
        active: root.trailing !== null
        sourceComponent: root.trailing
        width: root.trailingWidth
        anchors.right: parent.right
        anchors.rightMargin: root.trailingWidth > 0 ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.left: leadingSlot.right
        anchors.leftMargin: 10
        anchors.right: trailingSlot.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            color: Theme.ink
            font.pixelSize: 14
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
