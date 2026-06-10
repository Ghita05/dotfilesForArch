import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

// Overlay showing details for Root.Devices.detailId. Click outside to dismiss.
// Loaded from shell.qml. Self-contained — does not touch your PopupState system.
PanelWindow {
    id: root
    visible: Root.Devices.detailId !== "" && dev !== null
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore

    readonly property var dev: Root.Devices.deviceById(Root.Devices.detailId)

    Component.onCompleted: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.layer = WlrLayer.Overlay
    }

    mask: Region { item: catcher }

    Item {
        id: catcher
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 46
        MouseArea {
            anchors.fill: parent
            onClicked: Root.Devices.closeDetail()
        }
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 54
        anchors.rightMargin: 12
        width: 240
        height: cardCol.implicitHeight + 28
        radius: 16
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1

        opacity: 0
        scale: 0.94
        Component.onCompleted: { card.opacity = 1; card.scale = 1 }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        // swallow clicks so tapping the card doesn't dismiss it
        MouseArea { anchors.fill: parent }

        function typeLabel(n) {
            var s = String(n)
            if (s.indexOf("iPad") !== -1)   return "Tablet"
            if (s.indexOf("iPhone") !== -1) return "Phone"
            return "Apple device"
        }
        function typeGlyph(n) {
            var s = String(n)
            if (s.indexOf("iPad") !== -1)   return "\uf10a"
            if (s.indexOf("iPhone") !== -1) return "\uf10b"
            return "\uf179"
        }

        Column {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 14
            spacing: 11

            Row {
                spacing: 11
                Text {
                    text: root.dev ? card.typeGlyph(root.dev.name) : ""
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 20
                    color: Root.Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: root.dev ? root.dev.name : ""
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 15
                        color: Root.Theme.text
                    }
                    Text {
                        text: root.dev ? card.typeLabel(root.dev.name) : ""
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: "#6b7280"
                    }
                }
            }

            Rectangle { width: 208; height: 1; color: Root.Theme.border }

            Row {
                spacing: 8
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: (root.dev && root.dev.reachable) ? Root.Theme.accent : "#444a55"
                }
                Text {
                    text: (root.dev && root.dev.reachable) ? "Connected" : "Offline"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: 8
                visible: root.dev && root.dev.ip !== ""
                Text {
                    text: "\uf0ac"     // globe
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: "#6b7280"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.dev ? root.dev.ip : ""
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}