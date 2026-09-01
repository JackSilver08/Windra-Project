pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme

Rectangle {
    id: root
    property bool open: false
    property string query: ""
    property bool reduceMotion: false
    signal closeRequested()
    signal appRequested(string appId)
    signal webSearchRequested(string query)

    width: 540
    height: 390
    radius: Theme.radiusLarge
    color: Qt.rgba(0.96, 0.975, 0.965, 0.94)
    border.width: 1
    border.color: Qt.rgba(1,1,1,0.65)
    opacity: open ? 1 : 0
    scale: open ? 1 : (reduceMotion ? 1 : 0.975)
    visible: opacity > 0.01
    enabled: open

    Behavior on opacity { NumberAnimation { duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: root.reduceMotion ? 70 : Theme.motionNormal; easing.type: Easing.OutCubic } }

    // Danh mục app lấy từ ApplicationModel để launcher, dock và popup
    // "ứng dụng đang chạy" luôn nói về cùng một tập ứng dụng.
    readonly property var apps: appModel.catalog()

    function iconFor(name) {
        return Qt.resolvedUrl("../assets/icons/" + name + ".svg")
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 19

        TextField {
            id: searchField
            width: parent.width
            height: 48
            text: root.query
            placeholderText: "Tìm ứng dụng hoặc tìm trên web..."
            font.pixelSize: 16
            leftPadding: 17
            rightPadding: 17
            background: Rectangle {
                radius: 24
                color: "white"
                border.width: searchField.activeFocus ? 2 : 1
                border.color: searchField.activeFocus ? Theme.accent : "#d7dddc"
            }
            onTextChanged: root.query = text
            onAccepted: {
                const q = text.trim().toLowerCase()
                if (!q) return
                for (let i = 0; i < root.apps.length; ++i) {
                    if (root.apps[i].name.toLowerCase().includes(q) || root.apps[i].appId === q) {
                        root.appRequested(root.apps[i].appId)
                        return
                    }
                }
                root.webSearchRequested(text.trim())
            }
        }

        Text {
            text: root.query.length ? "Kết quả" : "Ứng dụng"
            color: Theme.textMuted
            font.pixelSize: 13
            font.bold: true
        }

        Grid {
            width: parent.width
            columns: 4
            spacing: 13

            Repeater {
                model: root.apps
                delegate: Rectangle {
                    required property var modelData
                    width: 112
                    height: 108
                    radius: 17
                    color: appMouse.containsMouse ? "#ffffff" : "transparent"
                    visible: root.query.length === 0
                        || modelData.name.toLowerCase().includes(root.query.toLowerCase())
                        || modelData.appId.includes(root.query.toLowerCase())

                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Image {
                            source: root.iconFor(modelData.iconName)
                            width: 48
                            height: 48
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            text: modelData.name.replace("Windra ", "")
                            color: Theme.ink
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.appRequested(modelData.appId)
                    }
                }
            }
        }

        Item { width: 1; height: 1 }

        Text {
            visible: root.query.length > 0
            text: "Nhấn Enter để tìm \"" + root.query + "\" trên web"
            color: Theme.textMuted
            font.pixelSize: 13
        }
    }

    function focusSearch(value) {
        query = value || ""
        searchField.text = query
        searchField.forceActiveFocus()
        searchField.selectAll()
    }
}
