import QtQuick
import Quickshell.Services.Mpris
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "media"
    property int playerIdx: 0
    readonly property var players: Mpris.players.values
    readonly property var player: (players.length > playerIdx && playerIdx >= 0) ? players[playerIdx] : (players.length ? players[0] : null)
    property real posNow: 0
    readonly property real prog: (player && player.length > 0) ? Math.max(0, Math.min(1, posNow / player.length)) : 0

    function fmt(us) { if (!us || us < 0) return "0:00"; const s = Math.floor(us / 1000000); const m = Math.floor(s / 60); const r = s % 60; return m + ":" + (r < 10 ? "0" : "") + r }
    function srcName() {
        if (!player) return ""
        return player.identity || player.desktopEntry || "Unknown"
    }
    function cyclePlayer(dir) {
        if (players.length < 2) return
        playerIdx = (playerIdx + dir + players.length) % players.length
        posNow = player ? player.position : 0
    }

    implicitWidth: 380
    implicitHeight: card.implicitHeight
    visible: shown && player !== null

    Timer { running: root.visible; interval: 1000; repeat: true; onTriggered: root.posNow = root.player ? root.player.position : 0 }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 32      // size to content — no more clipping
        radius: 18
        color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.9
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

        // swipe anywhere on the card to change player
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            property real startX: 0
            property real startY: 0
            property bool dragging: false
            property bool fired: false
            property real accum: 0

            onPressed: (m) => { startX = m.x; startY = m.y; dragging = true; fired = false }
            onReleased: { dragging = false; fired = false }
            onPositionChanged: (m) => {
                if (!dragging || fired) return
                const dx = m.x - startX
                const dy = m.y - startY
                // must be a clear horizontal intent: far enough + mostly sideways
                if (Math.abs(dx) > 110 && Math.abs(dx) > Math.abs(dy) * 2) {
                    root.cyclePlayer(dx > 0 ? -1 : 1)
                    fired = true
                }
            }
            onWheel: (w) => {
                accum = (accum * 0.6) + w.angleDelta.x   // decay old motion
                if (Math.abs(accum) > 320) { root.cyclePlayer(accum > 0 ? -1 : 1); accum = 0 }
            }
        }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 12

            Row {
                width: parent.width; spacing: 14

                Rectangle {
                    width: 84; height: 84; radius: 12; clip: true
                    color: Root.Theme.surfaceVeryGlass; border.color: Root.Theme.border; border.width: 1
                    Image { anchors.fill: parent; source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                    Text { anchors.centerIn: parent; visible: !(root.player && root.player.trackArtUrl); text: "\uf001"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 28 }
                }

                Column {
                    width: parent.width - 98
                    spacing: 3
                    Text { width: parent.width; elide: Text.ElideRight; text: root.player ? root.player.trackTitle : ""; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
                    Text { width: parent.width; elide: Text.ElideRight; text: root.player ? root.player.trackArtist : ""; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
                    Text { width: parent.width; elide: Text.ElideRight; visible: text.length > 0; text: root.player && root.player.trackAlbum ? root.player.trackAlbum : ""; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                    // "playing from <source>"
                    Text { width: parent.width; elide: Text.ElideRight; text: "\uf001  " + root.srcName(); color: Root.Theme.accentSoft; font.family: Root.Theme.fontFamily; font.pixelSize: 10; topPadding: 2 }
                }
            }

            // seek bar
            Item {
                width: parent.width; height: 14
                Rectangle {
                    id: seek
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    height: 5; radius: 3; color: Root.Theme.surfaceVeryGlass
                    Rectangle { width: seek.width * root.prog; height: parent.height; radius: parent.radius; color: Root.Theme.accent; Behavior on width { NumberAnimation { duration: 200 } } }
                    Rectangle { x: seek.width * root.prog - width / 2; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Root.Theme.accentSoft }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.player && root.player.length > 0 && root.player.canSeek
                    function seekTo(mx) { if (root.player && root.player.length > 0) { const f = Math.max(0, Math.min(1, mx / width)); root.player.position = f * root.player.length; root.posNow = root.player.position } }
                    onPressed: (m) => seekTo(m.x)
                    onPositionChanged: (m) => { if (pressed) seekTo(m.x) }
                }
            }
            Item {
                width: parent.width; height: 12
                Text { anchors.left: parent.left; text: root.fmt(root.posNow); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                Text { anchors.right: parent.right; text: root.player ? root.fmt(root.player.length) : "0:00"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
            }

            // controls + player switch (arrows show only with >1 player)
            Item {
                width: parent.width; height: 26
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    visible: root.players.length > 1
                    text: "\uf053"; color: lHov.containsMouse ? Root.Theme.accentSoft : Root.Theme.textDim
                    font.family: Root.Theme.fontFamily; font.pixelSize: 13
                    MouseArea { id: lHov; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cyclePlayer(-1) }
                }
                Row {
                    anchors.centerIn: parent; spacing: 26
                    component Ctl: Text {
                        property string glyph
                        property real sz: 18
                        signal activated()
                        text: glyph; color: cHov.containsMouse ? Root.Theme.accentSoft : Root.Theme.text
                        font.family: Root.Theme.fontFamily; font.pixelSize: sz
                        MouseArea { id: cHov; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
                    }
                    Ctl { glyph: "\uf048"; onActivated: if (root.player) root.player.previous() }
                    Ctl { glyph: (root.player && root.player.isPlaying) ? "\uf04c" : "\uf04b"; sz: 22; onActivated: if (root.player) { if (root.player.isPlaying) root.player.pause(); else root.player.play() } }
                    Ctl { glyph: "\uf051"; onActivated: if (root.player) root.player.next() }
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    visible: root.players.length > 1
                    text: "\uf054"; color: rHov.containsMouse ? Root.Theme.accentSoft : Root.Theme.textDim
                    font.family: Root.Theme.fontFamily; font.pixelSize: 13
                    MouseArea { id: rHov; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cyclePlayer(1) }
                }
                // tiny page dots
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: 2
                    spacing: 5; visible: root.players.length > 1
                    Repeater {
                        model: root.players.length
                        delegate: Rectangle { required property int index; width: 6; height: 6; radius: 3; color: index === root.playerIdx ? Root.Theme.accent : Root.Theme.surfaceGlassHi }
                    }
                }
            }
        }
    }
}