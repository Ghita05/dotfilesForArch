import QtQuick
import qs.services
import "../.." as Root

Rectangle {
    id: root

    readonly property color cGlass: "#9912141a"
    readonly property color cAccent: "#6a85a8"
    readonly property color cText: "#c8ccd6"
    readonly property color cDim: "#6b7080"
    readonly property color cGood: "#7fa886"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property bool active: Root.PopupState.active === "vms"
    readonly property bool anyUp: VmService.runningCount > 0

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: mouse.containsMouse || active
        ? Qt.alpha(cAccent, 0.18)
        : cGlass
    border.width: 1
    border.color: anyUp
        ? Qt.alpha(cGood, 0.5)
        : Qt.alpha(cAccent, 0.15)

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "\uf1b2"
            color: root.anyUp ? root.cText : root.cDim
            font.family: root.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: root.anyUp
                ? root.cGood
                : Qt.alpha(root.cDim, 0.4)

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        Text {
            visible: root.anyUp
            text: VmService.runningCount
            color: root.cGood
            font.family: root.fontFamily
            font.pixelSize: 11
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("vms")
    }
}