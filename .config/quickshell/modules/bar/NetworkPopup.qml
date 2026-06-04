import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "network"
    property string summary: "—"
    property bool wifiOn: true

    implicitWidth: 300
    implicitHeight: card.height
    visible: shown

    Process {
        id: probe
        command: ["sh", "-c",
            "nmcli -t -f NAME c show --active 2>/dev/null | head -1; echo '==='; nmcli radio wifi 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("===")
                const line = (parts[0] || "").trim()
                root.wifiOn = ((parts[1] || "").trim() === "enabled")
                root.summary = line.length === 0 ? "Disconnected" : line
            }
        }
    }
    onShownChanged: if (shown) probe.running = true
    Component.onCompleted: probe.running = true

    Rectangle {
        id: card
        width: parent.width
        height: 134
        radius: 18
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1
        opacity: root.shown ? 1 : 0
        transform: Translate { y: root.shown ? 0 : -8 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }

        Column {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.margins: 16
            spacing: 10

            Item {
                width: parent.width; height: 18
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "Network"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily
                    font.pixelSize: 13; font.weight: Font.Medium
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: root.summary
                    color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11
                    elide: Text.ElideRight; width: parent.width * 0.6; horizontalAlignment: Text.AlignRight
                }
            }

            // Wi-Fi toggle button
            Rectangle {
                width: parent.width; height: 38; radius: 12
                color: root.wifiOn ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
                border.color: root.wifiOn ? Root.Theme.selectionStrong : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "\uf1eb   Wi-Fi: " + (root.wifiOn ? "On" : "Off")
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
                        root.wifiOn = !root.wifiOn
                    }
                }
            }

            // open the full Control Center for connect/password/Bluetooth
            Rectangle {
                width: parent.width; height: 38; radius: 12
                color: hov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "Network settings"
                    color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Root.PopupState.close()
                        Quickshell.execDetached(["qs", "ipc", "call", "controlCenter", "toggle"])
                    }
                }
            }
        }
    }
}