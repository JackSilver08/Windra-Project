import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Format.js" as Format

/*!
 * Bottom-right utility cluster. Running apps and clock are visually separate
 * cards so the two actions are obvious without adding decoration.
 */
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
            NumberAnimation {
                target: root; property: "opacity"; to: 1
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
        id: appsCard
        width: 50
        height: parent.height
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        radius: 16
        color: Theme.chromeGlass
        border.width: 1
        border.color: Theme.chromeBorder

        WindraIconButton {
            id: appsButton
            anchors.fill: parent
            anchors.margins: 4
            backgroundRadius: 12
            reduceMotion: root.reduceMotion
            active: popupController.active === "apps"
            tooltip: appModel.runningCount > 0
                ? "Ứng dụng đang chạy (" + appModel.runningCount + ")"
                : "Ứng dụng đang chạy"
            onClicked: root.appsClicked()

            Image {
                anchors.centerIn: parent
                source: "../assets/icons/chevron.svg"
                width: 20
                height: 20
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: 0.9
            }

            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: Theme.accent
                visible: appModel.runningCount > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
            }
        }
    }

    Rectangle {
        id: clockCard
        anchors.left: appsCard.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 16
        color: Theme.chromeGlass
        border.width: 1
        border.color: Theme.chromeBorder

        Item {
            id: clockArea
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 12
                color: popupController.active === "calendar"
                    ? "#1effffff"
                    : (clockMouse.containsMouse ? "#12ffffff" : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.hoverDuration } }
            }

            Column {
                anchors.centerIn: parent
                spacing: -1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: Theme.chromeText
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.now, "d/M/yyyy")
                    font.pixelSize: 11
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
}
