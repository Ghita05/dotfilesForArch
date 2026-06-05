import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 16

    property bool btEnabled: false
    property var devices: []
    property var connectedDevices: []   // [{address, name}]
    property var connectedAddrs: []
    property int selIdx: 0
    property int selBattery: -1
    property string selName: ""
    readonly property var selDev: (connectedDevices.length > selIdx && selIdx >= 0) ? connectedDevices[selIdx] : null

    Process { id: checkProc; command: ["bluetoothctl", "show"]; stdout: StdioCollector { id: checkOut } }
    Process { id: toggleProc; stdout: StdioCollector { id: toggleOut } }
    Process { id: devProc; command: ["bluetoothctl", "devices"]; stdout: StdioCollector { id: devOut } }
    Process { id: connListProc; command: ["bluetoothctl", "devices", "Connected"]; stdout: StdioCollector { id: connListOut } }
    Process { id: infoProc; stdout: StdioCollector { id: infoOut } }
    Process { id: actProc; stdout: StdioCollector { id: actOut } }

    function refresh() { devProc.running = true; Qt.callLater(() => connListProc.running = true) }
    function scan() { actProc.command = ["sh", "-c", "bluetoothctl --timeout 6 scan on"]; actProc.running = true }
    function queryInfo() {
        if (!selDev) { selName = ""; selBattery = -1; return }
        infoProc.command = ["bluetoothctl", "info", selDev.address]; infoProc.running = true
    }
    function cycleSel() { if (connectedDevices.length < 2) return; selIdx = (selIdx + 1) % connectedDevices.length; queryInfo() }
    Component.onCompleted: checkProc.running = true
    Timer { interval: 5000; running: root.btEnabled; repeat: true; onTriggered: root.refresh() }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 300

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 240; height: 240; radius: 120
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
            width: 130; height: 130; radius: 65
            color: root.connectedAddrs.length > 0 ? Root.Theme.selection : Root.Theme.surfaceGlassHi
            border.color: root.connectedAddrs.length > 0 ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
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
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf025"; color: root.connectedAddrs.length > 0 ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 26 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; width: 112; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: root.selDev ? (root.selName !== "" ? root.selName : root.selDev.name) : "Not connected"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; visible: root.connectedAddrs.length > 0
                    text: root.connectedDevices.length > 1 ? "(" + (root.selIdx + 1) + "/" + root.connectedDevices.length + ") · tap" : "Connected"
                    color: Root.Theme.good; font.family: Root.Theme.fontFamily; font.pixelSize: 9
                }
            }
            MouseArea { anchors.fill: parent; enabled: root.connectedDevices.length > 1; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleSel() }
        }

        component Sat: Rectangle {
            id: sat
            property string label
            property string value
            property int delay: 0
            signal activated()
            width: 112; height: 44; radius: 12
            color: satHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass
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
            MouseArea { id: satHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sat.activated() }
        }

        Rectangle { width: 2; height: 24; anchors.bottom: hub.top; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 2; height: 24; anchors.top: hub.bottom; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 24; height: 2; anchors.right: hub.left; anchors.verticalCenter: hub.verticalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 24; height: 2; anchors.left: hub.right; anchors.verticalCenter: hub.verticalCenter; color: Root.Theme.border; opacity: 0.6 }

        Sat { label: "Switch / Scan"; value: "Scan Devices"; delay: 240; anchors.bottom: hub.top; anchors.bottomMargin: 24; anchors.horizontalCenter: hub.horizontalCenter; onActivated: root.scan() }
        Sat { label: "MAC Address"; value: root.selDev ? root.selDev.address : "—"; delay: 300; anchors.right: hub.left; anchors.rightMargin: 24; anchors.verticalCenter: hub.verticalCenter }
        Sat { label: "Battery"; value: root.selBattery >= 0 ? root.selBattery + "%" : "—"; delay: 340; anchors.left: hub.right; anchors.leftMargin: 24; anchors.verticalCenter: hub.verticalCenter }
        Sat {
            label: "Bluetooth"; value: root.btEnabled ? "On" : "Off"; delay: 420
            anchors.top: hub.bottom; anchors.topMargin: 24; anchors.horizontalCenter: hub.horizontalCenter
            color: root.btEnabled ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
            border.color: root.btEnabled ? Root.Theme.selectionStrong : Root.Theme.border
            onActivated: { toggleProc.command = ["bluetoothctl", "power", root.btEnabled ? "off" : "on"]; toggleProc.running = true }
        }
    }

    Text { visible: root.btEnabled && root.devices.length > 0; text: "Devices"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    Repeater {
        model: root.btEnabled ? root.devices : []
        delegate: Rectangle {
            id: drow
            required property var modelData
            required property int index
            property bool isConn: root.connectedAddrs.indexOf(modelData.address) !== -1
            property bool isSel: root.selDev && root.selDev.address === modelData.address
            Layout.fillWidth: true
            implicitHeight: 40; radius: 10
            color: isSel ? Root.Theme.selectionStrong : isConn ? Root.Theme.selection : (dHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass)
            Behavior on color { ColorAnimation { duration: 120 } }
            opacity: 0; scale: 0.7; transformOrigin: Item.Center
            Component.onCompleted: dAnim.start()
            SequentialAnimation {
                id: dAnim
                PauseAnimation { duration: 480 + drow.index * 50 }
                ParallelAnimation {
                    NumberAnimation { target: drow; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: drow; property: "scale"; to: 1; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }
            }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                Text { text: drow.isConn ? "\uf00c" : ""; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12; visible: drow.isConn }
                Text { text: modelData.name || modelData.address; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: drow.isConn ? "connected" : ""; color: Root.Theme.good; font.family: Root.Theme.fontFamily; font.pixelSize: 9; visible: drow.isConn }
            }
            MouseArea {
                id: dHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { actProc.command = ["bluetoothctl", drow.isConn ? "disconnect" : "connect", modelData.address]; actProc.running = true }
            }
        }
    }

    Text { visible: !root.btEnabled; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Bluetooth is off"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }

    Connections { target: checkOut; function onStreamFinished() { root.btEnabled = checkOut.text.includes("Powered: yes"); if (root.btEnabled) root.refresh() } }
    Connections { target: toggleOut; function onStreamFinished() { root.btEnabled = !root.btEnabled; if (root.btEnabled) Qt.callLater(root.refresh); else { root.devices = []; root.connectedDevices = []; root.connectedAddrs = []; root.selName = ""; root.selBattery = -1 } } }
    Connections {
        target: devOut
        function onStreamFinished() {
            const list = []
            for (const line of devOut.text.trim().split("\n")) {
                if (!line.startsWith("Device ")) continue
                const p = line.replace("Device ", "").split(" ")
                list.push({ address: p[0], name: p.slice(1).join(" ") })
            }
            root.devices = list
        }
    }
    Connections {
        target: connListOut
        function onStreamFinished() {
            const devs = [], addrs = []
            for (const line of connListOut.text.trim().split("\n")) {
                if (!line.startsWith("Device ")) continue
                const p = line.replace("Device ", "").split(" ")
                devs.push({ address: p[0], name: p.slice(1).join(" ") }); addrs.push(p[0])
            }
            root.connectedDevices = devs; root.connectedAddrs = addrs
            if (root.selIdx >= devs.length) root.selIdx = 0
            root.queryInfo()
        }
    }
    Connections {
        target: infoOut
        function onStreamFinished() {
            let name = "", batt = -1
            for (const line of infoOut.text.split("\n")) {
                const t = line.trim()
                if (t.startsWith("Name:")) name = t.substring(5).trim()
                else if (t.includes("Battery Percentage")) { const m = t.match(/\((\d+)\)/); if (m) batt = parseInt(m[1]) }
            }
            root.selName = name; root.selBattery = batt
        }
    }
    Connections { target: actOut; function onStreamFinished() { Qt.callLater(root.refresh) } }
}