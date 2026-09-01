import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Format.js" as Format

/*!
 * Pill góc dưới phải.
 *
 * Hai vùng click ĐỘC LẬP:
 *   - mũi tên ^  -> popup "Ứng dụng đang chạy / ứng dụng nền";
 *   - vùng giờ   -> popup Calendar.
 *
 * Giờ/ngày lấy từ đồng hồ hệ thống và theo locale khi hệ thống dùng vi_VN.
 */
Rectangle {
    id: root

    property bool reduceMotion: false
    property date now: new Date()

    property alias appsAnchor: appsButton
    property alias clockAnchor: clockArea

    signal appsClicked()
    signal clockClicked()

    color: "#e7ebe3"
    opacity: 0
    radius: height / 2
    transform: Translate { id: clockTranslate; y: root.reduceMotion ? 0 : 34 }

    function playIntro() { intro.start() }

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: root.reduceMotion ? 0 : 380 }
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "opacity"; to: 0.90
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

    WindraIconButton {
        id: appsButton
        width: 44
        height: 44
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        backgroundRadius: 22
        reduceMotion: root.reduceMotion
        active: popupController.active === "apps"
        tooltip: appModel.runningCount > 0
            ? "Ứng dụng đang chạy (" + appModel.runningCount + ")"
            : "Ứng dụng đang chạy"
        onClicked: root.appsClicked()

        Image {
            anchors.centerIn: parent
            source: "../assets/icons/chevron.svg"
            width: 26
            height: 26
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Chấm nhỏ báo có app đang chạy — không cần mở popup mới biết.
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
            visible: appModel.runningCount > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
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
            radius: height / 2
            color: popupController.active === "calendar"
                ? "#33ffffff"
                : (clockMouse.containsMouse ? "#26ffffff" : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 21
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                anchors.right: parent.right
                text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                font.pixelSize: 18
                font.bold: true
                color: Theme.ink
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(root.now, "d/M/yyyy")
                font.pixelSize: 16
                font.bold: true
                color: Theme.ink
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
