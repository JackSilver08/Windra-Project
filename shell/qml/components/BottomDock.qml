import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme
import "../design/Geometric.js" as Geo

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

    // One flat, pale geometric strip with a single dramatic diagonal end.
    WindraCutSurface {
        anchors.fill: parent
        cut: 24
        cutTopRight: true
        cutBottomLeft: false
        cutBottomRight: false
        fillColor: "#dce6eee9"
        borderColor: "#a9b7c3"
        borderWidth: 1
        shadowColor: "#4d000000"
        shadowOffsetX: 7
        shadowOffsetY: 7
    }

    AppTile {
        id: windra
        label: "Windra Hub"
        iconSource: "../assets/icons/windra-mark.svg"
        width: 48
        height: 48
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 55
        bare: true
        accentTile: true
        tileColor: Geo.sapphire
        onClicked: root.launcherRequested()
    }

    SearchBox {
        id: search
        width: Math.min(278, root.width * 0.39)
        height: 42
        anchors.left: windra.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 80
        onSubmitted: query => root.searchSubmitted(query)
        onFocused: root.launcherRequested()
    }

    AppTile {
        id: files
        label: "Files"
        iconSource: "../assets/icons/folder.svg"
        width: 46
        height: 48
        anchors.left: search.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 115
        bare: true
        running: root.isRunning("files")
        onClicked: root.appRequested("files")
    }

    AppTile {
        id: web
        label: "Web"
        iconSource: "../assets/icons/web.svg"
        width: 46
        height: 48
        anchors.left: files.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        reduceMotion: root.reduceMotion
        introDelay: 145
        bare: true
        running: root.isRunning("web")
        onClicked: root.appRequested("web")
    }
}
