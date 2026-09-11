import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo

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
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
        NumberAnimation { target: statusTranslate; property: "y"; to: 0; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
    }

    // Diagonal status strip inspired by the login mockup.
    WindraCutSurface {
        anchors.fill: parent
        cut: 13
        fillColor: "#e6edf3df"
        shadowColor: "#50000000"
        shadowOffsetX: -5
        shadowOffsetY: 5
        borderColor: "#9aaab8"
        borderWidth: 1
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        WindraIconButton {
            id: wifiButton
            width: 40
            height: 40
            reduceMotion: root.reduceMotion
            active: popupController.active === "wifi"
            tooltip: networkService.tooltipText
            onClicked: root.wifiClicked()

            WifiIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                level: networkService.level
                strokeColor: Geo.text
            }
        }

        Rectangle { width: 1; height: 19; color: "#3a566474"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: volumeButton
            width: 40
            height: 40
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
                strokeColor: audioService.muted ? Theme.danger : Geo.text
            }
        }

        Rectangle { width: 1; height: 19; color: "#3a566474"; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: batteryButton
            width: batteryRow.width + 16
            height: 40
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
                    width: 27
                    height: 16
                    percent: batteryService.percent
                    level: batteryService.level
                    charging: batteryService.charging
                    unavailable: !batteryService.available
                    strokeColor: Geo.text
                    fillColor: Theme.batteryChromeColor(batteryService.level)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryService.available
                    text: batteryService.percent + "%"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.batteryChromeColor(batteryService.level)
                }
            }
        }
    }
}
