import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "battery"
    readonly property var dev: UPower.displayDevice
    property string profile: "balanced"

    implicitWidth: 300
    implicitHeight: card.height
    visible: shown

    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.profile = text.trim() }
    }
    onShownChanged: if (shown) getProfile.running = true
    Component.onCompleted: getProfile.running = true

    function setProfile(p) {
        Quickshell.execDetached(["powerprofilesctl", "set", p])
        root.profile = p
    }

    Rectangle {
        id: card
        width: parent.width
        height: 122
        radius: 18
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1
        opacity: root.shown ? 1 : 0
        transform: Translate { y: root.shown ? 0 : -8 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }

        Column {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.margins: 16
            spacing: 14

            Item {
                width: parent.width; height: 18
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "Power Profile"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily
                    font.pixelSize: 13; font.weight: Font.Medium
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: (root.dev && root.dev.ready ? Math.round(root.dev.percentage) : 0) + "%"
                          + ((root.dev && root.dev.state === UPowerDeviceState.Charging) ? "  \uf0e7" : "")
                    color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
            }

            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { key: "power-saver", label: "Saver" },
                        { key: "balanced",    label: "Balanced" },
                        { key: "performance", label: "Perf" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - 16) / 3
                        height: 42
                        radius: 12
                        property bool sel: root.profile === modelData.key
                        color: sel ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
                        border.color: sel ? Root.Theme.selectionStrong : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: sel ? Root.Theme.text : Root.Theme.textDim
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: sel ? Font.Medium : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setProfile(modelData.key)
                        }
                    }
                }
            }
        }
    }
}