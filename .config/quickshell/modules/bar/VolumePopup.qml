import QtQuick
import Quickshell.Services.Pipewire
import "../.." as Root

Item {
    id: root
    property var sink: Pipewire.defaultAudioSink
    readonly property bool shown: Root.PopupState.active === "volume"
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real vol: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property real clamped: Math.max(0, Math.min(1, vol))

    implicitWidth: 280
    implicitHeight: card.height
    visible: shown

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Rectangle {
        id: card
        width: parent.width
        height: 96
        radius: 18
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1
        opacity: root.shown ? 1 : 0
        transform: Translate { y: root.shown ? 0 : -8 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }   // swallow clicks inside the card

        Column {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.margins: 16
            spacing: 14

            Item {
                width: parent.width; height: 18
                Text {
                    id: micon
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? "\uf026" : "\uf028"
                    color: root.muted ? Root.Theme.textDim : Root.Theme.accent
                    font.family: Root.Theme.fontFamily; font.pixelSize: 14
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
                Text {
                    anchors.left: micon.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                    text: "Output Volume"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily
                    font.pixelSize: 13; font.weight: Font.Medium
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.clamped * 100) + "%"
                    color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
            }

            Item {
                width: parent.width; height: 16
                Rectangle {
                    id: track
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6; radius: 3
                    color: Root.Theme.surfaceVeryGlass
                    Rectangle {
                        width: track.width * root.clamped; height: parent.height; radius: parent.radius
                        color: root.muted ? Root.Theme.textDim : Root.Theme.accent
                        Behavior on width { NumberAnimation { duration: 60 } }
                    }
                    Rectangle {
                        x: track.width * root.clamped - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: Root.Theme.accentSoft
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setFromX(mx) {
                        if (!root.sink || !root.sink.audio) return
                        root.sink.audio.volume = Math.max(0, Math.min(1, mx / width))
                    }
                    onPressed: (m) => setFromX(m.x)
                    onPositionChanged: (m) => { if (pressed) setFromX(m.x) }
                }
            }
        }
    }
}