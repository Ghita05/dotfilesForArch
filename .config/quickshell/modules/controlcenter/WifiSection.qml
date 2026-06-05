import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 14

    property bool wifiEnabled: false
    property string activeSsid: ""
    property var networks: []
    property var knownSsids: []
    readonly property var activeNet: {
        for (const n of networks) if (n.ssid === activeSsid) return n
        return null
    }

    Process { id: checkProc; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { id: checkOut } }
    Process { id: scanProc; command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]; stdout: StdioCollector { id: scanOut } }
    Process { id: savedProc; command: ["nmcli", "-t", "-f", "name", "connection", "show"]; stdout: StdioCollector { id: savedOut } }
    Process { id: toggleProc; stdout: StdioCollector { id: toggleOut } }
    Process { id: connProc; stdout: StdioCollector { id: connOut } }

    function rescan() { scanProc.running = true; savedProc.running = true }
    Component.onCompleted: checkProc.running = true
    Timer { id: delayedScan; interval: 1200; onTriggered: root.rescan() }
    Timer { interval: 8000; running: root.wifiEnabled; repeat: true; onTriggered: root.rescan() }

    // ---------- radial hub ----------
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 300

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 210; height: 210; radius: 105
            color: "transparent"; border.color: Root.Theme.border; border.width: 1
            opacity: 0; scale: 0.6
            Component.onCompleted: ringAnim.start()
            ParallelAnimation {
                id: ringAnim
                NumberAnimation { target: ring; property: "opacity"; to: 0.7; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }
        Rectangle {
            id: hub
            anchors.centerIn: parent
            width: 140; height: 140; radius: 70
            color: root.activeSsid !== "" ? Root.Theme.selection : Root.Theme.surfaceGlassHi
            border.color: root.activeSsid !== "" ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
            Behavior on color { ColorAnimation { duration: 200 } }
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: hubAnim.start()
            ParallelAnimation {
                id: hubAnim
                NumberAnimation { target: hub; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: hub; property: "scale"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            }
            Column {
                anchors.centerIn: parent; spacing: 3
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf1eb"; color: root.activeSsid !== "" ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 24 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; width: 120; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: root.activeSsid !== "" ? root.activeSsid : (root.wifiEnabled ? "Not connected" : "Wi-Fi off"); color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                Text { anchors.horizontalCenter: parent.horizontalCenter; visible: root.activeSsid !== ""; text: "Connected"; color: Root.Theme.good; font.family: Root.Theme.fontFamily; font.pixelSize: 9 }
            }
        }

        component Sat: Rectangle {
            id: sat
            property string label
            property string value
            property int delay: 0
            property bool clickable: false
            signal activated()
            width: 120; height: 44; radius: 12
            color: (clickable && satHov.containsMouse) ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass
            border.color: Root.Theme.border; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: satAnim.start()
            SequentialAnimation {
                id: satAnim
                PauseAnimation { duration: sat.delay }
                ParallelAnimation {
                    NumberAnimation { target: sat; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: sat; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                }
            }
            Column {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                spacing: 1
                Text { text: sat.value; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; width: parent.width; elide: Text.ElideRight }
                Text { text: sat.label; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 9 }
            }
            MouseArea { id: satHov; anchors.fill: parent; hoverEnabled: true; enabled: sat.clickable; cursorShape: Qt.PointingHandCursor; onClicked: sat.activated() }
        }

        Rectangle { width: 2; height: 20; anchors.bottom: hub.top; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 2; height: 20; anchors.top: hub.bottom; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 20; height: 2; anchors.right: hub.left; anchors.verticalCenter: hub.verticalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 20; height: 2; anchors.left: hub.right; anchors.verticalCenter: hub.verticalCenter; color: Root.Theme.border; opacity: 0.6 }

        Sat { label: "Switch / Scan"; value: "Scan"; delay: 240; clickable: true; anchors.bottom: hub.top; anchors.bottomMargin: 20; anchors.horizontalCenter: hub.horizontalCenter; onActivated: root.rescan() }
        Sat { label: "Signal"; value: root.activeNet ? root.activeNet.signal + "%" : "—"; delay: 300; anchors.right: hub.left; anchors.rightMargin: 20; anchors.verticalCenter: hub.verticalCenter }
        Sat { label: "Security"; value: root.activeNet ? (root.activeNet.secured ? "Secured" : "Open") : "—"; delay: 340; anchors.left: hub.right; anchors.leftMargin: 20; anchors.verticalCenter: hub.verticalCenter }
        Sat {
            label: "Wi-Fi"; value: root.wifiEnabled ? "On" : "Off"; delay: 420; clickable: true
            anchors.top: hub.bottom; anchors.topMargin: 20; anchors.horizontalCenter: hub.horizontalCenter
            color: root.wifiEnabled ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
            border.color: root.wifiEnabled ? Root.Theme.selectionStrong : Root.Theme.border
            onActivated: { toggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]; toggleProc.running = true }
        }
    }

    // ---------- network list ----------
    Text { visible: root.wifiEnabled && root.networks.length > 0; text: "Networks"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    Repeater {
        model: root.wifiEnabled ? root.networks : []
        delegate: FocusScope {
            id: rowItem
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: mainRow.height + (expanded ? 46 : 0)
            Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            clip: true
            property bool expanded: false
            property bool isActive: modelData.ssid === root.activeSsid
            property bool needsPw: modelData.secured && !isActive && root.knownSsids.indexOf(modelData.ssid) === -1

            opacity: 0; scale: 0.7; transformOrigin: Item.Center
            Component.onCompleted: rowBloom.start()
            SequentialAnimation {
                id: rowBloom
                PauseAnimation { duration: 460 + rowItem.index * 45 }
                ParallelAnimation {
                    NumberAnimation { target: rowItem; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: rowItem; property: "scale"; to: 1; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }
            }

            Rectangle {
                id: mainRow
                width: parent.width; height: 40; radius: 10
                color: rowItem.isActive ? Root.Theme.selection : (rowHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass)
                Behavior on color { ColorAnimation { duration: 120 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                    Text { text: rowItem.isActive ? "\uf00c" : ""; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12; visible: rowItem.isActive }
                    Text { text: modelData.ssid; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: (modelData.secured ? "\uf023  " : "") + modelData.signal + "%"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                }
                MouseArea { id: rowHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rowItem.expanded = !rowItem.expanded }
            }

            Rectangle {
                anchors.top: mainRow.bottom; anchors.topMargin: 6
                width: parent.width; height: 36; radius: 10
                color: Root.Theme.surfaceGlassHi
                visible: rowItem.expanded

                // connect / disconnect / password trigger
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                    visible: !pwField.visible
                    Text {
                        text: rowItem.isActive ? "Disconnect" : "Connect"
                        color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium
                        Layout.fillWidth: true
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (rowItem.isActive) { connProc.command = ["nmcli", "connection", "down", "id", modelData.ssid]; connProc.running = true; rowItem.expanded = false }
                                else if (rowItem.needsPw) { pwField.visible = true; Qt.callLater(() => pwInput.forceActiveFocus()) }
                                else { connProc.command = ["nmcli", "device", "wifi", "connect", modelData.ssid]; connProc.running = true; rowItem.expanded = false }
                            }
                        }
                    }
                    Text { text: "Cancel"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rowItem.expanded = false } }
                }

                // password entry
                RowLayout {
                    id: pwField
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                    visible: false
                    Rectangle {
                        Layout.fillWidth: true; height: 26; radius: 8
                        color: Root.Theme.surfaceVeryGlass; border.color: Root.Theme.selectionStrong; border.width: 1
                        TextInput {
                            id: pwInput
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                            echoMode: TextInput.Password; clip: true; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true
                            onAccepted: if (text.length > 0) { connProc.command = ["nmcli", "device", "wifi", "connect", rowItem.modelData.ssid, "password", text]; connProc.running = true; text = ""; pwField.visible = false; rowItem.expanded = false }
                        }
                        Text { anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: Text.AlignVCenter; text: "Password"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12; visible: pwInput.text.length === 0 && !pwInput.activeFocus }
                        MouseArea { anchors.fill: parent; onClicked: pwInput.forceActiveFocus() }
                    }
                    Text { text: "Join"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (pwInput.text.length > 0) { connProc.command = ["nmcli", "device", "wifi", "connect", rowItem.modelData.ssid, "password", pwInput.text]; connProc.running = true; pwInput.text = ""; pwField.visible = false; rowItem.expanded = false } } }
                }
            }
        }
    }

    Text { visible: !root.wifiEnabled; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Wi-Fi is off"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }

    // ---------- parsers (your proven logic) ----------
    Connections { target: checkOut; function onStreamFinished() { root.wifiEnabled = checkOut.text.trim() === "enabled"; if (root.wifiEnabled) root.rescan() } }
    Connections {
        target: scanOut
        function onStreamFinished() {
            const lines = scanOut.text.trim().split("\n"); const list = []; const seen = {}; let active = ""
            for (const line of lines) {
                const p = line.split(":"); if (p.length < 3 || !p[1]) continue
                if (p[0].includes("*")) active = p[1]
                if (!seen[p[1]]) { seen[p[1]] = true; list.push({ ssid: p[1], signal: parseInt(p[2]) || 0, secured: p[3] && p[3].length > 0 }) }
            }
            list.sort((a, b) => b.signal - a.signal); root.networks = list; root.activeSsid = active
        }
    }
    Connections { target: savedOut; function onStreamFinished() { const k = []; for (const l of savedOut.text.trim().split("\n")) if (l.length) k.push(l); root.knownSsids = k } }
    Connections { target: toggleOut; function onStreamFinished() { root.wifiEnabled = !root.wifiEnabled; if (root.wifiEnabled) delayedScan.start(); else { root.networks = []; root.activeSsid = "" } } }
    Connections { target: connOut; function onStreamFinished() { Qt.callLater(root.rescan) } }
}