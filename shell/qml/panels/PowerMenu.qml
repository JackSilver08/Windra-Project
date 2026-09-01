import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../design/Theme.js" as Theme

Rectangle {
    id: root
    property bool open: false
    property bool reduceMotion: false
    property bool previewMode: true
    signal actionRequested(string action)

    width: 245
    height: 245
    radius: Theme.radiusLarge
    color: Qt.rgba(0.96, 0.975, 0.965, 0.97)
    border.width: 1
    border.color: Qt.rgba(1,1,1,0.68)
    opacity: open ? 1 : 0
    scale: open ? 1 : (reduceMotion ? 1 : 0.97)
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: root.reduceMotion ? 70 : Theme.motionNormal } }
    Behavior on scale { NumberAnimation { duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 7
        Text { text: "Nguồn"; font.pixelSize: 19; font.bold: true; color: Theme.ink; Layout.bottomMargin: 4 }
        Button { text: "Ngủ"; Layout.fillWidth: true; onClicked: root.actionRequested("suspend") }
        Button { text: "Khởi động lại"; Layout.fillWidth: true; onClicked: root.actionRequested("reboot") }
        Button { text: "Tắt máy"; Layout.fillWidth: true; onClicked: root.actionRequested("poweroff") }
        Button { text: "Đăng xuất"; Layout.fillWidth: true; onClicked: root.actionRequested("logout") }
        Text { visible: root.previewMode; text: "Preview: không tắt máy thật"; color: Theme.textMuted; font.pixelSize: 11 }
    }
}
