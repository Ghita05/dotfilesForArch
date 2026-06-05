import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.." as Root

PanelWindow {
    id: root
    property bool open: false
    property bool _show: false

    visible: _show
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }
    onOpenChanged: {
        if (open) _show = true
        else closeTimer.restart()
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    }
    Timer { id: closeTimer; interval: 320; onTriggered: if (!root.open) root._show = false }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    Process { id: act }
    function run(cmd) { if (act.running) act.running = false; act.command = ["sh", "-c", cmd]; act.running = true; root.open = false }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.open = false
    }

    Row {
        anchors.centerIn: parent
        spacing: 20

        component PBtn: Rectangle {
            id: btn
            property string glyph
            property string label
            property string cmd
            property int delay: 0
            width: 112; height: 128; radius: 22
            color: bHov.containsMouse ? Root.Theme.selection : Root.Theme.surfaceGlass
            border.color: bHov.containsMouse ? Root.Theme.selectionStrong : Root.Theme.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            // bloom drives `scale`; hover "lift" is a separate transform (no clash)
            opacity: 0
            scale: 0.6
            transformOrigin: Item.Center
            transform: Scale {
                origin.x: btn.width / 2; origin.y: btn.height / 2
                xScale: bHov.containsMouse ? 1.06 : 1
                yScale: bHov.containsMouse ? 1.06 : 1
                Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Component.onCompleted: bAnim.start()
            SequentialAnimation {
                id: bAnim
                PauseAnimation { duration: btn.delay }
                ParallelAnimation {
                    NumberAnimation { target: btn; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: btn; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                }
            }
            Connections {
                target: root
                function onOpenChanged() { if (root.open) bAnim.restart() }
            }

            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: btn.glyph; color: bHov.containsMouse ? Root.Theme.text : Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 32 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: btn.label; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
            }
            MouseArea { id: bHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(btn.cmd) }
        }

        // Safe sleep = lock + DPMS off (avoids the broken Meteor Lake suspend); wakes on input
        PBtn { glyph: "\uf186"; label: "Sleep"; cmd: "loginctl lock-session"; delay: 0 }
        PBtn { glyph: "\uf023"; label: "Lock";     cmd: "hyprlock";              delay: 60 }
        PBtn { glyph: "\uf2f5"; label: "Logout";   cmd: "hyprctl dispatch exit"; delay: 120 }
        PBtn { glyph: "\uf021"; label: "Reboot";   cmd: "systemctl reboot";      delay: 180 }
        PBtn { glyph: "\uf011"; label: "Shutdown"; cmd: "systemctl poweroff";    delay: 240 }
    }
}