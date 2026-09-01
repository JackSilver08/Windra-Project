import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Status island góc trên phải.
 *
 * Ba control ĐỘC LẬP: Wi-Fi, Volume, Battery. Mỗi cái có hover, tooltip và popup
 * riêng — không còn một MouseArea phủ toàn bộ mở chung một Quick Settings.
 * Main.qml neo popup vào các anchor được expose ở đây.
 */
Item {
    id: root

    property bool reduceMotion: false

    //! Anchor để Main.qml định vị popup ngay dưới đúng icon tương ứng.
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

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "rgba(205, 217, 225, 0.82)"
            ctx.beginPath()
            ctx.moveTo(58, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.closePath()
            ctx.fill()
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        WindraIconButton {
            id: wifiButton
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            active: popupController.active === "wifi"
            tooltip: networkService.tooltipText
            onClicked: root.wifiClicked()

            WifiIcon {
                anchors.centerIn: parent
                width: 27
                height: 27
                level: networkService.level
            }
        }

        WindraIconButton {
            id: volumeButton
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            active: popupController.active === "volume"
            tooltip: audioService.tooltipText
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.volumeClicked()
            // Chuột phải = tắt/bật tiếng nhanh, không cần mở popup.
            onRightClicked: audioService.toggleMute()

            VolumeIcon {
                anchors.centerIn: parent
                width: 27
                height: 27
                level: audioService.level
                unavailable: !audioService.available
                strokeColor: audioService.muted ? Theme.danger : Theme.ink
            }
        }

        WindraIconButton {
            id: batteryButton
            width: batteryRow.width + 14
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            active: popupController.active === "battery"
            tooltip: batteryService.tooltipText
            onClicked: root.batteryClicked()

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 6

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 20
                    percent: batteryService.percent
                    level: batteryService.level
                    charging: batteryService.charging
                    unavailable: !batteryService.available
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryService.available
                    text: batteryService.percent + "%"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.batteryColor(batteryService.level)
                }
            }
        }
    }
}
