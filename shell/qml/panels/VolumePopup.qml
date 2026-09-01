import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Popup âm lượng riêng.
 *
 * Slider bind thẳng vào AudioService.volume; `moved` chỉ phát khi người dùng kéo
 * nên volume đổi từ ngoài (phím media, mixer khác) vẫn đẩy ngược vào UI được.
 */
WindraPopup {
    id: root

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 13

        WindraSectionTitle { text: "ÂM LƯỢNG" }

        Row {
            width: parent.width
            spacing: 10

            WindraIconButton {
                id: muteButton
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                backgroundRadius: 16
                reduceMotion: root.reduceMotion
                tooltip: audioService.muted ? "Bật tiếng" : "Tắt tiếng"
                onClicked: audioService.toggleMute()

                VolumeIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    level: audioService.level
                    unavailable: !audioService.available
                    strokeColor: audioService.muted ? Theme.danger : Theme.ink
                }
            }

            WindraSlider {
                id: slider
                width: parent.width - muteButton.width - percentLabel.width - 20
                anchors.verticalCenter: parent.verticalCenter
                enabled: audioService.available
                reduceMotion: root.reduceMotion
                from: 0
                to: 100
                value: audioService.volume
                fillColor: audioService.muted ? Theme.textMuted : Theme.accent
                onMoved: function(next) {
                    if (audioService.muted)
                        audioService.setMuted(false)
                    audioService.setVolume(next)
                }
            }

            Text {
                id: percentLabel
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                horizontalAlignment: Text.AlignRight
                text: audioService.available ? audioService.volume + "%" : "—"
                font.pixelSize: 13
                font.bold: true
                color: Theme.ink
            }
        }

        Column {
            width: parent.width
            spacing: 2

            WindraSectionTitle { text: "OUTPUT" }
            Text {
                width: parent.width
                text: audioService.deviceName
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Text {
            visible: !audioService.available
            width: parent.width
            text: "Không tìm thấy dịch vụ âm thanh. Cần PipeWire/WirePlumber (wpctl) hoặc pactl."
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.pixelSize: 11
        }

        WindraButton {
            text: audioService.muted ? "Bỏ tắt tiếng" : "Tắt tiếng"
            enabled: audioService.available
            selected: audioService.muted
            reduceMotion: root.reduceMotion
            onClicked: audioService.toggleMute()
        }
    }
}
