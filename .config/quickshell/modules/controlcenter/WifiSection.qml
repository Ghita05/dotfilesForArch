import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root

    spacing: 12

    // =========================
    // STATE (ONLY SOURCE OF TRUTH)
    // =========================

    property bool wifiEnabled: false
    property string activeSsid: ""
    property var networks: []

    // =========================
    // TIMERS
    // =========================

    Timer {
        interval: 8000
        running: root.wifiEnabled
        repeat: true
        onTriggered: scanNetworks()
    }

    Timer {
        id: delayedScan
        interval: 1200
        repeat: false
        onTriggered: scanNetworks()
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
                onClicked: toggleWifi()
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
                    onClicked: connectToNetwork(modelData.ssid)
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
    // FUNCTIONS
    // =========================

    function toggleWifi() {
        let proc = Process.launch([
            "nmcli",
            "radio",
            "wifi",
            root.wifiEnabled ? "off" : "on"
        ])

        proc.finished.connect(() => {
            root.wifiEnabled = !root.wifiEnabled

            if (root.wifiEnabled) {
                delayedScan.start()
                updateActiveConnection()
            } else {
                root.networks = []
                root.activeSsid = ""
            }
        })
    }

    function scanNetworks() {
        let proc = Process.launch([
            "nmcli",
            "-t",
            "-f",
            "IN-USE,SSID,SIGNAL",
            "device",
            "wifi",
            "list"
        ])

        let output = ""

        proc.stdout.connect(d => output += d.toString())

        proc.finished.connect(() => {

            let lines = output.trim().split("\n")

            let list = []
            let seen = {}

            for (let line of lines) {

                let parts = line.split(":")

                if (parts.length < 3) continue
                if (!parts[1]) continue

                let active = parts[0].includes("*")

                if (active) {
                    root.activeSsid = parts[1]
                }

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
        })
    }

    function updateActiveConnection() {
        let proc = Process.launch([
            "nmcli",
            "-t",
            "-f",
            "ACTIVE,SSID",
            "device",
            "wifi",
            "list"
        ])

        let output = ""

        proc.stdout.connect(d => output += d.toString())

        proc.finished.connect(() => {

            let lines = output.trim().split("\n")

            for (let line of lines) {
                let parts = line.split(":")

                if (parts[0] === "yes") {
                    root.activeSsid = parts[1]
                    return
                }
            }

            root.activeSsid = ""
        })
    }

    function connectToNetwork(ssid) {
        let proc = Process.launch([
            "nmcli",
            "device",
            "wifi",
            "connect",
            ssid
        ])

        proc.finished.connect(() => {
            updateActiveConnection()
            scanNetworks()
        })
    }

    // =========================
    // INIT
    // =========================

    Component.onCompleted: {

        let proc = Process.launch(["nmcli", "radio", "wifi"])

        let output = ""

        proc.stdout.connect(d => output += d.toString())

        proc.finished.connect(() => {

            root.wifiEnabled = output.trim() === "enabled"

            if (root.wifiEnabled) {
                scanNetworks()
                updateActiveConnection()
            }
        })
    }
}