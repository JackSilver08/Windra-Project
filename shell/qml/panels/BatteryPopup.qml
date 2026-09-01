pragma ComponentBehavior: Bound

import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Popup pin — mở riêng khi click khu vực Battery, không kéo theo Volume/Wi-Fi.
 * Mọi số liệu đến từ BatteryService (UPower hoặc /sys/class/power_supply).
 */
WindraPopup {
    id: root

    implicitWidth: 286
    implicitHeight: column.implicitHeight + padding * 2

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 12

        WindraSectionTitle { text: "PIN" }

        Row {
            spacing: 12

            BatteryIcon {
                width: 42
                height: 23
                anchors.verticalCenter: parent.verticalCenter
                percent: batteryService.percent
                level: batteryService.level
                charging: batteryService.charging
                unavailable: !batteryService.available
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: batteryService.available ? batteryService.percent + "%" : "—"
                font.pixelSize: 30
                font.bold: true
                color: Theme.ink
            }
        }

        Text {
            visible: !batteryService.available
            width: parent.width
            text: "Máy này không có pin hoặc không đọc được thông tin pin."
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.pixelSize: 12
        }

        Column {
            visible: batteryService.available
            width: parent.width
            spacing: 5

            Text {
                width: parent.width
                text: batteryService.remainingText
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: "Trạng thái: " + batteryService.stateText
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: "Chế độ nguồn: " + powerProfiles.activeProfileText
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.divider
        }

        Row {
            spacing: 6

            Repeater {
                model: [
                    { key: "power-saver", label: "Tiết kiệm" },
                    { key: "balanced", label: "Cân bằng" },
                    { key: "performance", label: "Hiệu năng" }
                ]

                delegate: WindraButton {
                    required property var modelData
                    text: modelData.label
                    horizontalPadding: 10
                    implicitHeight: 32
                    selected: powerProfiles.activeProfile === modelData.key
                    enabled: powerProfiles.available && powerProfiles.hasProfile(modelData.key)
                    reduceMotion: root.reduceMotion
                    onClicked: powerProfiles.setProfile(modelData.key)
                }
            }
        }

        Text {
            visible: !powerProfiles.available
            width: parent.width
            text: "Chế độ nguồn cần power-profiles-daemon."
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }
}
