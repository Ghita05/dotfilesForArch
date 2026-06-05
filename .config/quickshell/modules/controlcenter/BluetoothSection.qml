import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 16

    property bool btEnabled: false
    property string connName: ""
    property string connAddr: ""
    property int battery: -1
    property var devices: []

    Process { id: checkProc; command: ["bluetoothctl", "show"]; stdout: StdioCollector { id: checkOut } }
    Process { id: toggleProc; stdout: StdioCollector { id: toggleOut } }
    Process { id: devProc; command: ["bluetoothctl", "devices"]; stdout: StdioCollector { id: devOut } }
    Process { id: infoProc; command: ["bluetoothctl", "info"]; stdout: StdioCollector { id: infoOut } }
    Process { id: actProc; stdout: StdioCollector { id: actOut } }

    function refresh() { devProc.running = true; Qt.callLater(() => infoProc.running = true) }
    function scan() { Quickshell.execDetached(["sh", "-c", "bluetoothctl --timeout 6 scan on"]) }
    Component.onCompleted: checkProc.running = true
    Timer { interval: 5000; running: root.btEnabled; repeat: true; onTriggered: root.refresh() }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 300

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 240; height: 240; radius: 120
            color: "transparent"
            border.color: Root.Theme.border
            border.width: 1
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
            color: root.connName !== "" ? Root.Theme.selection : Root.Theme.surfaceGlassHi
            border.color: root.connName !== "" ? Root.Theme.selectionStrong : Root.Theme.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 200 } }

            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: hubAnim.start()
            ParallelAnimation {
                id: hubAnim
                NumberAnimation { target: hub; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: hub; property: "scale"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            }

            Column {
                anchors.centerIn: parent
                spacing: 3
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf025"
                    color: root.connName !== "" ? Root.Theme.text : Root.Theme.textDim
                    font.family: Root.Theme.fontFamily; font.pixelSize: 26
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 110; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    text: root.connName !== "" ? root.connName : "Not connected"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily
                    font.pixelSize: 11; font.weight: Font.Medium
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.connName !== ""
                    text: "Connected"
                    color: Root.Theme.good; font.family: Root.Theme.fontFamily; font.pixelSize: 9
                }
            }
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

        component Link: Rectangle {
            id: link
            property int delay: 0
            color: Root.Theme.border
            opacity: 0
            Component.onCompleted: linkAnim.start()
            SequentialAnimation {
                id: linkAnim
                PauseAnimation { duration: link.delay }
                NumberAnimation { target: link; property: "opacity"; to: 0.6; duration: 200 }
            }
        }

        Link { width: 2; height: 24; anchors.bottom: hub.top; anchors.horizontalCenter: hub.horizontalCenter; delay: 220 }
        Link { width: 2; height: 24; anchors.top: hub.bottom; anchors.horizontalCenter: hub.horizontalCenter; delay: 340 }
        Link { width: 24; height: 2; anchors.right: hub.left; anchors.verticalCenter: hub.verticalCenter; delay: 280 }
        Link { width: 24; height: 2; anchors.left: hub.right; anchors.verticalCenter: hub.verticalCenter; delay: 400 }

        Sat {
            label: "Switch / Scan"; value: "Scan Devices"; delay: 240
            anchors.bottom: hub.top; anchors.bottomMargin: 24; anchors.horizontalCenter: hub.horizontalCenter
            onActivated: root.scan()
        }
        Sat {
            label: "MAC Address"; value: root.connAddr !== "" ? root.connAddr : "—"; delay: 300
            anchors.right: hub.left; anchors.rightMargin: 24; anchors.verticalCenter: hub.verticalCenter
        }
        Sat {
            label: "Battery"; value: root.battery >= 0 ? root.battery + "%" : "—"; delay: 340
            anchors.left: hub.right; anchors.leftMargin: 24; anchors.verticalCenter: hub.verticalCenter
        }
        Sat {
            label: "Bluetooth"; value: root.btEnabled ? "On" : "Off"; delay: 420
            anchors.top: hub.bottom; anchors.topMargin: 24; anchors.horizontalCenter: hub.horizontalCenter
            color: root.btEnabled ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
            border.color: root.btEnabled ? Root.Theme.selectionStrong : Root.Theme.border
            onActivated: { toggleProc.command = ["bluetoothctl", "power", root.btEnabled ? "off" : "on"]; toggleProc.running = true }
        }
    }

    Text {
        visible: root.btEnabled && root.devices.length > 0
        text: "Devices"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11
    }
    Repeater {
        model: root.btEnabled ? root.devices : []
        delegate: Rectangle {
            id: drow
            required property var modelData
            required property int index
            property bool isConn: modelData.address === root.connAddr
            Layout.fillWidth: true
            implicitHeight: 40; radius: 10
            color: isConn ? Root.Theme.selection : (dHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass)
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
            }
            MouseArea {
                id: dHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { actProc.command = ["bluetoothctl", drow.isConn ? "disconnect" : "connect", modelData.address]; actProc.running = true }
            }
        }
    }

    Text {
        visible: !root.btEnabled
        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
        text: "Bluetooth is off"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
    }

    Connections { target: checkOut; function onStreamFinished() { root.btEnabled = checkOut.text.includes("Powered: yes"); if (root.btEnabled) root.refresh() } }
    Connections { target: toggleOut; function onStreamFinished() { root.btEnabled = !root.btEnabled; if (root.btEnabled) Qt.callLater(root.refresh); else { root.devices = []; root.connName = ""; root.connAddr = ""; root.battery = -1 } } }
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
        target: infoOut
        function onStreamFinished() {
            let connected = false
            for (const line of infoOut.text.split("\n")) {
                const t = line.trim()
                if (t.startsWith("Device ")) root.connAddr = t.split(" ")[1]
                else if (t.startsWith("Name:")) root.connName = t.substring(5).trim()
                else if (t.includes("Connected: yes")) connected = true
                else if (t.includes("Connected: no")) connected = false
                else if (t.includes("Battery Percentage")) { const m = t.match(/\((\d+)\)/); if (m) root.battery = parseInt(m[1]) }
            }
            if (!connected) { root.connName = ""; root.connAddr = ""; root.battery = -1 }
        }
    }
    Connections { target: actOut; function onStreamFinished() { Qt.callLater(root.refresh) } }
}