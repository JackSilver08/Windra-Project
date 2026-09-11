import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo

Item {
    id: root

    property bool reduceMotion: false
    property date now: new Date()

    property alias wifiAnchor: wifiButton
    property alias volumeAnchor: volumeButton
    property alias batteryAnchor: batteryButton
    property alias clockAnchor: clockArea

    signal wifiClicked()
    signal volumeClicked()
    signal batteryClicked()
    signal clockClicked()

    opacity: 0
    transform: Translate { id: statusTranslate; y: root.reduceMotion ? 0 : -28 }

    function playIntro() { intro.start() }

    ParallelAnimation {
        id: intro
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
        NumberAnimation { target: statusTranslate; property: "y"; to: 0; duration: root.reduceMotion ? 80 : Geo.motionNormal; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    WindraCutSurface {
        anchors.fill: parent
        cut: 24
        cutTopLeft: true
        cutTopRight: false
        cutBottomLeft: true
        cutBottomRight: false
        fillColor: "#dce6eee8"
        borderColor: "#a9b7c3"
        borderWidth: 1
        shadowColor: "#40000000"
        shadowOffsetX: -5
        shadowOffsetY: 5
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 42
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        WindraIconButton {
            id: wifiButton
            width: 42
            height: 42
            reduceMotion: root.reduceMotion
            active: popupController.active === "wifi"
            showBackground: false
            tooltip: networkService.tooltipText
            onClicked: root.wifiClicked()

            WifiIcon {
                anchors.centerIn: parent
                width: 25
                height: 25
                level: networkService.level
                strokeColor: Geo.text
            }
        }

        Rectangle { width: 1; height: 26; color: "#597080"; opacity: 0.55; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: volumeButton
            width: 42
            height: 42
            reduceMotion: root.reduceMotion
            active: popupController.active === "volume"
            showBackground: false
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
                strokeColor: audioService.muted ? Theme.danger : Geo.text
            }
        }

        Rectangle { width: 1; height: 26; color: "#597080"; opacity: 0.55; anchors.verticalCenter: parent.verticalCenter }

        WindraIconButton {
            id: batteryButton
            width: 74
            height: 42
            reduceMotion: root.reduceMotion
            active: popupController.active === "battery"
            showBackground: false
            tooltip: batteryService.tooltipText
            onClicked: root.batteryClicked()

            Row {
                anchors.centerIn: parent
                spacing: 7

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 18
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
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Geo.text
                }
            }
        }

        Item {
            id: clockArea
            width: 110
            height: 48

            Column {
                anchors.centerIn: parent
                spacing: -2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: Geo.text
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.now, "d/M/yyyy")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Geo.textMuted
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clockClicked()
            }
        }
    }
}
