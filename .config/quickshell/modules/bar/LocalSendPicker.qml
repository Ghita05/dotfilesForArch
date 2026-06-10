import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

// Overlay listing scanned LocalSend devices. Click one to send the staged file.
PanelWindow {
    id: root
    visible: Root.Devices.picking
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore

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
            onClicked: Root.Devices.cancelPick()
        }
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 54
        anchors.rightMargin: 12
        width: 240
        height: cardCol.implicitHeight + 24
        radius: 16
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1

        opacity: 0
        scale: 0.94
        Component.onCompleted: { card.opacity = 1; card.scale = 1 }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent }

        Column {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 12
            spacing: 8

            Text {
                text: "Send to"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 11
                color: "#6b7280"
            }

            Text {
                visible: Root.Devices.sendTargets.length === 0
                text: "No devices found"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                color: Root.Theme.text
            }

            Repeater {
                model: Root.Devices.sendTargets
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: 212
                    height: 34
                    radius: 10
                    color: rowHov.containsMouse ? Root.Theme.surface : "transparent"
                    border.color: rowHov.containsMouse ? Root.Theme.accent : Root.Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9
                        Text {
                            text: "\uf1d8"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            color: Root.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: row.modelData.name
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 13
                                color: Root.Theme.text
                            }
                            Text {
                                text: row.modelData.ip
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: "#6b7280"
                            }
                        }
                    }
                    MouseArea {
                        id: rowHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Devices.sendTo(row.modelData.ip)
                    }
                }
            }
        }
    }
}