import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Format.js" as Format
import "../design/Geometric.js" as Geo

Item {
    id: root

    property bool reduceMotion: false
    property date now: new Date()

    property alias appsAnchor: appsButton
    property alias clockAnchor: clockArea

    signal appsClicked()
    signal clockClicked()

    opacity: 0
    transform: Translate { id: clockTranslate; y: root.reduceMotion ? 0 : 24 }

    function playIntro() { intro.start() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : 240 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
            NumberAnimation { target: clockTranslate; property: "y"; to: 0; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
        }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    WindraCutSurface {
        id: clockSurface
        anchors.fill: parent
        cut: 14
        fillColor: "#e6edf3df"
        shadowColor: "#50000000"
        shadowOffsetX: 5
        shadowOffsetY: 5
        borderColor: "#9aaab8"
        borderWidth: 1
    }

    WindraIconButton {
        id: appsButton
        width: 44
        height: 44
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 6
        reduceMotion: root.reduceMotion
        active: popupController.active === "apps"
        tooltip: appModel.runningCount > 0 ? "Ứng dụng đang chạy (" + appModel.runningCount + ")" : "Ứng dụng đang chạy"
        onClicked: root.appsClicked()

        Image {
            anchors.centerIn: parent
            source: "../assets/icons/chevron.svg"
            width: 20
            height: 20
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Rectangle {
            width: 5; height: 5; radius: 2.5
            color: Geo.sapphire
            visible: appModel.runningCount > 0
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5
        }
    }

    Item {
        id: clockArea
        anchors.left: appsButton.right
        anchors.leftMargin: 4
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: clockMouse.containsMouse || popupController.active === "calendar" ? "#1f80ff26" : "transparent"
            clip: true
            transform: Rotation { angle: -2; origin.x: width / 2; origin.y: height / 2 }
            Behavior on color { ColorAnimation { duration: Geo.motionFast } }
        }

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: Geo.text
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.now, "d/M/yyyy")
                font.pixelSize: 11
                color: Geo.textMuted
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clockClicked()
        }

        WindraTooltip {
            text: Format.longDate(root.now)
            show: clockMouse.containsMouse && popupController.active !== "calendar"
            reduceMotion: root.reduceMotion
            side: "above"
        }
    }
}
