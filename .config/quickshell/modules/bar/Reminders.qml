import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

Item {
    id: root
    property var now: new Date()
    readonly property var next: {
        const up = Root.PersistState.reminders.filter(r => r.ts > now.getTime()).sort((a, b) => a.ts - b.ts)
        return up.length ? up[0] : null
    }
    visible: next !== null
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Process { id: notify }
    Timer {
        interval: 15000; running: true; repeat: true
        onTriggered: {
            const t = new Date(); root.now = t
            for (const r of Root.PersistState.reminders) {
                if (!r.fired && r.ts <= t.getTime()) {
                    r.fired = true
                    notify.command = ["notify-send", "-u", "critical", "Reminder", r.text]; notify.running = true
                    Root.PersistState.removeReminder(r.ts, r.text)
                }
            }
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf0f3"; color: hov.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 150); elide: Text.ElideRight
            text: root.next ? root.next.text : ""
            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
        Text { anchors.verticalCenter: parent.verticalCenter; text: root.next ? Qt.formatTime(new Date(root.next.ts), "HH:mm") : ""; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    }
    MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Root.PopupState.toggle("reminders") }
}