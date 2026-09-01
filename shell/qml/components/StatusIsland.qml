import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Status island góc trên phải.
 * Ba control độc lập: Wi-Fi, Volume, Battery. Visual mới bám mockup Windra:
 * glass compact, viền xanh lạnh và wind motif ở cạnh trái.
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
    transform: Translate { id: statusTranslate; y: root.reduceMotion ? 0 : -54 }

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
        radius: 13
        color: Theme.chromeGlassStrong
        border.width: 1
        border.color: Theme.chromeBorder
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        height: 2
        radius: 1
        color: Theme.chromeGlow
        opacity: 0.58
    }

    Image {
        source: "../assets/icons/windra-waves.svg"
        width: 38
        height: 26
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        opacity: 0.72
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        WindraIconButton {
            id: wifiButton
            width: 38
            height: 38
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            active: popupController.active === "wifi"
            tooltip: networkService.tooltipText
            onClicked: root.wifiClicked()

            WifiIcon {
                anchors.centerIn: parent
                width: 25
                height: 25
                level: networkService.level
                strokeColor: Theme.chromeText
            }
        }

        Rectangle { width: 1; height: 24; color: "#33ffffff"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: volumeButton
            width: 38
            height: 38
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            active: popupController.active === "volume"
            tooltip: audioService.tooltipText
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.volumeClicked()
            onRightClicked: audioService.toggleMute()

            VolumeIcon {
                anchors.centerIn: parent
                width: 25
                height: 25
                level: audioService.level
                unavailable: !audioService.available
                strokeColor: audioService.muted ? Theme.danger : Theme.chromeText
            }
        }

        Rectangle { width: 1; height: 24; color: "#33ffffff"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: batteryButton
            width: batteryRow.width + 12
            height: 38
            anchors.verticalCenter: parent.verticalCenter
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
                    width: 32
                    height: 18
                    percent: batteryService.percent
                    level: batteryService.level
                    charging: batteryService.charging
                    unavailable: !batteryService.available
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryService.available
                    text: batteryService.percent + "%"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.batteryColor(batteryService.level)
                }
            }
        }
    }
}
