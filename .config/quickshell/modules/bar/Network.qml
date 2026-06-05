import QtQuick
import Quickshell.Io
import "../.." as Root

Item {
    id: root
    property string mode: "off"
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

    Process { id: act }
    function run(c) { if (act.running) act.running = false; act.command = c; act.running = true }

    Row {
        id: row
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "wifi" ? "\uf1eb" : root.mode === "wired" ? "\uf0e8" : "\uf00d"
            color: hov.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent
            font.family: Root.Theme.fontFamily; font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "wifi" ? root.strength + "%" : root.mode === "wired" ? "wired" : "off"
            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
    }
    MouseArea {
        id: hov
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        // left → Wi-Fi tab, right → Bluetooth tab
        onClicked: (m) => root.run(["qs", "ipc", "call", "controlCenter", "openTab", (m.button === Qt.RightButton ? "bluetooth" : "wifi")])
    }
}