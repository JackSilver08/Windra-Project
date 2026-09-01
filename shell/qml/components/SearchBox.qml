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

    color: field.activeFocus ? "#dbeff5f6" : Theme.searchGlass
    radius: height / 2
    border.width: field.activeFocus ? 2 : 1
    border.color: field.activeFocus ? Theme.chromeGlow : Theme.searchBorder
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

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }

    // Viền sáng mảnh phía dưới tạo cảm giác HUD/game UI nhưng không cần blur.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        height: 1
        radius: 1
        color: Theme.chromeGlow
        opacity: field.activeFocus ? 0.9 : 0.18
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
    }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 43
        placeholderText: "Tìm kiếm..."
        placeholderTextColor: "#64727a"
        font.pixelSize: 15
        color: "#172126"
        selectByMouse: true
        background: Item {}
        onAccepted: root.submitted(text.trim())
        onActiveFocusChanged: if (activeFocus) root.focused()
    }

    Image {
        source: "../assets/icons/search.svg"
        width: 22
        height: 22
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        opacity: 0.88
    }
}
