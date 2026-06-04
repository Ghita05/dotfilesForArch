import QtQuick
import Quickshell.Io
import "../.." as Root

Item {
    id: root
    property string mode: "off"   // "wifi" | "wired" | "off"
    property int strength: 0

    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Process {
        id: probe
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep ':connected' | head -1; " +
            "echo '==='; " +
            "nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '/^yes/{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("===")
                const conn = (parts[0] || "").trim()
                const sig = parseInt((parts[1] || "").trim()) || 0
                if (conn.indexOf("wifi") === 0)          { root.mode = "wifi";  root.strength = sig }
                else if (conn.indexOf("ethernet") === 0) { root.mode = "wired"; root.strength = 0 }
                else                                      { root.mode = "off";   root.strength = 0 }
            }
        }
    }
    Component.onCompleted: probe.running = true
    Timer { interval: 10000; running: true; repeat: true; onTriggered: probe.running = true }

    Row {
        id: row
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "wifi" ? "\uf1eb" : root.mode === "wired" ? "\uf0e8" : "\uf00d"
            color: hover.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "wifi" ? root.strength + "%" : root.mode === "wired" ? "wired" : "off"
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("network")
    }
}