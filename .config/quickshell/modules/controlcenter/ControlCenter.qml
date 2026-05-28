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

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Component.onCompleted: {
        if (this.WlrLayershell) {
            this.WlrLayershell.layer = WlrLayer.Overlay
            this.WlrLayershell.keyboardFocus = WlrKeyboardFocus.None
        }
    }

    // BACKDROP
    Rectangle {
        anchors.fill: parent
        color: "#66000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    // PANEL
    Rectangle {
        id: panel

        width: 400

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            margins: 14
        }

        radius: 22
        color: "#DD1E1E2E"
        border.color: "#33FFFFFF"
        border.width: 1

        transform: Translate {
            x: root.open ? 0 : panel.width + 50

            Behavior on x {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }
        }

        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            Text {
                text: "Control Center"
                color: "white"
                font.pixelSize: 16
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            WifiSection {
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    function toggle() { open = !open }
    function show() { open = true }
    function hide() { open = false }
}