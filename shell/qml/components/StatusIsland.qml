import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Compact status island. Each area keeps its own popup anchor while the visual
 * treatment stays deliberately quiet so wallpaper and applications remain the focus.
 */
Item {
    id: root

    property bool reduceMotion: false

    property alias wifiAnchor: wifiButton
    property alias volumeAnchor: volumeButton
    property alias batteryAnchor: batteryButton

    signal wifiClicked()
    signal volumeClicked()
    signal batteryClicked()

    opacity: 0
    transform: Translate { id: statusTranslate; y: root.reduceMotion ? 0 : -30 }

    function playIntro() { intro.start() }

    ParallelAnimation {
        id: intro
        NumberAnimation {
            target: root; property: "opacity"; to: 1
            duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: statusTranslate; property: "y"; to: 0
            duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.chromeGlass
        border.width: 1
        border.color: Theme.chromeBorder
    }

    Row {
        anchors.centerIn: parent
        spacing: 3

        WindraIconButton {
            id: wifiButton
            width: 38
            height: 38
            reduceMotion: root.reduceMotion
            active: popupController.active === "wifi"
            tooltip: networkService.tooltipText
            onClicked: root.wifiClicked()

            WifiIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                level: networkService.level
                strokeColor: Theme.chromeText
            }
        }

        Rectangle { width: 1; height: 18; color: "#24ffffff"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: volumeButton
            width: 38
            height: 38
            reduceMotion: root.reduceMotion
            active: popupController.active === "volume"
            tooltip: audioService.tooltipText
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.volumeClicked()
            onRightClicked: audioService.toggleMute()

            VolumeIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                level: audioService.level
                unavailable: !audioService.available
                strokeColor: audioService.muted ? Theme.danger : Theme.chromeText
            }
        }

        Rectangle { width: 1; height: 18; color: "#24ffffff"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: batteryButton
            width: batteryRow.width + 14
            height: 38
            reduceMotion: root.reduceMotion
            active: popupController.active === "battery"
            tooltip: batteryService.tooltipText
            onClicked: root.batteryClicked()

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 5

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 16
                    percent: batteryService.percent
                    level: batteryService.level
                    charging: batteryService.charging
                    unavailable: !batteryService.available
                    strokeColor: Theme.chromeText
                    fillColor: Theme.batteryChromeColor(batteryService.level)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryService.available
                    text: batteryService.percent + "%"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.batteryChromeColor(batteryService.level)
                }
            }
        }
    }
}
