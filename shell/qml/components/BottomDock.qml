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
        windra.playIntro(); files.playIntro(); web.playIntro(); notes.playIntro(); calc.playIntro(); apps.playIntro()
    }

    ParallelAnimation {
        id: dockIntro
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
        NumberAnimation { target: dockTranslate; property: "x"; to: 0; duration: root.reduceMotion ? 80 : Theme.motionSlow; easing.type: Easing.OutCubic }
    }

    // Main glass body. Alpha + border thay cho blur nặng để giữ Windra nhẹ.
    Rectangle {
        id: glassBody
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - 38
        radius: height / 2
        color: Theme.chromeGlass
        border.width: 1
        border.color: Theme.chromeBorder
    }

    // Glow mảnh chạy dọc chân dock, giống HUD trong mockup.
    Rectangle {
        anchors.left: glassBody.left
        anchors.right: glassBody.right
        anchors.bottom: glassBody.bottom
        anchors.leftMargin: 26
        anchors.rightMargin: 20
        height: 2
        radius: 1
        color: Theme.chromeGlow
        opacity: 0.72
    }

    // Phần đuôi xiên bên phải giữ DNA thiết kế Windra cũ nhưng được làm nhỏ hơn.
    Canvas {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 72
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = Theme.chromeGlassStrong
            ctx.strokeStyle = Theme.chromeBorder
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width - 24, 0)
            ctx.lineTo(width, height)
            ctx.lineTo(18, height)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()
        }
    }

    Image {
        source: "../assets/icons/windra-waves.svg"
        width: 42
        height: 28
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        fillMode: Image.PreserveAspectFit
        opacity: 0.78
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 11

        AppTile {
            id: windra
            label: "Windra"
            iconSource: "../assets/icons/windra-mark.svg"
            orb: true
            reduceMotion: root.reduceMotion
            introDelay: 100
            onClicked: root.powerRequested()
        }

        SearchBox {
            id: search
            width: Math.max(200, Math.min(255, root.width * 0.32))
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            reduceMotion: root.reduceMotion
            introDelay: 150
            onSubmitted: query => root.searchSubmitted(query)
            onFocused: root.launcherRequested()
        }

        AppTile {
            id: web
            label: "Web"
            iconSource: "../assets/icons/web.svg"
            accentTile: true
            reduceMotion: root.reduceMotion
            introDelay: 210
            running: root.isRunning("web")
            onClicked: root.appRequested("web")
        }
        AppTile {
            id: files
            label: "Files"
            iconSource: "../assets/icons/folder.svg"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger
            running: root.isRunning("files")
            onClicked: root.appRequested("files")
        }
        AppTile {
            id: notes
            label: "Notes"
            iconSource: "../assets/icons/notes.svg"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 2
            running: root.isRunning("notes")
            onClicked: root.appRequested("notes")
        }
        AppTile {
            id: calc
            label: "Calc"
            iconSource: "../assets/icons/calc.svg"
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 3
            running: root.isRunning("calc")
            onClicked: root.appRequested("calc")
        }
        AppTile {
            id: apps
            label: "Ứng dụng"
            iconSource: "../assets/icons/apps.svg"
            orb: true
            reduceMotion: root.reduceMotion
            introDelay: 210 + Theme.stagger * 4
            onClicked: root.launcherRequested()
        }
    }
}
