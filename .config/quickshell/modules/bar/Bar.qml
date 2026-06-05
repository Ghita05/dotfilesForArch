import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 38
    margins { top: 8; left: 12; right: 12 }
    color: "transparent"

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Top }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height; radius: 16
            color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
            width: workspacesRow.implicitWidth + 16
            Workspaces { id: workspacesRow; anchors.centerIn: parent }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height; radius: 16
            color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
            width: centerRow.implicitWidth + 32
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 12
                Media { id: media; anchors.verticalCenter: parent.verticalCenter }   // skipped by Row when not visible
                Rectangle { width: 1; height: 16; color: Root.Theme.border; visible: media.visible; anchors.verticalCenter: parent.verticalCenter }
                Clock { id: clock; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height; radius: 16
            color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
            width: rightRow.implicitWidth + 24
            Row {
                id: rightRow
                anchors.centerIn: parent
                spacing: 14
                Volume  { anchors.verticalCenter: parent.verticalCenter }
                Network { anchors.verticalCenter: parent.verticalCenter }
                Battery { anchors.verticalCenter: parent.verticalCenter }
                SysTray { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}