import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.." as Root

PanelWindow {
    id: root
    property bool open: false

    visible: open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore   // don't respect waybar's exclusion zone

Component.onCompleted: {
        if (this.WlrLayershell) {
            this.WlrLayershell.layer = WlrLayer.Overlay
        }
    }

    // Reactive: update keyboard focus whenever open changes
    onOpenChanged: {
        if (this.WlrLayershell) {
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    // Backdrop — full screen, ignores exclusion zones now
    Rectangle {
        anchors.fill: parent
        color: "#90000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    // Panel — back to translucent, relying on Hyprland blur for frosting
    Rectangle {
        id: panel
        width: 420
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            margins: 14
        }
        radius: 22
        color: "#a60a0b0f"     // 65% opaque — glass feel, lets blur do its work
        border.color: Root.Theme.border
        border.width: 1

        transform: Translate {
            x: root.open ? 0 : panel.width + 50
            Behavior on x {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }
        }
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }

        MouseArea { anchors.fill: parent }   // swallow clicks

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            Text {
                text: "Control Center"
                color: Root.Theme.text
                font.family: Root.Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            WifiSection { Layout.fillWidth: true }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Theme.border
                opacity: 0.5
            }

            BluetoothSection { Layout.fillWidth: true }

            Item { Layout.fillHeight: true }
        }
    }
}