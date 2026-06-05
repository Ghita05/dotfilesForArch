import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.." as Root

PanelWindow {
    id: root
    property bool open: false
    property string tab: "audio"
    property bool _show: false

    visible: _show
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: {
        if (this.WlrLayershell) this.WlrLayershell.layer = WlrLayer.Overlay
    }
    onOpenChanged: {
        if (open) _show = true
        else closeTimer.restart()        // keep mapped until slide-out finishes
        if (this.WlrLayershell)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    }
    onTabChanged: { bodyLoader.opacity = 0; bodyLoader.y = 10 }   // re-trigger reveal

    Timer { id: closeTimer; interval: 360; onTriggered: if (!root.open) root._show = false }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
        function openTab(tab: string): void { root.tab = tab; root.open = true }
    }

    // light scrim
    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
    }

    Rectangle {
        id: panel
        width: 440
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; margins: 12 }
        radius: 24
        color: Root.Theme.panel
        border.color: Root.Theme.border
        border.width: 1

        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }

        transform: Translate {
            x: root.open ? 0 : panel.width + 60
            Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutExpo } }
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            Text {
                text: "Control Center"
                color: Root.Theme.text
                font.family: Root.Theme.fontFamily
                font.pixelSize: 18; font.weight: Font.Medium
                Layout.fillWidth: true
            }

            // tab bar with a sliding indicator
            Item {
                id: tabBar
                Layout.fillWidth: true
                height: 40
                property var keys:  ["audio", "wifi", "bluetooth", "battery", "display"]
                property var icons: ["\uf028", "\uf1eb", "\uf293", "\uf240", "\uf108"]
                property int active: keys.indexOf(root.tab)
                readonly property int step: 60   // 52 width + 8 spacing

                Rectangle {                       // the slider
                    width: 52; height: 40; radius: 12
                    x: tabBar.active * tabBar.step
                    color: Root.Theme.selection
                    border.color: Root.Theme.selectionStrong; border.width: 1
                    Behavior on x {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    }
                }
                Row {
                    spacing: 8
                    Repeater {
                        model: tabBar.keys.length
                        delegate: Item {
                            required property int index
                            width: 52; height: 40
                            Text {
                                anchors.centerIn: parent
                                text: tabBar.icons[index]
                                color: index === tabBar.active ? Root.Theme.text : Root.Theme.textDim
                                font.family: Root.Theme.fontFamily; font.pixelSize: 15
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tab = tabBar.keys[index]
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Root.Theme.border; opacity: 0.6 }

            Flickable {
                id: bodyFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: bodyLoader.implicitHeight + 12
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: bodyLoader
                    width: bodyFlick.width
                    // FILE-PATH loading: a broken section breaks only its own tab.
                    source: root.tab === "audio"     ? "AudioSection.qml"
                          : root.tab === "wifi"      ? "WifiSection.qml"
                          : root.tab === "bluetooth" ? "BluetoothSection.qml"
                          : root.tab === "battery"   ? "BatterySection.qml"
                          : "DisplaySection.qml"

                    opacity: 0
                    y: 10
                    onLoaded: { opacity = 1; y = 0 }
                    onStatusChanged: if (status === Loader.Error) { opacity = 1; y = 0 }
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }

                // shown only when the active section fails to load
                Text {
                    anchors.top: parent.top; anchors.topMargin: 8
                    width: parent.width
                    visible: bodyLoader.status === Loader.Error
                    wrapMode: Text.WordWrap
                    text: "This section failed to load.\nRun  qs log  and check the first ERROR."
                    color: Root.Theme.crit
                    font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
            }
        }
    }
}