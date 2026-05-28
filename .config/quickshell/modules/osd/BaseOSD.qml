import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

PanelWindow {
    id: root

    // ─── Public API (what callers set) ─────────────────────
    property string icon: ""        // Nerd Font glyph
    property int value: 0           // 0..maxValue
    property int maxValue: 100
    property bool dimmed: false     // e.g. muted state — greys out the bar
    property bool visible_: false
    property int bottomOffset: 80   // Customize vertical position

    // ─── Overlay positioning (bottom, floating) ─────
    anchors { bottom: true }
    margins { bottom: bottomOffset }
    exclusiveZone: 0  // Don't reserve space - allow overlap
    
    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Overlay
        }
    }

    // ─── Window ────────────────────────────────────────────
    implicitWidth: 280
    implicitHeight: 56
    color: "transparent"
    visible: visible_

    // ─── Glass card ────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        color: Root.Theme.surfaceGlass
        radius: 22
        border.color: Root.Theme.border
        border.width: 1
        opacity: root.visible_ ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
        }

        Row {
            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: Root.Theme.accent
                font.family: Root.Theme.fontFamily
                font.pixelSize: 20
                antialiasing: true
                visible: root.icon !== ""
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 180
                height: 6
                radius: 3
                color: "#33ffffff"

                Rectangle {
                    width: parent.width * (root.value / root.maxValue)
                    height: parent.height
                    radius: parent.radius
                    color: root.dimmed ? Root.Theme.textDim : Root.Theme.accent

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.value + "%"
                color: Root.Theme.text
                font.family: Root.Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.SemiBold
                antialiasing: true
            }
        }
    }

    // ─── Hide timer ────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible_ = false
    }

    // ─── Show function — exposed for subclasses to call ────
    function show() {
        visible_ = true
        hideTimer.restart()
    }
}