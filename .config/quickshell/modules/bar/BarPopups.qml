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

    // popups that contain text inputs need the keyboard; icon popups don't
    readonly property bool needsKeyboard: Root.PopupState.active === "calendar" || Root.PopupState.active === "reminders"

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }
    onNeedsKeyboardChanged: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    }

    mask: Region { item: catcher }

    Item {
        id: catcher
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 46 }
        MouseArea { anchors.fill: parent; onClicked: Root.PopupState.close() }
    }

    VolumePopup    { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    NetworkPopup   { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    BatteryPopup   { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    RemindersPopup { anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 54; anchors.rightMargin: 12 }
    CalendarPopup  { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 54 }
    MediaPopup     { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 54 }
    DeviceDetailPopup { }
}