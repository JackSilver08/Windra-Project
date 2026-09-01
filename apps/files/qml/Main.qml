import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1020
    height: 680
    visible: true
    title: "Windra Files"
    color: "#f7f9f6"

    property color ink: "#0b0d0e"
    property color muted: "#667074"
    property color accent: "#22a7df"

    header: Rectangle {
        height: 62
        color: "#ffffff"
        border.color: "#e5e9e7"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 10
            ToolButton { text: "‹"; font.pixelSize: 28; onClicked: directoryModel.goUp() }
            Label { text: directoryModel.currentPath; color: root.ink; elide: Text.ElideMiddle; Layout.fillWidth: true; font.pixelSize: 15 }
            Button { text: "Làm mới"; onClicked: directoryModel.refresh() }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 235
            Layout.fillHeight: true
            color: "#eef2ef"
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                Label { text: "Windra Files"; font.pixelSize: 23; font.bold: true; color: root.ink; bottomPadding: 8 }
                Button { width: parent.width; text: "Home"; flat: true; onClicked: directoryModel.goHome() }
                Button { width: parent.width; text: "Documents"; flat: true; onClicked: directoryModel.goTo(directoryModel.homePath + "/Documents") }
                Button { width: parent.width; text: "Downloads"; flat: true; onClicked: directoryModel.goTo(directoryModel.homePath + "/Downloads") }
                Button { width: parent.width; text: "Pictures"; flat: true; onClicked: directoryModel.goTo(directoryModel.homePath + "/Pictures") }
                Rectangle { width: parent.width; height: 1; color: "#dce2df" }
                Label { text: "This Device"; font.bold: true; color: root.muted; topPadding: 6 }
                Button { width: parent.width; text: "System  /"; flat: true; onClicked: directoryModel.goTo("/") }
                Button { width: parent.width; text: "+  Thêm ổ đĩa"; onClicked: addDrive.open() }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Nội dung"; font.pixelSize: 21; font.bold: true; color: root.ink; Layout.fillWidth: true }
                    Label { text: directoryList.count + " mục"; color: root.muted }
                }

                ListView {
                    id: directoryList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: directoryModel
                    delegate: Rectangle {
                        required property string name
                        required property bool isDir
                        required property string sizeText
                        required property int index
                        width: directoryList.width
                        height: 52
                        radius: 10
                        color: rowMouse.containsMouse ? "#eef7fb" : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            Text { text: isDir ? "▰" : "▱"; font.pixelSize: 22; color: isDir ? "#e8bf48" : "#7c878c" }
                            Label { text: name; color: root.ink; Layout.fillWidth: true; elide: Text.ElideRight }
                            Label { text: sizeText; color: root.muted; font.pixelSize: 12 }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onDoubleClicked: directoryModel.openIndex(index)
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: addDrive
        title: "Thêm ổ đĩa"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
        contentItem: Label {
            width: 390
            wrapMode: Text.WordWrap
            text: "Windra 0.2 đã có giao diện Human-first cho tính năng này. Việc resize/partition thật sẽ chỉ được bật sau khi có bước xem trước, xác thực Polkit và cơ chế bảo vệ dữ liệu."
            padding: 18
        }
    }
}
