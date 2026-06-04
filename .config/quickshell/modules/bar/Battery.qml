import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../.." as Root

Item {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property real raw: (dev && dev.ready) ? dev.percentage : 0
    // Builds differ: some report 0..1, some 0..100. Normalize to a percent.
    readonly property int pct: Math.round(raw > 1.0 ? raw : raw * 100)
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false

    visible: dev && dev.ready
    implicitWidth: row.implicitWidth
    implicitHeight: 22

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
            color: root.charging ? Root.Theme.good
                 : root.pct <= 15 ? Root.Theme.crit
                 : root.pct <= 30 ? Root.Theme.warn
                 : Root.Theme.accent
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.pct + "%"
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("battery")
    }
}