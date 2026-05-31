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
    property var knownSsids: []

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
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
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

    Process {
        id: savedConnsProc
        command: ["nmcli", "-t", "-f", "name", "connection", "show"]
        stdout: StdioCollector { id: savedConnsStdout }
    }

    // =========================
    // TIMERS
    // =========================

    Timer {
        interval: 8000
        running: root.wifiEnabled
        repeat: true
        onTriggered: {
            scanProc.running = true
            savedConnsProc.running = true
        }
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
        spacing: 10

        Text {
            text: "Wi-Fi"
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
        }

        // Refresh button
        Text {
            text: "↻"
            color: Root.Theme.textDim
            font.family: Root.Theme.fontFamily
            font.pixelSize: 16
            opacity: refreshArea.containsMouse ? 1.0 : 0.6
            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: scanProc.running = true
            }
        }

        // Toggle pill
        Rectangle {
            width: 44
            height: 22
            radius: 11
            color: root.wifiEnabled ? Root.Theme.accent : "#33ffffff"
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: Root.Theme.text
                anchors.verticalCenter: parent.verticalCenter
                x: root.wifiEnabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    toggleWifiProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]
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

            FocusScope {
                id: rowItem
                Layout.fillWidth: true
                implicitHeight: mainRow.height + (expanded ? actionRow.height + 6 : 0)
                Behavior on implicitHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                property bool expanded: false
                clip: true

                // The main row
                Rectangle {
                    id: mainRow
                    width: parent.width
                    height: 40
                    radius: 12

                    color: rowHover.containsMouse
                        ? "#1a8ca0c8"
                        : (modelData.ssid === root.activeSsid ? "#287d9bc4" : "#0affffff")
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: modelData.ssid === root.activeSsid ? "✓" : ""
                            color: Root.Theme.accent
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            visible: text.length > 0
                        }

                        Text {
                            text: modelData.ssid
                            color: Root.Theme.text
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.signal + "%"
                            color: Root.Theme.textDim
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rowItem.expanded = !rowItem.expanded
                    }
                }

                // Action row: shows Connect/Disconnect or password prompt
                Rectangle {
                    id: actionRow
                    anchors.top: mainRow.bottom
                    anchors.topMargin: 6
                    width: parent.width
                    height: 36
                    radius: 10
                    color: "#1a8ca0c8"
                    visible: rowItem.expanded
                    opacity: rowItem.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    // Whether this row needs a password (secured + not saved + not the active network)
                    property bool needsPassword: modelData.secured && modelData.ssid !== root.activeSsid && root.knownSsids.indexOf(modelData.ssid) === -1
                    property bool showPasswordInput: false

                    // STATE 1: Connect / Disconnect / Cancel
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        visible: !actionRow.showPasswordInput

                        Text {
                            text: modelData.ssid === root.activeSsid ? "Disconnect" : "Connect"
                            color: Root.Theme.accent
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            Layout.fillWidth: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.ssid === root.activeSsid) {
                                        connectProc.command = ["nmcli", "connection", "down", "id", modelData.ssid]
                                        connectProc.running = true
                                        rowItem.expanded = false
                                    } else if (actionRow.needsPassword) {
                                        actionRow.showPasswordInput = true
                                    } else {
                                        connectProc.command = ["nmcli", "device", "wifi", "connect", modelData.ssid]
                                        connectProc.running = true
                                        rowItem.expanded = false
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Cancel"
                            color: Root.Theme.textDim
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rowItem.expanded = false
                            }
                        }
                    }

                    // STATE 2: Password input
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        visible: actionRow.showPasswordInput

                        Rectangle {
                            Layout.fillWidth: true
                            height: parent.height
                            color: "#0a1a1a1a"
                            radius: 6
                            border.color: Root.Theme.accent
                            border.width: 1
                            focus: true

                            TextInput {
                                id: pwInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                color: Root.Theme.text
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                echoMode: TextInput.Password
                                clip: true
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter
                                focus: true

                                onAccepted: {
                                    if (text.length > 0) {
                                        connectProc.command = ["nmcli", "device", "wifi", "connect", modelData.ssid, "password", text]
                                        connectProc.running = true
                                        actionRow.showPasswordInput = false
                                        rowItem.expanded = false
                                        text = ""
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: "Password"
                                color: Root.Theme.textDim
                                font.family: pwInput.font.family
                                font.pixelSize: pwInput.font.pixelSize
                                visible: pwInput.text.length === 0 && !pwInput.activeFocus
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: pwInput.forceActiveFocus()
                            }
                        }

                        Text {
                            text: "Join"
                            color: Root.Theme.accent
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (pwInput.text.length > 0) {
                                        connectProc.command = ["nmcli", "device", "wifi", "connect", modelData.ssid, "password", pwInput.text]
                                        connectProc.running = true
                                        actionRow.showPasswordInput = false
                                        rowItem.expanded = false
                                        pwInput.text = ""
                                    }
                                }
                            }
                        }

                        Text {
                            text: "×"
                            color: Root.Theme.textDim
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 14

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    actionRow.showPasswordInput = false
                                    pwInput.text = ""
                                }
                            }
                        }
                    }

                    onShowPasswordInputChanged: {
                        if (showPasswordInput) {
                            Qt.callLater(() => {
                                pwInput.forceActiveFocus()
                                pwInput.selectAll()
                            })
                        }
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
                        signal: parseInt(parts[2]) || 0,
                        secured: parts[3] && parts[3].length > 0
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
                savedConnsProc.running = true
            } else {
                root.networks = []
                root.activeSsid = ""
            }
        }
    }

    Connections {
        target: savedConnsStdout
        function onStreamFinished() {
            let output = savedConnsStdout.text
            let lines = output.trim().split("\n")
            let knownSsids = []

            for (let line of lines) {
                if (line.length > 0) {
                    knownSsids.push(line)
                }
            }

            root.knownSsids = knownSsids
        }
    }

    Connections {
        target: connectStdout
        function onStreamFinished() {
            activeConnProc.running = true
            savedConnsProc.running = true
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