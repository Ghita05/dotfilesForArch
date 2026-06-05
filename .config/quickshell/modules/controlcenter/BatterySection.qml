import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 16

    readonly property var dev: UPower.displayDevice
    readonly property real raw: (dev && dev.ready) ? dev.percentage : 0
    readonly property int pct: Math.round(raw > 1.0 ? raw : raw * 100)
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false
    readonly property int secs: dev ? (charging ? dev.timeToFull : dev.timeToEmpty) : 0
    property string profile: "balanced"

    function fmtTime(s) { if (!s || s <= 0) return "—"; const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60); return h > 0 ? h + "h " + m + "m" : m + "m" }
    function stateColor() { return charging ? Root.Theme.good : pct <= 15 ? Root.Theme.crit : pct <= 30 ? Root.Theme.warn : Root.Theme.accent }

    Process { id: getProfile; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: root.profile = text.trim() } }
    Process { id: setProc }
    Component.onCompleted: getProfile.running = true
    function setProfile(p) { setProc.command = ["powerprofilesctl", "set", p]; setProc.running = true; root.profile = p }

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
        Item {
            id: hub
            anchors.centerIn: parent
            width: 150; height: 150
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: hubAnim.start()
            ParallelAnimation {
                id: hubAnim
                NumberAnimation { target: hub; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: hub; property: "scale"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            }
            Canvas {
                id: gauge
                anchors.fill: parent
                property real value: Math.max(0, Math.min(1, root.pct / 100))
                property color arc: root.stateColor()
                onValueChanged: requestPaint()
                onArcChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    var cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 8
                    ctx.lineWidth = 7; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.strokeStyle = Root.Theme.surfaceGlassHi; ctx.stroke()
                    if (value > 0) { ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * value); ctx.strokeStyle = arc; ctx.stroke() }
                }
            }
            Column {
                anchors.centerIn: parent; spacing: 1
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.charging ? "\uf0e7" : "\uf240"; color: root.stateColor(); font.family: Root.Theme.fontFamily; font.pixelSize: 18 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.pct + "%"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold }
            }
        }
        component Sat: Rectangle {
            id: sat
            property string label
            property string value
            property int delay: 0
            width: 130; height: 44; radius: 12
            color: Root.Theme.surfaceVeryGlass; border.color: Root.Theme.border; border.width: 1
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
        }
        Rectangle { width: 2; height: 20; anchors.bottom: hub.top; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 2; height: 20; anchors.top: hub.bottom; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Sat { label: "Status"; value: root.charging ? "Charging" : "On battery"; delay: 240; anchors.bottom: hub.top; anchors.bottomMargin: 20; anchors.horizontalCenter: hub.horizontalCenter }
        Sat { label: root.charging ? "Until full" : "Remaining"; value: root.fmtTime(root.secs); delay: 320; anchors.top: hub.bottom; anchors.topMargin: 20; anchors.horizontalCenter: hub.horizontalCenter }
    }

    Text { text: "Power Profile"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    Row {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [{ k: "power-saver", l: "Saver" }, { k: "balanced", l: "Balanced" }, { k: "performance", l: "Perf" }]
            delegate: Rectangle {
                id: pb
                required property var modelData
                required property int index
                width: (parent.width - 16) / 3; height: 46; radius: 12
                property bool sel: root.profile === modelData.k
                color: sel ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
                border.color: sel ? Root.Theme.selectionStrong : "transparent"; border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }
                opacity: 0; scale: 0.7; transformOrigin: Item.Center
                Component.onCompleted: pbAnim.start()
                SequentialAnimation {
                    id: pbAnim
                    PauseAnimation { duration: 380 + pb.index * 60 }
                    ParallelAnimation {
                        NumberAnimation { target: pb; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pb; property: "scale"; to: 1; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }
                }
                Text { anchors.centerIn: parent; text: modelData.l; color: pb.sel ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: pb.sel ? Font.Medium : Font.Normal }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setProfile(modelData.k) }
            }
        }
    }
    Item { Layout.fillHeight: true }
}