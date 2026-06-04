import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.." as Root

Row {
    id: root
    spacing: 4

    property var workspaceList: {
        const list = Hyprland.workspaces.values.filter(w => w.id > 0)
        list.sort((a, b) => a.id - b.id)
        return list
    }

    Repeater {
        model: root.workspaceList
        delegate: Rectangle {
            required property var modelData
            property bool isActive: modelData.focused
            property bool isHovered: pillHover.containsMouse

            width: isActive ? 28 : 22
            height: 22
            radius: 8
            color: isActive ? Root.Theme.selection
                 : (isHovered ? Root.Theme.surfaceGlassHi : "transparent")
            border.color: isActive ? Root.Theme.selectionStrong : "transparent"
            border.width: 1

            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }

            Text {
                anchors.centerIn: parent
                text: modelData.id
                color: parent.isActive ? Root.Theme.text : Root.Theme.textDim
                font.family: Root.Theme.fontFamily
                font.pixelSize: 11
                font.weight: parent.isActive ? Font.Bold : Font.Normal
            }

            MouseArea {
                id: pillHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(modelData.id)])
            }
        }
    }
}