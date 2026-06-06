import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "media"
    implicitWidth: 360
    implicitHeight: card.height
    visible: shown

    property string tab: "media"
    property int sel: 0
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var mp: players.length ? players[Math.min(sel, players.length - 1)] : null
    readonly property bool playing: mp && mp.playbackState === MprisPlaybackState.Playing

    property real pos: 0
    readonly property real len: mp && mp.length ? mp.length : 0
    Timer { interval: 500; running: root.shown && root.mp; repeat: true; onTriggered: if (root.mp) root.pos = root.mp.position }

    function fmt(s) { s = Math.max(0, Math.floor(s)); const m = Math.floor(s / 60), ss = s % 60; return m + ":" + (ss < 10 ? "0" : "") + ss }

    // performance probe (only while that tab is open)
    property string perf: "—"
    Process {
        id: perfProc
        command: ["sh", "-c", "read a b c rest </proc/loadavg; t=$(awk '/MemTotal/{print $2}' /proc/meminfo); av=$(awk '/MemAvailable/{print $2}' /proc/meminfo); echo \"$a|$(( (t-av)*100/t ))\""]
        stdout: StdioCollector { onStreamFinished: root.perf = text.trim() }
    }
    Timer { interval: 2000; running: root.shown && root.tab === "performance"; repeat: true; triggeredOnStart: true; onTriggered: perfProc.running = true }
    readonly property var dev: UPower.displayDevice
    readonly property int battPct: (dev && dev.ready) ? Math.round(dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0

    Rectangle {
        id: card
        width: parent.width
        height: root.tab === "media" ? 408 : 248
        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        radius: 20
        color: Root.Theme.panel
        border.color: Root.Theme.border
        border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        MouseArea { anchors.fill: parent }

        // ── tab header ──
        Item {
            id: tabs
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            height: 30
            property var keys: ["dashboard", "media", "performance"]
            property var labels: ["Dashboard", "Media", "Performance"]
            property int active: keys.indexOf(root.tab)
            readonly property real seg: width / 3

            Rectangle {
                width: tabs.seg - 8; height: 26
                x: tabs.active * tabs.seg + 4
                anchors.verticalCenter: parent.verticalCenter
                radius: 9
                color: Root.Theme.selection
                border.color: Root.Theme.selectionStrong; border.width: 1
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }
            Row {
                anchors.fill: parent
                Repeater {
                    model: 3
                    delegate: Item {
                        required property int index
                        width: tabs.seg; height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: tabs.labels[index]
                            color: index === tabs.active ? Root.Theme.text : Root.Theme.textDim
                            font.family: Root.Theme.fontFamily; font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.tab = tabs.keys[index] }
                    }
                }
            }
        }

        // ── MEDIA tab ──
        Item {
            anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; margins: 14 }
            visible: root.tab === "media"
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Item {
                id: artWrap
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 8
                width: 200; height: 200

                Canvas {
                    id: ring
                    anchors.fill: parent
                    property real phase: 0
                    onPaint: {
                        const ctx = getContext("2d"); ctx.reset()
                        const cx = width / 2, cy = height / 2, inner = 78, bars = 64
                        for (let i = 0; i < bars; i++) {
                            const a = (i / bars) * Math.PI * 2
                            const amp = root.playing ? (7 + 13 * Math.abs(Math.sin(phase * 0.06 + i * 0.5))) : 4
                            ctx.beginPath()
                            ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                            ctx.lineTo(cx + Math.cos(a) * (inner + amp), cy + Math.sin(a) * (inner + amp))
                            ctx.lineWidth = 2; ctx.strokeStyle = "rgba(138,147,163,0.5)"; ctx.stroke()
                        }
                    }
                }
                Timer { interval: 90; running: root.shown && root.playing && root.tab === "media"; repeat: true; onTriggered: { ring.phase++; ring.requestPaint() } }

                ClippingRectangle {
                    anchors.centerIn: parent
                    width: 132; height: 132; radius: width / 2
                    color: Root.Theme.surfaceVeryGlass
                    border.color: Root.Theme.border; border.width: 1
                    Image { anchors.fill: parent; source: root.mp && root.mp.trackArtUrl ? root.mp.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                    Text { anchors.centerIn: parent; visible: !root.mp || !root.mp.trackArtUrl; text: "\uf001"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 34 }
                }
            }

            Text {
                id: mTitle
                anchors { left: parent.left; right: parent.right; top: artWrap.bottom; topMargin: 8 }
                horizontalAlignment: Text.AlignHCenter
                text: root.mp ? root.mp.trackTitle : "Nothing playing"
                color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight
            }
            Text {
                id: mArtist
                anchors { left: parent.left; right: parent.right; top: mTitle.bottom; topMargin: 2 }
                horizontalAlignment: Text.AlignHCenter
                text: root.mp ? (root.mp.trackArtist + (root.mp.identity ? "  ·  " + root.mp.identity : "")) : ""
                color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight
            }

            // scrubber
            Item {
                id: scrub
                anchors { left: parent.left; right: parent.right; top: mArtist.bottom; topMargin: 14 }
                height: 16
                readonly property real frac: root.len > 0 ? Math.max(0, Math.min(1, root.pos / root.len)) : 0
                Rectangle {
                    id: trk
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    height: 5; radius: 3; color: Root.Theme.surfaceVeryGlass
                    Rectangle { width: trk.width * scrub.frac; height: parent.height; radius: parent.radius; color: Root.Theme.accent }
                    Rectangle { x: trk.width * scrub.frac - 6; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Root.Theme.accentSoft }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    function seek(mx) { if (root.mp && root.mp.canSeek && root.len > 0) { const f = Math.max(0, Math.min(1, mx / width)); root.mp.position = f * root.len; root.pos = f * root.len } }
                    onPressed: (m) => seek(m.x)
                    onPositionChanged: (m) => { if (pressed) seek(m.x) }
                }
            }
            Row {
                anchors { left: parent.left; right: parent.right; top: scrub.bottom; topMargin: 4 }
                Text { text: root.fmt(root.pos); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text { anchors.right: parent.right; text: root.fmt(root.len); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
            }

            // transport
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                spacing: 26
                Text { text: "\uf048"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 17
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mp) root.mp.previous() } }
                Text { text: root.playing ? "\uf04c" : "\uf04b"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 24
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mp) root.mp.togglePlaying() } }
                Text { text: "\uf051"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 17
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mp) root.mp.next() } }
            }

            // player dots (only if >1 source)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: -8
                spacing: 6
                visible: root.players.length > 1
                Repeater {
                    model: root.players.length
                    delegate: Rectangle {
                        required property int index
                        width: 6; height: 6; radius: 3
                        color: index === root.sel ? Root.Theme.accent : Root.Theme.textDim
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.sel = index }
                    }
                }
            }
        }

        // ── DASHBOARD tab ──
        Column {
            anchors { left: parent.left; right: parent.right; top: tabs.bottom; margins: 18; topMargin: 16 }
            visible: root.tab === "dashboard"
            spacing: 6
            Text { text: Qt.formatDateTime(dTick.now, "HH:mm"); color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 40; font.weight: Font.Bold }
            Text { text: Qt.formatDateTime(dTick.now, "dddd, d MMMM"); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
            Item { width: 1; height: 8 }
            Text { text: "\uf0f3   Next up"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
            Repeater {
                model: ((Root.PersistState.reminders || []).filter(r => r.when > Date.now()).sort((a, b) => a.when - b.when)).slice(0, 3)
                delegate: Text {
                    required property var modelData
                    text: "·  " + modelData.text
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: card.width - 36
                }
            }
        }
        Item { id: dTick; property var now: new Date(); Timer { interval: 1000; running: root.shown && root.tab === "dashboard"; repeat: true; onTriggered: dTick.now = new Date() } }

        // ── PERFORMANCE tab ──
        Column {
            anchors { left: parent.left; right: parent.right; top: tabs.bottom; margins: 18; topMargin: 18 }
            visible: root.tab === "performance"
            spacing: 14

            component Stat: Item {
                property string label
                property real frac
                property string value
                property color tint: Root.Theme.accent
                width: parent.width; height: 30
                Text { anchors.left: parent.left; text: label; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                Text { anchors.right: parent.right; text: value; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 5; radius: 3; color: Root.Theme.surfaceVeryGlass
                    Rectangle { width: parent.width * Math.max(0, Math.min(1, frac)); height: parent.height; radius: parent.radius; color: tint; Behavior on width { NumberAnimation { duration: 300 } } }
                }
            }

            Stat {
                label: "Load (1m)"
                value: root.perf.split("|")[0] || "—"
                frac: Math.min(1, (parseFloat(root.perf.split("|")[0]) || 0) / 4)
            }
            Stat {
                label: "Memory"
                value: (root.perf.split("|")[1] || "0") + "%"
                frac: (parseFloat(root.perf.split("|")[1]) || 0) / 100
                tint: Root.Theme.warn
            }
            Stat {
                label: "Battery"
                value: root.battPct + "%"
                frac: root.battPct / 100
                tint: root.battPct <= 15 ? Root.Theme.crit : Root.Theme.good
            }
        }
    }
}