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

    property bool btEnabled: false
    property string activeDevice: ""
    property var devices: []

    // =========================
    // PROCESSES
    // =========================

    Process {
        id: checkBtProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector { id: checkBtStdout }
    }

    Process {
        id: toggleBtProc
        stdout: StdioCollector { id: toggleBtStdout }
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector { id: scanStdout }
    }

    Process {
        id: infoProc
        command: ["bluetoothctl", "info"]
        stdout: StdioCollector { id: infoStdout }
    }

    Process {
        id: connectProc
        stdout: StdioCollector { id: connectStdout }
    }

    // =========================
    // TIMERS
    // =========================

    Timer {
        interval: 5000
        running: root.btEnabled
        repeat: true
        onTriggered: {
            scanProc.running = true
            Qt.callLater(() => { infoProc.running = true })
        }
    }

    Timer {
        id: delayedScan
        interval: 1200
        repeat: false
        onTriggered: {
            scanProc.running = true
            Qt.callLater(() => { infoProc.running = true })
        }
    }

    // =========================
    // HEADER
    // =========================

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Bluetooth"
            color: "white"
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
        }

        Rectangle {
            width: 52
            height: 26
            radius: 13
            color: root.btEnabled ? "#4CAF50" : "#555"

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.btEnabled ? 28 : 4

                Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    toggleBtProc.command = [
                        "bluetoothctl", "power",
                        root.btEnabled ? "off" : "on"
                    ]
                    toggleBtProc.running = true
                }
            }
        }
    }

    // =========================
    // CONNECTION STATUS
    // =========================

    Text {
        visible: root.activeDevice !== ""
        text: "Connected to " + root.activeDevice
        color: "#7CFFB2"
        font.pixelSize: 12
    }

    // =========================
    // DEVICE LIST
    // =========================

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.btEnabled

        Repeater {
            model: root.devices

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 12

                color: modelData.address === root.activeDevice
                    ? "#3355AAFF"
                    : "#22FFFFFF"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Text {
                        text: modelData.address === root.activeDevice ? "✓" : ""
                        color: "#7CFFB2"
                        font.pixelSize: 14
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name || modelData.address
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: 12
                        }

                        Text {
                            text: modelData.connected ? "Connected" : "Available"
                            color: modelData.connected ? "#7CFFB2" : "#CCCCCC"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: modelData.rssi ? modelData.rssi + "dBm" : ""
                        color: "#CCCCCC"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: modelData.address !== root.activeDevice
                    onClicked: {
                        connectProc.command = ["bluetoothctl", "connect", modelData.address]
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
        visible: !root.btEnabled
        text: "Bluetooth is disabled"
        color: "#999"
        font.pixelSize: 12
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }

    // =========================
    // PROCESS HANDLERS
    // =========================

    Connections {
        target: checkBtStdout
        function onStreamFinished() {
            root.btEnabled = checkBtStdout.text.includes("Powered: yes")
            if (root.btEnabled) {
                scanProc.running = true
                Qt.callLater(() => { infoProc.running = true })
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
                if (!line.startsWith("Device ")) continue

                let parts = line.replace("Device ", "").split(" ")
                if (parts.length < 2) continue

                let address = parts[0]
                let name = parts.slice(1).join(" ")

                if (!seen[address]) {
                    seen[address] = true
                    list.push({
                        address: address,
                        name: name,
                        connected: false,
                        rssi: 0
                    })
                }
            }

            root.devices = list
        }
    }

    Connections {
        target: infoStdout
        function onStreamFinished() {
            let output = infoStdout.text
            let lines = output.trim().split("\n")
            let currentDevice = ""
            let updatedDevices = root.devices.map(d => Object.assign({}, d))

            for (let line of lines) {
                if (line.startsWith("Device ")) {
                    currentDevice = line.replace("Device ", "").split(" ")[0]
                }

                if (line.includes("Connected: yes")) {
                    for (let dev of updatedDevices) {
                        if (dev.address === currentDevice) {
                            dev.connected = true
                            root.activeDevice = currentDevice
                        }
                    }
                }

                if (line.includes("Connected: no")) {
                    for (let dev of updatedDevices) {
                        if (dev.address === currentDevice) {
                            dev.connected = false
                        }
                    }
                }
            }

            updatedDevices.sort((a, b) => {
                if (a.connected !== b.connected) {
                    return b.connected - a.connected
                }
                return a.name.localeCompare(b.name)
            })

            root.devices = updatedDevices
        }
    }

    Connections {
        target: toggleBtStdout
        function onStreamFinished() {
            root.btEnabled = !root.btEnabled
            if (root.btEnabled) {
                delayedScan.start()
                Qt.callLater(() => { infoProc.running = true })
            } else {
                root.devices = []
                root.activeDevice = ""
            }
        }
    }

    Connections {
        target: connectStdout
        function onStreamFinished() {
            Qt.callLater(() => { infoProc.running = true })
        }
    }

    // =========================
    // INIT
    // =========================

    Component.onCompleted: {
        checkBtProc.running = true
    }
}
