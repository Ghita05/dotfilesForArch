import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "../.." as Root

Item {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property real rawv: (dev && dev.ready) ? dev.percentage : 0
    readonly property int pct: Math.round(rawv > 1.0 ? rawv : rawv * 100)
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false
    visible: dev && dev.ready
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Process { id: act }
    function run(c) { if (act.running) act.running = false; act.command = c; act.running = true }

    function battGlyph(p) {
        if (p >= 90) return "\uf240"
        if (p >= 65) return "\uf241"
        if (p >= 40) return "\uf242"
        if (p >= 15) return "\uf243"
        return "\uf244"
    }
    Row {
        id: row
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.charging ? "\uf0e7" : root.battGlyph(root.pct)
            color: root.charging ? Root.Theme.good : root.pct <= 15 ? Root.Theme.crit : root.pct <= 30 ? Root.Theme.warn : Root.Theme.accent
            font.family: Root.Theme.fontFamily; font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.pct + "%"
            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
    }
    MouseArea {
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: root.run(["qs", "ipc", "call", "controlCenter", "openTab", "battery"])
    }
}