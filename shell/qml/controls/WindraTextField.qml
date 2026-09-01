import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme

//! Ô nhập của popup (tìm mạng, mật khẩu Wi-Fi).
Rectangle {
    id: root

    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property alias inputField: field
    property bool reduceMotion: false

    signal accepted()

    implicitHeight: 36
    radius: Theme.radiusSmall
    color: Theme.surfaceStrong
    border.width: field.activeFocus ? 2 : 1
    border.color: field.activeFocus ? Theme.accent : Theme.divider

    Behavior on border.color { ColorAnimation { duration: Theme.hoverDuration } }

    function forceFocus() { field.forceActiveFocus() }
    function clear() { field.clear() }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        font.pixelSize: 13
        color: Theme.ink
        placeholderTextColor: Theme.textMuted
        selectByMouse: true
        background: Item {}
        onAccepted: root.accepted()
    }
}
