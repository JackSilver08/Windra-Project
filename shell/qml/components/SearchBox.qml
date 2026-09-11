import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo
import "../controls"

Item {
    id: root
    property alias text: field.text
    property int introDelay: 0
    property bool reduceMotion: false
    signal submitted(string query)
    signal focused()

    width: 210
    height: 40
    opacity: 0
    scale: reduceMotion ? 1.0 : 0.985

    function playIntro() { intro.start() }
    function forceFocus() { field.forceActiveFocus() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : root.introDelay }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 70 : Geo.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "scale"; to: 1; duration: root.reduceMotion ? 70 : Geo.motionNormal; easing.type: Easing.OutCubic }
        }
    }

    WindraCutSurface {
        anchors.fill: parent
        cut: 10
        fillColor: field.activeFocus ? "#f8fbff" : "#e9eef3"
        borderColor: field.activeFocus ? Geo.sapphire : "#aebbc7"
        borderWidth: field.activeFocus ? 2 : 1
        shadowColor: "#28000000"
        shadowOffsetX: 3
        shadowOffsetY: 3
    }

    Image {
        source: "../assets/icons/search.svg"
        width: 18
        height: 18
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        opacity: 0.72
    }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        placeholderText: "Tìm kiếm..."
        placeholderTextColor: "#53616d"
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Geo.text
        selectByMouse: true
        background: Item {}
        onAccepted: root.submitted(text.trim())
        onActiveFocusChanged: if (activeFocus) root.focused()
    }
}
