import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo
import "../controls"

Item {
    id: root

    property bool reduceMotion: false
    property int runningRevision: 0
    signal powerRequested()
    signal launcherRequested()
    signal appRequested(string appId)
    signal searchSubmitted(string query)

    opacity: 0
    transform: Translate { id: dockTranslate; x: root.reduceMotion ? 0 : -42 }

    function isRunning(id) {
        return root.runningRevision >= 0 && appModel.isRunning(id)
    }

    Connections {
        target: appModel
        function onAppsChanged() { root.runningRevision = root.runningRevision + 1 }
    }

    function playIntro() {
        dockIntro.start()
        search.playIntro()
        windra.playIntro()
        files.playIntro()
        web.playIntro()
    }

    ParallelAnimation {
        id: dockIntro
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: root.reduceMotion ? 80 : Theme.motionSlow
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: dockTranslate
            property: "x"
            to: 0
            duration: root.reduceMotion ? 80 : Theme.motionSlow
            easing.type: Easing.OutCubic
        }
    }

    // The dock is one strong geometric strip, not a row of rounded cards.
    WindraCutSurface {
        anchors.fill: parent
        cut: 22
        cutTopRight: true
        cutBottomLeft: false
        fillColor: "#dbe4ece8"
        borderColor: "#a7b4bf"
        borderWidth: 1
        shadowColor: "#50000000"
        shadowOffsetX: 7
        shadowOffsetY: 7
    }

    // Brand mark / launcher.
    WindraCutSurface {
        id: windraSurface
        width: 44
        height: 44
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        cut: 12
        cutTopRight: false
        cutBottomLeft: false
        fillColor: "#1f80ff"
        borderColor: "#ffffff55"
        borderWidth: 1
        shadowColor: "#30000000"
        shadowOffsetX: 3
        shadowOffsetY: 3

        Image {
            anchors.centerIn: parent
            width: 31
            height: 31
            source: "../assets/icons/windra-mark.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.launcherRequested()
        }

        scale: windraMousePlaceholder.containsMouse ? 1.03 : 1.0
    }

    // Invisible hover proxy keeps the launcher tile responsive without adding a rounded background.
    MouseArea {
        id: windraMousePlaceholder
        anchors.fill: windraSurface
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.launcherRequested()
    }

    SearchBox {
        id: search
        width: Math.min(270, root.width * 0.39)
        height: 42
        anchors.left: windraSurface.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 80
        onSubmitted: query => root.searchSubmitted(query)
        onFocused: root.launcherRequested()
    }

    // Minimal application shortcuts, matching the approved desktop mockup.
    AppTile {
        id: files
        label: "Files"
        iconSource: "../assets/icons/folder.svg"
        width: 48
        height: 48
        anchors.left: search.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 120
        running: root.isRunning("files")
        tileColor: "transparent"
        onClicked: root.appRequested("files")
    }

    AppTile {
        id: web
        label: "Web"
        iconSource: "../assets/icons/web.svg"
        width: 48
        height: 48
        anchors.left: files.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 150
        running: root.isRunning("web")
        tileColor: "transparent"
        onClicked: root.appRequested("web")
    }

    // Keep the launcher accessible from keyboard even though the dock stays visually clean.
    Rectangle {
        visible: false
        anchors.fill: parent
        color: "transparent"
    }
}
