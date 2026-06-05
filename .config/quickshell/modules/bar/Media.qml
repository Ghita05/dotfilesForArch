import QtQuick
import Quickshell.Services.Mpris
import "../.." as Root

Item {
    id: root
    property var player: {
        const ps = Mpris.players.values
        if (!ps.length) return null
        for (const p of ps) if (p.isPlaying) return p
        return ps[0]
    }
    visible: player !== null
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (root.player && root.player.isPlaying) ? "\uf001" : "\uf04c"
            color: hov.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent
            font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 170)
            elide: Text.ElideRight
            text: root.player ? (root.player.trackTitle + (root.player.trackArtist ? " · " + root.player.trackArtist : "")) : ""
            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
    }
    MouseArea {
        id: hov
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("media")
        onWheel: (w) => {
            if (!root.player) return
            if (w.angleDelta.y > 0) root.player.next()
            else root.player.previous()
        }
    }
}