pragma ComponentBehavior: Bound

import QtQuick
import "../design/Theme.js" as Theme

//! 4 vạch tín hiệu cho từng dòng trong danh sách Wi-Fi.
Row {
    id: root

    property int bars: 0        //!< 0..4
    property color barColor: Theme.ink

    spacing: 2
    height: 16

    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            width: 3
            radius: 1.5
            height: 5 + index * 3.4
            anchors.verticalCenter: parent.verticalCenter
            color: root.barColor
            opacity: index < root.bars ? 0.92 : 0.2
        }
    }
}
