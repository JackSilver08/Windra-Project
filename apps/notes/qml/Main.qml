import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 850
    height: 620
    visible: true
    title: "Windra Notes"
    color: "#f7f7f2"
    property url currentFile

    header: ToolBar {
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
            Label { text: "Windra Notes"; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true }
            Button { text: "Mới"; onClicked: { editor.clear(); root.currentFile = "" } }
            Button { text: "Mở"; onClicked: openDialog.open() }
            Button { text: "Lưu"; onClicked: root.currentFile.toString().length ? notesBackend.save(root.currentFile, editor.text) : saveDialog.open() }
        }
    }

    TextArea {
        id: editor
        anchors.fill: parent
        anchors.margins: 22
        padding: 22
        wrapMode: TextEdit.Wrap
        font.pixelSize: 17
        color: "#17191a"
        placeholderText: "Viết điều gì đó..."
        background: Rectangle { radius: 20; color: "#ffffff"; border.color: "#e1e4df" }
    }

    FileDialog {
        id: openDialog
        title: "Mở ghi chú"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Văn bản (*.txt *.md)", "Tất cả tệp (*)"]
        onAccepted: { root.currentFile = selectedFile; editor.text = notesBackend.load(selectedFile) }
    }
    FileDialog {
        id: saveDialog
        title: "Lưu ghi chú"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Văn bản (*.txt)"]
        onAccepted: { root.currentFile = selectedFile; notesBackend.save(selectedFile, editor.text) }
    }
}
