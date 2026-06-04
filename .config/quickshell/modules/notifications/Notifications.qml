import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Io
import "../.." as Root

PanelWindow {
    id: root

    anchors { top: true; right: true }
    margins { top: 8; right: 12 }
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore     // ignore the bar's reserved space
    color: "transparent"
    implicitWidth: 380
    // shrink to content; 1px floor so the window never has zero size
    implicitHeight: column.implicitHeight > 0 ? column.implicitHeight : 1
    // only mapped when something is showing
    visible: server.trackedNotifications.values.length > 0

    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Overlay
            this.WlrLayershell.namespace = "quickshell-notifications"
        }
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: (n) => { n.tracked = true }
    }

    // qs ipc call notifications dismissAll
    IpcHandler {
        target: "notifications"
        function dismissAll(): void {
            const list = server.trackedNotifications.values
            for (let i = list.length - 1; i >= 0; i--) list[i].dismiss()
        }
    }

    Column {
        id: column
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 8

        Repeater {
            model: server.trackedNotifications
            delegate: Toast {
                required property var modelData
                notif: modelData
                width: root.width
            }
        }
    }
}