import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme

Rectangle {
    id: root
    property alias text: field.text
    property int introDelay: 0
    property bool reduceMotion: false
    signal submitted(string query)
    signal focused()

    color: "#fbfcfb"
    radius: height / 2
    border.width: field.activeFocus ? 2 : 1
    border.color: field.activeFocus ? Theme.accent : "#d2d8d9"
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.975

    function playIntro() { intro.start() }
    function forceFocus() { field.forceActiveFocus() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : root.introDelay }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "scale"; to: 1; duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic }
        }
    }

    Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 46
        placeholderText: "Tìm kiếm..."
        font.pixelSize: 16
        color: Theme.ink
        selectByMouse: true
        background: Item {}
        onAccepted: root.submitted(text.trim())
        onActiveFocusChanged: if (activeFocus) root.focused()
    }

    Image {
        source: "../assets/icons/search.svg"
        width: 25
        height: 25
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
    }
}
