import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1000
    height: 680
    visible: true
    title: "Windra Settings"
    color: "#f7f9f6"

    property string section: "Hệ thống"
    property color ink: "#101214"
    property color muted: "#687176"
    property color accent: "#22a7df"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 245
            Layout.fillHeight: true
            color: "#edf1ee"
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 7
                Label { text: "Windra Settings"; font.pixelSize: 23; font.bold: true; color: root.ink; bottomPadding: 14 }
                Repeater {
                    model: ["Mạng", "Bluetooth", "Màn hình", "Âm thanh", "Pin", "Lưu trữ", "Ứng dụng", "Giao diện", "Cập nhật", "Hệ thống"]
                    delegate: Button {
                        required property string modelData
                        width: parent.width
                        height: 42
                        text: modelData
                        flat: root.section !== modelData
                        onClicked: root.section = modelData
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            Flickable {
                anchors.fill: parent
                contentHeight: content.implicitHeight + 80
                clip: true
                ColumnLayout {
                    id: content
                    width: parent.width - 76
                    x: 38; y: 34
                    spacing: 18
                    Label { text: root.section; font.pixelSize: 30; font.bold: true; color: root.ink }
                    Label { text: root.section === "Hệ thống" ? "Windra 0.2 Desktop Alpha" : "Thiết lập " + root.section.toLowerCase(); color: root.muted; font.pixelSize: 15 }

                    Rectangle {
                        visible: root.section === "Hệ thống"
                        Layout.fillWidth: true; Layout.preferredHeight: 210; radius: 20; color: "#f4f7f4"
                        Column { anchors.fill: parent; anchors.margins: 22; spacing: 13
                            Label { text: "System Health"; font.pixelSize: 20; font.bold: true }
                            Label { text: "✓ Bộ nhớ        Tốt\n✓ Lưu trữ       Tốt\n✓ Hệ thống      Đang chạy\n✓ Windra Shell  0.2"; font.pixelSize: 16; lineHeight: 1.35 }
                            Label { text: "Linux / Debian · Qt 6 / QML · Wayland-first"; color: root.muted }
                        }
                    }

                    Rectangle {
                        visible: root.section === "Giao diện"
                        Layout.fillWidth: true; Layout.preferredHeight: 240; radius: 20; color: "#f4f7f4"
                        ColumnLayout { anchors.fill: parent; anchors.margins: 22; spacing: 15
                            Label { text: "Chuyển động"; font.pixelSize: 20; font.bold: true }
                            Switch {
                                text: "Bật hiệu ứng chuyển động"
                                checked: windraSettings.motionEnabled
                                onToggled: windraSettings.motionEnabled = checked
                            }
                            Switch {
                                text: "Reduce Motion"
                                checked: windraSettings.reduceMotion
                                onToggled: windraSettings.reduceMotion = checked
                            }
                            Label { text: "Reduce Motion giảm slide/stagger và ưu tiên fade ngắn. Windra Shell áp dụng ngay, không cần đăng nhập lại."; wrapMode: Text.WordWrap; color: root.muted; Layout.fillWidth: true }
                        }
                    }

                    Rectangle {
                        visible: root.section === "Âm thanh"
                        Layout.fillWidth: true; Layout.preferredHeight: 190; radius: 20; color: "#f4f7f4"
                        ColumnLayout { anchors.fill: parent; anchors.margins: 22; spacing: 13
                            Label { text: "Âm lượng đầu ra"; font.pixelSize: 20; font.bold: true }
                            Slider { from: 0; to: 100; value: 62; Layout.fillWidth: true }
                            Label { text: "PipeWire integration sẽ được nối đầy đủ ở System Alpha."; color: root.muted }
                        }
                    }

                    Rectangle {
                        visible: ["Mạng","Bluetooth","Màn hình","Pin","Lưu trữ","Ứng dụng","Cập nhật"].indexOf(root.section) >= 0
                        Layout.fillWidth: true; Layout.preferredHeight: 185; radius: 20; color: "#f4f7f4"
                        Column { anchors.fill: parent; anchors.margins: 22; spacing: 12
                            Label { text: "Giao diện Alpha"; font.pixelSize: 20; font.bold: true }
                            Label { width: parent.width; wrapMode: Text.WordWrap; text: "Trang này đã có trong Windra 0.2 để chốt UX. Backend Linux tương ứng sẽ lần lượt nối NetworkManager, BlueZ, UDisks2, PipeWire và fwupd trong các mốc tiếp theo."; color: root.muted }
                        }
                    }
                }
            }
        }
    }
}
