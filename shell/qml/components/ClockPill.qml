import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Format.js" as Format

/*!
 * Pill góc dưới phải.
 * Hai vùng click độc lập: ^ mở app đang chạy, vùng giờ mở lịch.
 * Visual mới dùng glass tối + cyan rim giống mockup homepage Windra.
 */
Rectangle {
    id: root

    property bool reduceMotion: false
    property date now: new Date()

    property alias appsAnchor: appsButton
    property alias clockAnchor: clockArea

    signal appsClicked()
    signal clockClicked()

    color: Theme.chromeGlassStrong
    border.width: 1
    border.color: Theme.chromeBorder
    opacity: 0
    radius: 18
    transform: Translate { id: clockTranslate; y: root.reduceMotion ? 0 : 34 }

    function playIntro() { intro.start() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : 380 }
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "opacity"; to: 0.96
                duration: root.reduceMotion ? 80 : Theme.motionNormal; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: clockTranslate; property: "y"; to: 0
                duration: root.reduceMotion ? 80 : Theme.motionNormal; easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 2
        radius: 1
        color: Theme.chromeGlow
        opacity: 0.82
    }

    WindraIconButton {
        id: appsButton
        width: 44
        height: 44
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        backgroundRadius: 22
        reduceMotion: root.reduceMotion
        active: popupController.active === "apps"
        tooltip: appModel.runningCount > 0
            ? "Ứng dụng đang chạy (" + appModel.runningCount + ")"
            : "Ứng dụng đang chạy"
        onClicked: root.appsClicked()

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#25ffffff"
            border.width: 1
            border.color: "#3cffffff"
        }

        Image {
            anchors.centerIn: parent
            source: "../assets/icons/chevron.svg"
            width: 23
            height: 23
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.92
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: Theme.chromeGlow
            visible: appModel.runningCount > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
        }
    }

    Item {
        id: clockArea
        anchors.left: appsButton.right
        anchors.leftMargin: 3
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 14
            color: popupController.active === "calendar"
                ? "#24ffffff"
                : (clockMouse.containsMouse ? "#18ffffff" : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                anchors.right: parent.right
                text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                font.pixelSize: 23
                font.bold: true
                color: Theme.chromeText
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(root.now, "d/M/yyyy")
                font.pixelSize: 13
                font.bold: false
                color: Theme.chromeMuted
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
