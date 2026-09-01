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

    color: field.activeFocus ? "#f8ffffff" : Theme.searchGlass
    radius: 12
    border.width: 1
    border.color: field.activeFocus ? "#704da3ff" : Theme.searchBorder
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.985

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

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }

    Image {
        source: "../assets/icons/search.svg"
        width: 18
        height: 18
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        opacity: 0.72
    }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 38
        anchors.rightMargin: 12
        placeholderText: "Tìm kiếm..."
        placeholderTextColor: "#74808a"
        font.pixelSize: 14
        color: "#172126"
        selectByMouse: true
        background: Item {}
        onAccepted: root.submitted(text.trim())
        onActiveFocusChanged: if (activeFocus) root.focused()
    }
}
