import QtQuick
import "../design/Theme.js" as Theme

/*!
 * Shared surface for Windra system popups.
 * Keeps one positioning/motion implementation and a quiet, readable visual.
 */
Item {
    id: root

    property bool open: false
    property bool reduceMotion: false

    property Item anchorItem: null
    property string preferredSide: "below"
    property int gap: 10
    property int screenMargin: 14

    readonly property real hiddenOffset: preferredSide === "above"
        ? Theme.slideFor(reduceMotion)
        : -Theme.slideFor(reduceMotion)

    property alias radius: surface.radius
    property alias surfaceColor: surface.color
    readonly property int padding: 18

    implicitWidth: 320
    implicitHeight: 200
    width: implicitWidth
    height: implicitHeight

    visible: opacity > 0.01
    enabled: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.popupMs(root.reduceMotion)
            easing.type: Easing.OutCubic
        }
    }

    transform: Translate {
        y: root.open ? 0 : root.hiddenOffset
        Behavior on y {
            NumberAnimation {
                duration: Theme.popupMs(root.reduceMotion)
                easing.type: Easing.OutCubic
            }
        }
    }

    onOpenChanged: if (open) reposition()
    onWidthChanged: reposition()
    onHeightChanged: reposition()
    Component.onCompleted: reposition()

    Connections {
        target: root.parent
        ignoreUnknownSignals: true
        function onWidthChanged() { root.reposition() }
        function onHeightChanged() { root.reposition() }
    }

    function reposition() {
        if (!parent)
            return

        if (!anchorItem) {
            x = Math.max(screenMargin, parent.width - width - screenMargin)
            y = screenMargin
            return
        }

        var point = anchorItem.mapToItem(parent, 0, 0)
        var below = point.y + anchorItem.height + gap
        var above = point.y - height - gap

        var targetY = preferredSide === "above" ? above : below
        if (targetY + height > parent.height - screenMargin)
            targetY = above
        if (targetY < screenMargin)
            targetY = below

        var targetX = point.x + anchorItem.width / 2 - width / 2

        x = Math.max(screenMargin, Math.min(targetX, parent.width - width - screenMargin))
        y = Math.max(screenMargin, Math.min(targetY, parent.height - height - screenMargin))
    }

    Rectangle {
        anchors.fill: surface
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: surface.radius
        color: Theme.popupShadow
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.popupSurface
        border.width: 1
        border.color: Theme.popupBorder
    }
}
