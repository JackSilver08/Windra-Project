import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "components"
import "panels"

Window {
    id: root
    width: windraDevWindowed ? 1280 : Screen.width
    height: windraDevWindowed ? 720 : Screen.height
    visible: true
    visibility: windraDevWindowed ? Window.Windowed : Window.FullScreen
    title: "Windra Shell · 0.2 Desktop Alpha"
    color: "#10181b"

    readonly property bool reduceMotion: windraSettings.effectiveReduceMotion
    readonly property int edgeGap: Math.max(18, Math.round(Math.min(width, height) * 0.032))

    function launch(appId) {
        popupController.close()
        shellBackend.launchApp(appId)
    }

    Image {
        anchors.fill: parent
        source: "assets/wallpaper/windra-meadow.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    // Chỉ phủ một lớp rất nhẹ để chrome kính đọc được trên cả vùng trời lẫn cỏ.
    Rectangle { anchors.fill: parent; color: "#061216"; opacity: 0.035 }

    StatusIsland {
        id: statusIsland
        z: 10
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.edgeGap * 0.72
        anchors.rightMargin: root.edgeGap * 0.72
        width: 276
        height: 54
        reduceMotion: root.reduceMotion
        onWifiClicked: popupController.toggle("wifi")
        onVolumeClicked: popupController.toggle("volume")
        onBatteryClicked: popupController.toggle("battery")
    }

    BottomDock {
        id: dock
        z: 10
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.edgeGap
        anchors.bottomMargin: root.edgeGap * 0.72
        width: Math.min(Math.max(690, parent.width * 0.405), 790)
        height: 72
        reduceMotion: root.reduceMotion
        onPowerRequested: popupController.toggle("power")
        onLauncherRequested: {
            popupController.open("launcher")
            launcher.focusSearch("")
        }
        onAppRequested: appId => root.launch(appId)
        onSearchSubmitted: query => {
            if (!query.length) return
            popupController.open("launcher")
            launcher.focusSearch(query)
        }
    }

    ClockPill {
        id: clock
        z: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.edgeGap
        anchors.bottomMargin: root.edgeGap * 0.72
        width: 222
        height: 76
        reduceMotion: root.reduceMotion
        onAppsClicked: popupController.toggle("apps")
        onClockClicked: popupController.toggle("calendar")
    }

    // Click ra ngoài đóng popup đang mở — một chỗ duy nhất cho mọi popup.
    MouseArea {
        z: 20
        anchors.fill: parent
        visible: popupController.anyOpen
        onClicked: popupController.close()
    }

    WifiPopup {
        id: wifiPopup
        z: 30
        open: popupController.active === "wifi"
        reduceMotion: root.reduceMotion
        anchorItem: statusIsland.wifiAnchor
        preferredSide: "below"
    }

    VolumePopup {
        id: volumePopup
        z: 30
        open: popupController.active === "volume"
        reduceMotion: root.reduceMotion
        anchorItem: statusIsland.volumeAnchor
        preferredSide: "below"
    }

    BatteryPopup {
        id: batteryPopup
        z: 30
        open: popupController.active === "battery"
        reduceMotion: root.reduceMotion
        anchorItem: statusIsland.batteryAnchor
        preferredSide: "below"
    }

    CalendarPopup {
        id: calendarPopup
        z: 30
        open: popupController.active === "calendar"
        reduceMotion: root.reduceMotion
        anchorItem: clock.clockAnchor
        preferredSide: "above"
    }

    RunningAppsPopup {
        id: appsPopup
        z: 30
        open: popupController.active === "apps"
        reduceMotion: root.reduceMotion
        anchorItem: clock.appsAnchor
        preferredSide: "above"
    }

    LauncherPanel {
        id: launcher
        z: 30
        anchors.left: parent.left
        anchors.leftMargin: root.edgeGap
        anchors.bottom: dock.top
        anchors.bottomMargin: 14
        open: popupController.active === "launcher"
        reduceMotion: root.reduceMotion
        onAppRequested: appId => root.launch(appId)
        onWebSearchRequested: query => {
            popupController.close()
            shellBackend.webSearch(query)
        }
        onCloseRequested: popupController.close()
    }

    PowerMenu {
        id: powerMenu
        z: 30
        anchors.left: parent.left
        anchors.leftMargin: root.edgeGap
        anchors.bottom: dock.top
        anchors.bottomMargin: 14
        open: popupController.active === "power"
        reduceMotion: root.reduceMotion
        previewMode: windraDevWindowed
        onActionRequested: action => {
            popupController.close()
            shellBackend.powerAction(action)
        }
    }

    NotificationToast {
        id: toast
        z: 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 110
        reduceMotion: root.reduceMotion
    }

    Connections {
        target: shellBackend
        function onNotification(message) { toast.show(message) }
    }

    Connections {
        target: networkService
        function onConnectSucceeded(ssid) { toast.show("Đã kết nối " + ssid) }
    }

    Label {
        visible: windraDevWindowed
        text: "Windra 0.2 Desktop Alpha · development preview"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 14
        color: "white"
        opacity: 0.58
        font.pixelSize: 11
        z: 11
    }

    Component.onCompleted: Qt.callLater(function() {
        statusIsland.playIntro()
        dock.playIntro()
        clock.playIntro()
    })

    Shortcut { sequence: "Esc"; onActivated: popupController.close() }
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: {
            popupController.open("launcher")
            launcher.focusSearch("")
        }
    }
}
