import QtQuick
import Quickshell.Services.Mpris
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "media"
    property var player: {
        const ps = Mpris.players.values
        if (!ps.length) return null
        for (const p of ps) if (p.isPlaying) return p
        return ps.length ? ps[0] : null
    }
    property real posNow: 0
    readonly property real prog: (player && player.length > 0) ? Math.max(0, Math.min(1, posNow / player.length)) : 0

    implicitWidth: 340
    implicitHeight: card.height
    visible: shown && player !== null

    Timer { running: root.visible; interval: 1000; repeat: true; onTriggered: root.posNow = root.player ? root.player.position : 0 }

    Rectangle {
        id: card
        width: parent.width; height: 132; radius: 18
        color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.9
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        MouseArea { anchors.fill: parent }

        Row {
            anchors.fill: parent; anchors.margins: 16; spacing: 14

            Rectangle {
                width: 100; height: 100; radius: 12; clip: true
                anchors.verticalCenter: parent.verticalCenter
                color: Root.Theme.surfaceVeryGlass
                border.color: Root.Theme.border; border.width: 1
                Image {
                    anchors.fill: parent
                    source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(root.player && root.player.trackArtUrl)
                    text: "\uf001"; color: Root.Theme.textDim
                    font.family: Root.Theme.fontFamily; font.pixelSize: 30
                }
            }

            Column {
                width: parent.width - 100 - 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.player ? root.player.trackTitle : ""
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.player ? root.player.trackArtist : ""
                    color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
                Rectangle {
                    width: parent.width; height: 4; radius: 2; color: Root.Theme.surfaceVeryGlass
                    visible: root.player && root.player.length > 0
                    Rectangle { width: parent.width * root.prog; height: parent.height; radius: parent.radius; color: Root.Theme.accent; Behavior on width { NumberAnimation { duration: 400 } } }
                }
                Row {
                    spacing: 22
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 2
                    component Ctl: Text {
                        property string glyph
                        signal activated()
                        text: glyph
                        color: cHov.containsMouse ? Root.Theme.accentSoft : Root.Theme.text
                        font.family: Root.Theme.fontFamily; font.pixelSize: 18
                        MouseArea { id: cHov; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
                    }
                    Ctl { glyph: "\uf048"; onActivated: if (root.player) root.player.previous() }
                    Ctl { glyph: (root.player && root.player.isPlaying) ? "\uf04c" : "\uf04b"; onActivated: if (root.player) { if (root.player.isPlaying) root.player.pause(); else root.player.play() } }
                    Ctl { glyph: "\uf051"; onActivated: if (root.player) root.player.next() }
                }
            }
        }
    }
}