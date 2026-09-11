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
    transform: Translate { id: dockTranslate; x: root.reduceMotion ? 0 : -56 }

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
        windra.playIntro(); web.playIntro(); files.playIntro(); notes.playIntro(); calc.playIntro(); apps.playIntro()
    }

    ParallelAnimation {
        id: dockIntro
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
        NumberAnimation { target: dockTranslate; property: "x"; to: 0; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
    }

    // Windra uses a cut silhouette instead of a rounded glass tray.
    WindraCutSurface {
        anchors.fill: parent
        cut: 16
        fillColor: "#e8eef3e8"
        shadowColor: "#62000000"
        shadowOffsetX: 6
        shadowOffsetY: 6
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        AppTile {
            id: windra
            label: "Windra"
            iconSource: "../assets/icons/windra-mark.svg"
            orb: false
            tileColor: "#1f80ff"
            accentTile: true
            reduceMotion: root.reduceMotion
            introDelay: 70
            onClicked: root.powerRequested()
        }

        SearchBox {
            id: search
            width: Math.max(190, Math.min(224, root.width * 0.40))
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            introDelay: 100
            onSubmitted: query => root.searchSubmitted(query)
            onFocused: root.launcherRequested()
        }

        AppTile {
            id: web
            label: "Web"
            iconSource: "../assets/icons/web.svg"
            reduceMotion: root.reduceMotion
            introDelay: 135
            running: root.isRunning("web")
            onClicked: root.appRequested("web")
        }
        AppTile {
            id: files
            label: "Files"
            iconSource: "../assets/icons/folder.svg"
            reduceMotion: root.reduceMotion
            introDelay: 135 + Geo.motionFast / 2
            running: root.isRunning("files")
            onClicked: root.appRequested("files")
        }
        AppTile {
            id: notes
            label: "Notes"
            iconSource: "../assets/icons/notes.svg"
            reduceMotion: root.reduceMotion
            introDelay: 135 + Theme.stagger * 2
            running: root.isRunning("notes")
            onClicked: root.appRequested("notes")
        }
        AppTile {
            id: calc
            label: "Calc"
            iconSource: "../assets/icons/calc.svg"
            reduceMotion: root.reduceMotion
            introDelay: 135 + Theme.stagger * 3
            running: root.isRunning("calc")
            onClicked: root.appRequested("calc")
        }
        AppTile {
            id: apps
            label: "Ứng dụng"
            iconSource: "../assets/icons/apps.svg"
            orb: false
            tileColor: "#162437"
            reduceMotion: root.reduceMotion
            introDelay: 135 + Theme.stagger * 4
            onClicked: root.launcherRequested()
        }
    }
}
