import QtQuick
import QtQuick.Controls
import "../design/Theme.js" as Theme

Item {
    id: root
    property bool reduceMotion: false
    //! Đổi giá trị mỗi khi ApplicationModel thay đổi, để ép tính lại isRunning().
    property int runningRevision: 0
    signal powerRequested()
    signal launcherRequested()
    signal appRequested(string appId)
    signal searchSubmitted(string query)

    opacity: 0
    transform: Translate { id: dockTranslate; x: root.reduceMotion ? 0 : -90 }

    // Running indicator lấy trực tiếp từ ApplicationModel — app tự thoát thì
    // gạch dưới icon cũng tắt theo, không cần shell tự đoán.
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
        power.playIntro(); files.playIntro(); web.playIntro(); notes.playIntro(); calc.playIntro(); apps.playIntro()
    }

    ParallelAnimation {
        id: dockIntro
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
        NumberAnimation { target: dockTranslate; property: "x"; to: 0; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
    }

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "rgba(239, 242, 233, 0.84)"
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width - 52, 0)
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.closePath()
            ctx.fill()
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        AppTile {
            id: power
            label: "Nguồn"
            iconSource: "../assets/icons/power.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 100
            onClicked: root.powerRequested()
        }

        SearchBox {
            id: search
            width: Math.max(220, Math.min(325, root.width * 0.34))
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            introDelay: 150
            onSubmitted: query => root.searchSubmitted(query)
            onFocused: root.launcherRequested()
        }

        AppTile {
            id: files
            label: "Files"
            iconSource: "../assets/icons/folder.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 210
            running: root.isRunning("files")
            onClicked: root.appRequested("files")
        }
        AppTile {
            id: web
            label: "Web"
            iconSource: "../assets/icons/web.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger
            running: root.isRunning("web")
            onClicked: root.appRequested("web")
        }
        AppTile {
            id: notes
            label: "Notes"
            iconSource: "../assets/icons/notes.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 2
            running: root.isRunning("notes")
            onClicked: root.appRequested("notes")
        }
        AppTile {
            id: calc
            label: "Calc"
            iconSource: "../assets/icons/calc.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 3
            running: root.isRunning("calc")
            onClicked: root.appRequested("calc")
        }
        AppTile {
            id: apps
            label: "Ứng dụng"
            iconSource: "../assets/icons/apps.svg"
            tileColor: "transparent"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 4
            onClicked: root.launcherRequested()
        }
    }
}
