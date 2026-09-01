pragma ComponentBehavior: Bound

import QtQuick
import "../controls"
import "../design/Theme.js" as Theme
import "../design/Format.js" as Format

/*!
 * Popup lịch của đồng hồ hệ thống.
 *
 * Không phải app Calendar: chỉ hiển thị ngày giờ thật, cho lật tháng và quay về
 * hôm nay. Đồng hồ chỉ chạy khi popup mở để không tốn nhịp vẽ vô ích.
 */
WindraPopup {
    id: root

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2

    property date now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    onOpenChanged: {
        if (open) {
            now = new Date()
            goToToday()
        }
    }

    function goToToday() {
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
    }

    function shiftMonth(delta) {
        var next = new Date(viewYear, viewMonth + delta, 1)
        viewYear = next.getFullYear()
        viewMonth = next.getMonth()
    }

    readonly property bool viewingToday: viewYear === now.getFullYear()
        && viewMonth === now.getMonth()

    Timer {
        interval: 1000
        running: root.open
        repeat: true
        onTriggered: root.now = new Date()
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 12

        // --- đồng hồ realtime
        Column {
            width: parent.width
            spacing: 1

            Text {
                text: Qt.formatTime(root.now, "HH:mm:ss")
                font.pixelSize: 30
                font.bold: true
                color: Theme.ink
            }
            Text {
                width: parent.width
                text: Format.longDate(root.now)
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.divider }

        // --- điều hướng tháng
        Item {
            width: parent.width
            height: 30

            WindraIconButton {
                id: previousMonth
                width: 28
                height: 28
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                backgroundRadius: 14
                reduceMotion: root.reduceMotion
                tooltip: "Tháng trước"
                onClicked: root.shiftMonth(-1)

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.pixelSize: 20
                    color: Theme.ink
                }
            }

            Text {
                anchors.centerIn: parent
                text: Format.monthTitle(root.viewYear, root.viewMonth)
                font.pixelSize: 14
                font.bold: true
                color: Theme.ink
            }

            WindraIconButton {
                width: 28
                height: 28
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                backgroundRadius: 14
                reduceMotion: root.reduceMotion
                tooltip: "Tháng sau"
                onClicked: root.shiftMonth(1)

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: 20
                    color: Theme.ink
                }
            }
        }

        // --- nhãn cột
        Row {
            width: parent.width
            Repeater {
                model: Format.weekdayHeaders
                delegate: Text {
                    required property string modelData
                    required property int index
                    width: column.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 11
                    font.bold: true
                    color: index === 6 ? Theme.danger : Theme.textMuted
                }
            }
        }

        // --- lưới ngày
        Grid {
            width: parent.width
            columns: 7

            Repeater {
                model: Format.monthGrid(root.viewYear, root.viewMonth)

                delegate: Item {
                    id: cell
                    required property var modelData

                    readonly property bool isToday: Format.isSameDay(modelData.date, root.now)

                    width: column.width / 7
                    height: 30

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: cell.isToday ? Theme.accent : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        font.pixelSize: 12
                        font.bold: cell.isToday
                        color: cell.isToday
                            ? "#ffffff"
                            : (cell.modelData.inMonth ? Theme.ink : Theme.textMuted)
                        opacity: cell.modelData.inMonth ? 1 : 0.4
                    }
                }
            }
        }

        WindraButton {
            text: "Hôm nay"
            enabled: !root.viewingToday
            reduceMotion: root.reduceMotion
            onClicked: root.goToToday()
        }
    }
}
