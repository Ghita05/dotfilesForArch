import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

PanelWindow {
    id: root
    visible: Root.PopupState.active !== ""
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: {
        if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay
    }

    // Only the area BELOW the bar receives input. The top strip passes clicks
    // through to the bar, so the other pills stay clickable while a popup is open.
    mask: Region { item: catcher }

    Item {
        id: catcher
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            top: parent.top; topMargin: 46     // 8 (margin) + 38 (bar height)
        }
        MouseArea { anchors.fill: parent; onClicked: Root.PopupState.close() }
    }

    VolumePopup   { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    NetworkPopup  { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    BatteryPopup  { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    CalendarPopup { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 54 }
}