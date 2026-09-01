// Delegate dùng id của component ngoài (root, runningRow) nên bind theo
// creation context thay vì context động.
pragma ComponentBehavior: Bound

import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Popup "Ứng dụng đang chạy / ứng dụng nền" của mũi tên ^.
 *
 * Nguồn dữ liệu là ApplicationModel — chỉ app cấp người dùng do Windra launch,
 * KHÔNG phải danh sách process Linux. Người dùng không bao giờ thấy systemd,
 * dbus-daemon hay pipewire ở đây.
 */
WindraPopup {
    id: root

    implicitWidth: 292
    implicitHeight: Math.min(420, column.implicitHeight + padding * 2)

    function iconFor(name) {
        return Qt.resolvedUrl("../assets/icons/" + name + ".svg")
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 10

        // --- foreground / native apps
        WindraSectionTitle { text: "ỨNG DỤNG ĐANG CHẠY" }

        Text {
            width: parent.width
            visible: appModel.running.length === 0
            text: "Không có ứng dụng nào đang chạy."
            color: Theme.textMuted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: appModel.running

                delegate: WindraListItem {
                    id: runningRow
                    required property var modelData

                    width: parent.width
                    title: modelData.name
                    subtitle: modelData.state === "closing"
                        ? "Đang đóng..."
                        : (modelData.pid > 0 ? "PID " + modelData.pid : "Đang chạy")
                    reduceMotion: root.reduceMotion
                    leadingWidth: 24
                    trailingWidth: 22

                    leading: Image {
                        source: root.iconFor(runningRow.modelData.iconName)
                        width: 22
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    trailing: WindraIconButton {
                        width: 22
                        height: 22
                        backgroundRadius: 11
                        reduceMotion: root.reduceMotion
                        tooltip: "Đóng ứng dụng"
                        onClicked: appModel.requestClose(runningRow.modelData.appId)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    onClicked: appModel.activate(modelData.appId)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.divider
        }

        // --- background / web apps
        WindraSectionTitle { text: "CHẠY NỀN" }

        Text {
            width: parent.width
            visible: appModel.background.length === 0
            text: "Không có ứng dụng nền."
            color: Theme.textMuted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: appModel.background

                delegate: WindraListItem {
                    id: backgroundRow
                    required property var modelData

                    width: parent.width
                    title: modelData.name
                    subtitle: modelData.tracked
                        ? (modelData.pid > 0 ? "PID " + modelData.pid : "Chạy nền")
                        : "Windra không theo dõi được cửa sổ này"
                    reduceMotion: root.reduceMotion
                    leadingWidth: 24
                    trailingWidth: 22

                    leading: Image {
                        source: root.iconFor(backgroundRow.modelData.iconName)
                        width: 22
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    trailing: WindraIconButton {
                        width: 22
                        height: 22
                        backgroundRadius: 11
                        reduceMotion: root.reduceMotion
                        tooltip: backgroundRow.modelData.tracked
                            ? "Đóng ứng dụng"
                            : "Bỏ khỏi danh sách"
                        onClicked: appModel.requestClose(backgroundRow.modelData.appId)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    onClicked: appModel.activate(modelData.appId)
                }
            }
        }
    }
}
