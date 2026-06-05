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

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }

    mask: Region { item: catcher }

    Item {
        id: catcher
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 46 }
        MouseArea { anchors.fill: parent; onClicked: Root.PopupState.close() }
    }

    CalendarPopup { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 54 }
    MediaPopup    { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 54 }
}