import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root

    spacing: 12

    // =========================
    // STATE
    // =========================

    property bool wifiEnabled: false
    property string activeSsid: ""
    property var networks: []

    // =========================
    // PROCESSES
    // =========================

    Process {
        id: checkWifiProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { id: checkWifiStdout }
    }

    Process {
        id: toggleWifiProc
        stdout: StdioCollector { id: toggleWifiStdout }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "device", "wifi", "list"]
        stdout: StdioCollector { id: scanStdout }
    }

    Process {
        id: activeConnProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "device", "wifi", "list"]
        stdout: StdioCollector { id: activeConnStdout }
    }

    Process {
        id: connectProc
        stdout: StdioCollector { id: connectStdout }
    }

    // =========================
    // TIMERS
    // =========================

    Timer {
        interval: 8000
        running: root.wifiEnabled
        repeat: true
        onTriggered: scanProc.running = true
    }

    Timer {
        id: delayedScan
        interval: 1200
        repeat: false
        onTriggered: scanProc.running = true
    }

    // =========================
    // HEADER
    // =========================

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Wi-Fi"
            color: "white"
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
        }

        Rectangle {
            width: 52
            height: 26
            radius: 13
            color: root.wifiEnabled ? "#4CAF50" : "#555"

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.wifiEnabled ? 28 : 4

                Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    toggleWifiProc.command = [
                        "nmcli", "radio", "wifi",
                        root.wifiEnabled ? "off" : "on"
                    ]
                    toggleWifiProc.running = true
                }
            }
        }
    }

    // =========================
    // CONNECTION STATUS
    // =========================

    Text {
        visible: root.activeSsid !== ""
        text: "Connected to " + root.activeSsid
        color: "#7CFFB2"
        font.pixelSize: 12
    }

    // =========================
    // NETWORK LIST
    // =========================

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.wifiEnabled

        Repeater {
            model: root.networks

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 12

                color: modelData.ssid === root.activeSsid
                    ? "#3355AAFF"
                    : "#22FFFFFF"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Text {
                        text: modelData.ssid === root.activeSsid ? "✓" : ""
                        color: "#7CFFB2"
                        font.pixelSize: 14
                    }

                    Text {
                        text: modelData.ssid
                        color: "white"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.signal + "%"
                        color: "#CCCCCC"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: modelData.ssid !== root.activeSsid
                    onClicked: {
                        connectProc.command = [
                            "nmcli", "device", "wifi", "connect", modelData.ssid
                        ]
                        connectProc.running = true
                    }
                }
            }
        }
    }

    // =========================
    // DISABLED STATE
    // =========================

    Text {
        visible: !root.wifiEnabled
        text: "Wi-Fi is disabled"
        color: "#999"
        font.pixelSize: 12
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }

    // =========================
    // PROCESS HANDLERS
    // =========================

    Connections {
        target: checkWifiStdout
        function onStreamFinished() {
            root.wifiEnabled = checkWifiStdout.text.trim() === "enabled"
            if (root.wifiEnabled) {
                scanProc.running = true
                activeConnProc.running = true
            }
        }
    }

    Connections {
        target: scanStdout
        function onStreamFinished() {
            let output = scanStdout.text
            let lines = output.trim().split("\n")
            let list = []
            let seen = {}

            for (let line of lines) {
                let parts = line.split(":")
                if (parts.length < 3 || !parts[1]) continue

                let active = parts[0].includes("*")
                if (active) root.activeSsid = parts[1]

                if (!seen[parts[1]]) {
                    seen[parts[1]] = true
                    list.push({
                        ssid: parts[1],
                        signal: parseInt(parts[2]) || 0
                    })
                }
            }

            list.sort((a, b) => b.signal - a.signal)
            root.networks = list
        }
    }

    Connections {
        target: activeConnStdout
        function onStreamFinished() {
            let output = activeConnStdout.text
            let lines = output.trim().split("\n")

            for (let line of lines) {
                let parts = line.split(":")
                if (parts[0] === "yes") {
                    root.activeSsid = parts[1]
                    return
                }
            }
            root.activeSsid = ""
        }
    }

    Connections {
        target: toggleWifiStdout
        function onStreamFinished() {
            root.wifiEnabled = !root.wifiEnabled
            if (root.wifiEnabled) {
                delayedScan.start()
                activeConnProc.running = true
            } else {
                root.networks = []
                root.activeSsid = ""
            }
        }
    }

    Connections {
        target: connectStdout
        function onStreamFinished() {
            activeConnProc.running = true
            Qt.callLater(() => { scanProc.running = true })
        }
    }

    // =========================
    // INIT
    // =========================

    Component.onCompleted: {
        checkWifiProc.running = true
    }
}