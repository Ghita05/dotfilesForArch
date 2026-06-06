import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../.." as Root

PanelWindow {
    id: launcher

    // ── SET YOUR PHOTO HERE (absolute path). Leave "" for a person glyph. ──
    property string avatarPath: "/home/ghita/Downloads/menupfp.jpeg"

    property bool open: false
    property bool _show: false
    property int selectedIndex: 0
    property var results: filterApps(searchField.text)

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    visible: _show

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }
    onOpenChanged: {
        if (open) _show = true
        else closeTimer.restart()
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        if (open) { searchField.text = ""; selectedIndex = 0; searchField.forceActiveFocus() }
    }
    Timer { id: closeTimer; interval: 380; onTriggered: if (!launcher.open) launcher._show = false }

    function toggle() { open = !open }
    function hide() { open = false }

    Process { id: act }
    function run(cmd) { if (act.running) act.running = false; act.command = ["sh", "-c", cmd]; act.running = true; hide() }

    function filterApps(query) {
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (!query || query.length === 0) {
            return all.slice().sort((a, b) => {
                const fb = Root.PersistState.frecency(b.id), fa = Root.PersistState.frecency(a.id)
                if (fb !== fa) return fb - fa
                return a.name.localeCompare(b.name)
            })
        }
        const q = query.toLowerCase()
        return all
            .map(a => ({ app: a, idx: a.name.toLowerCase().indexOf(q), fr: Root.PersistState.frecency(a.id) }))
            .filter(x => x.idx !== -1)
            .sort((a, b) => (a.idx - b.idx) || (b.fr - a.fr) || a.app.name.localeCompare(b.app.name))
            .map(x => x.app)
    }
    function launch(app) { if (!app) return; Root.PersistState.recordLaunch(app.id); app.execute(); hide() }

    readonly property int cols: Math.max(1, Math.floor(grid.width / grid.cellWidth))
    function move(d) { selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + d)); grid.positionViewAtIndex(selectedIndex, GridView.Contain) }

    readonly property var upcoming: ((Root.PersistState.reminders || [])
        .filter(r => r.when > Date.now())
        .sort((a, b) => a.when - b.when))
    function relTime(ms) {
        const d = ms - Date.now()
        if (d <= 0) return "now"
        const m = Math.round(d / 60000)
        if (m < 60) return "in " + m + "m"
        const h = Math.floor(m / 60), rm = m % 60
        if (h < 24) return "in " + h + "h" + (rm ? " " + rm + "m" : "")
        return "in " + Math.floor(h / 24) + "d"
    }

    // ── media (all players, swipeable) ──
    readonly property var mplayers: Mpris.players ? Mpris.players.values : []
    property int mSel: 0
    readonly property var mp: mplayers.length ? mplayers[Math.min(mSel, mplayers.length - 1)] : null
    readonly property bool mPlaying: mp && mp.playbackState === MprisPlaybackState.Playing
    function cycleMedia(d) { const n = mplayers.length; if (n <= 1) return; mSel = (mSel + d + n) % n; mPos = 0 }
    property real mPos: 0
    readonly property real mLen: mp && mp.length ? mp.length : 0
    Timer { interval: 500; running: launcher._show && launcher.mp; repeat: true; onTriggered: if (launcher.mp) launcher.mPos = launcher.mp.position }
    function fmt(s) { s = Math.max(0, Math.floor(s)); const m = Math.floor(s / 60), ss = s % 60; return m + ":" + (ss < 10 ? "0" : "") + ss }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function open(): void { launcher.open = true }
        function close(): void { launcher.hide() }
    }

    // fully transparent catcher — wallpaper/windows show clean, no dim, no crop
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
        opacity: launcher.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    component GlassCard: Rectangle {
        id: glass
        property int delay: 0
        radius: 22
        color: Root.Theme.panel
        border.color: Root.Theme.border
        border.width: 1
        clip: true
        opacity: 0
        transformOrigin: Item.Center
        MouseArea { anchors.fill: parent }   // swallow clicks so the card doesn't close the dash
        SequentialAnimation {
            running: launcher.open
            PauseAnimation { duration: glass.delay }
            ParallelAnimation {
                NumberAnimation { target: glass; property: "opacity"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
                NumberAnimation { target: glass; property: "scale";   from: 0.97; to: 1; duration: 460; easing.type: Easing.OutCubic }
            }
        }
    }

    Item {
        id: dash
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1240)
        height: Math.min(parent.height - 80, 680)

        // whole-dashboard glide+fade for a smooth, calm entrance
        opacity: launcher.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: launcher.open ? 0 : 28
            Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
        }

        // ===== LEFT: app grid =====
        GlassCard {
            id: appCard
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 500
            delay: 40

            Text {
                id: appHeader
                anchors { left: parent.left; top: parent.top; leftMargin: 26; topMargin: 22 }
                text: "Applications"
                color: Root.Theme.text
                font.family: Root.Theme.fontFamily; font.pixelSize: 17; font.weight: Font.Medium
            }
            Rectangle {
                id: searchWrap
                anchors { left: parent.left; right: parent.right; top: appHeader.bottom; leftMargin: 22; rightMargin: 22; topMargin: 14 }
                height: 44; radius: 12
                color: Root.Theme.surfaceVeryGlass
                border.color: searchField.activeFocus ? Root.Theme.selectionStrong : Root.Theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text { id: sIcon; anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "\uf002"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 13 }
                TextField {
                    id: searchField
                    anchors { left: sIcon.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                    placeholderText: "Search applications…"
                    color: Root.Theme.text; placeholderTextColor: Root.Theme.textDim
                    font.family: Root.Theme.fontFamily; font.pixelSize: 14
                    background: null
                    Keys.onPressed: (e) => {
                        if (e.key === Qt.Key_Escape) { launcher.hide(); e.accepted = true }
                        else if (e.key === Qt.Key_Down) { launcher.move(launcher.cols); e.accepted = true }
                        else if (e.key === Qt.Key_Up) { launcher.move(-launcher.cols); e.accepted = true }
                        else if (e.key === Qt.Key_Right) { launcher.move(1); e.accepted = true }
                        else if (e.key === Qt.Key_Left) { launcher.move(-1); e.accepted = true }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { launcher.launch(launcher.results[launcher.selectedIndex]); e.accepted = true }
                    }
                    onTextChanged: launcher.selectedIndex = 0
                }
            }
            GridView {
                id: grid
                anchors { left: parent.left; right: parent.right; top: searchWrap.bottom; bottom: parent.bottom; leftMargin: 14; rightMargin: 6; topMargin: 12; bottomMargin: 14 }
                clip: true
                cellWidth: 152; cellHeight: 110
                model: launcher.results
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 800
                populate: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 } }
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle {
                        id: tile
                        anchors.fill: parent; anchors.margins: 6
                        radius: 15
                        property bool selected: cell.index === launcher.selectedIndex
                        color: selected ? Root.Theme.selection : (tHov.containsMouse ? Root.Theme.surfaceGlassHi : "transparent")
                        border.color: selected ? Root.Theme.selectionStrong : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        transform: Scale {
                            origin.x: tile.width / 2; origin.y: tile.height / 2
                            xScale: tHov.containsMouse ? 1.07 : 1
                            yScale: tHov.containsMouse ? 1.07 : 1
                            Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Image { anchors.horizontalCenter: parent.horizontalCenter; width: 46; height: 46; sourceSize.width: 46; sourceSize.height: 46; source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable"); fillMode: Image.PreserveAspectFit }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; width: tile.width - 16; horizontalAlignment: Text.AlignHCenter; text: cell.modelData.name; color: tile.selected ? Root.Theme.text : Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap }
                        }
                        Text { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8; visible: searchField.text.length === 0 && Root.PersistState.frecency(cell.modelData.id) > 0; text: "\uf005"; color: Root.Theme.accentSoft; font.family: Root.Theme.fontFamily; font.pixelSize: 9 }
                        MouseArea { id: tHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: launcher.selectedIndex = cell.index; onClicked: launcher.launch(cell.modelData) }
                    }
                }
            }
            Text { anchors.centerIn: grid; visible: launcher.results.length === 0; text: "No matches"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 13 }
        }

        // ===== RIGHT column =====
        Item {
            id: rightCol
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 300
            GlassCard {
                id: powerCard
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 250
                delay: 120
                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                    component PowerTile: Rectangle {
                        id: pt
                        property string glyph
                        property string label
                        property string cmd
                        property color tint: Root.Theme.accentSoft
                        width: parent.width; height: 46; radius: 13
                        color: ptHov.containsMouse ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
                        border.color: ptHov.containsMouse ? Root.Theme.selectionStrong : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                            Text { anchors.verticalCenter: parent.verticalCenter; text: pt.glyph; color: ptHov.containsMouse ? Root.Theme.text : pt.tint; font.family: Root.Theme.fontFamily; font.pixelSize: 16 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: pt.label; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 13 }
                        }
                        MouseArea { id: ptHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: launcher.run(pt.cmd) }
                    }
                    PowerTile { glyph: "\uf023"; label: "Lock";     cmd: "hyprlock";              tint: Root.Theme.accentSoft }
                    PowerTile { glyph: "\uf186"; label: "Sleep";    cmd: "loginctl lock-session"; tint: Root.Theme.accentSoft }
                    PowerTile { glyph: "\uf021"; label: "Reboot";   cmd: "systemctl reboot";      tint: Root.Theme.warn }
                    PowerTile { glyph: "\uf011"; label: "Shutdown"; cmd: "systemctl poweroff";    tint: Root.Theme.crit }
                }
            }
            GlassCard {
                id: remCard
                anchors { left: parent.left; right: parent.right; top: powerCard.bottom; bottom: parent.bottom; topMargin: 16 }
                delay: 160
                Text {
                    id: remHeader
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.topMargin: 16
                    text: "\uf0f3   Reminders"
                    color: Root.Theme.text
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                ListView {
                    anchors { left: parent.left; right: parent.right; top: remHeader.bottom; bottom: parent.bottom; margins: 14; topMargin: 12 }
                    clip: true; spacing: 6
                    model: launcher.upcoming
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: 44; radius: 11
                        color: Root.Theme.surfaceVeryGlass
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: delBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: modelData.text
                                color: Root.Theme.text
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: launcher.relTime(modelData.when)
                                color: Root.Theme.accentSoft
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                        Text {
                            id: delBtn
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            text: "\uf00d"; color: dHov.containsMouse ? Root.Theme.crit : Root.Theme.textDim
                            font.family: Root.Theme.fontFamily; font.pixelSize: 12
                            MouseArea { id: dHov; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Root.PersistState.removeReminder(modelData.id) }
                        }
                    }
                }
                Text { anchors.centerIn: parent; visible: launcher.upcoming.length === 0; text: "No upcoming reminders"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
            }
        }

        // ===== CENTER column =====
        Item {
            id: centerCol
            anchors { left: appCard.right; right: rightCol.left; top: parent.top; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }

            GlassCard {
                id: clockCard
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 320
                delay: 80
                Column {
                    anchors.centerIn: parent; spacing: 14
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clockTick.now, "HH:mm"); color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 64; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clockTick.now, "dddd, d MMMM"); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 14 }
                    ClippingRectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 92; height: 92; radius: width / 2
                        color: Root.Theme.surfaceVeryGlass; border.color: Root.Theme.border; border.width: 1
                        Image { id: avatarImg; anchors.fill: parent; source: launcher.avatarPath !== "" ? "file://" + launcher.avatarPath : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                        Text { anchors.centerIn: parent; visible: avatarImg.status !== Image.Ready; text: "\uf007"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 34 }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 7
                        Repeater {
                            model: 7
                            delegate: Rectangle { required property int index; width: 6; height: 6; radius: 3; color: Root.Theme.accentSoft; opacity: 0.35 + 0.4 * Math.abs(Math.sin(dotPhase.v + index)) }
                        }
                    }
                }
                QtObject { id: dotPhase; property real v: 0 }
                Timer { interval: 600; running: launcher._show; repeat: true; onTriggered: dotPhase.v += 0.6 }
            }
            Item { id: clockTick; property var now: new Date(); Timer { interval: 1000; running: launcher._show; repeat: true; onTriggered: clockTick.now = new Date() } }

            // ── media: popup-style (circular art + spectrum ring), swipeable, click-to-raise ──
            GlassCard {
                id: mediaCard
                anchors { left: parent.left; right: parent.right; top: clockCard.bottom; bottom: parent.bottom; topMargin: 16 }
                delay: 110

                Text { anchors.centerIn: parent; visible: !launcher.mp; text: "Nothing playing"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 13 }

                Item {
                    anchors.fill: parent
                    anchors.margins: 16
                    visible: launcher.mp

                    Item {
                        id: ringWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 150; height: 150

                        Canvas {
                            id: ring
                            anchors.fill: parent
                            property real phase: 0
                            onPaint: {
                                const ctx = getContext("2d"); ctx.reset()
                                const cx = width / 2, cy = height / 2, inner = 58, bars = 56
                                for (let i = 0; i < bars; i++) {
                                    const a = (i / bars) * Math.PI * 2
                                    const amp = launcher.mPlaying ? (6 + 11 * Math.abs(Math.sin(phase * 0.06 + i * 0.5))) : 3
                                    ctx.beginPath()
                                    ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                                    ctx.lineTo(cx + Math.cos(a) * (inner + amp), cy + Math.sin(a) * (inner + amp))
                                    ctx.lineWidth = 2; ctx.strokeStyle = "rgba(138,147,163,0.5)"; ctx.stroke()
                                }
                            }
                        }
                        Timer { interval: 90; running: launcher._show && launcher.mPlaying; repeat: true; onTriggered: { ring.phase++; ring.requestPaint() } }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 100; height: 100; radius: width / 2
                            color: Root.Theme.surfaceVeryGlass; border.color: Root.Theme.border; border.width: 1
                            Image { anchors.fill: parent; source: launcher.mp && launcher.mp.trackArtUrl ? launcher.mp.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                            Text { anchors.centerIn: parent; visible: !launcher.mp || !launcher.mp.trackArtUrl; text: "\uf001"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 28 }
                        }

                        // swipe = switch player; click = raise its window
                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            property real startX: 0
                            property real startY: 0
                            property bool dragging: false
                            property bool fired: false
                            property real accum: 0
                            onPressed: (m) => { startX = m.x; startY = m.y; dragging = true; fired = false }
                            onPositionChanged: (m) => {
                                if (!dragging || fired) return
                                const dx = m.x - startX, dy = m.y - startY
                                if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy) * 2 && launcher.mplayers.length > 1) {
                                    launcher.cycleMedia(dx > 0 ? -1 : 1); fired = true
                                }
                            }
                            onReleased: { if (!fired && launcher.mp && launcher.mp.canRaise) launcher.mp.raise(); dragging = false; fired = false }
                            onWheel: (w) => { accum = accum * 0.6 + w.angleDelta.x; if (Math.abs(accum) > 300) { launcher.cycleMedia(accum > 0 ? -1 : 1); accum = 0 } }
                        }
                    }

                    Text {
                        id: dTitle
                        anchors { left: parent.left; right: parent.right; top: ringWrap.bottom; topMargin: 8 }
                        horizontalAlignment: Text.AlignHCenter
                        text: launcher.mp ? launcher.mp.trackTitle : ""
                        color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Medium; elide: Text.ElideRight
                    }
                    Text {
                        id: dArtist
                        anchors { left: parent.left; right: parent.right; top: dTitle.bottom; topMargin: 2 }
                        horizontalAlignment: Text.AlignHCenter
                        text: launcher.mp ? (launcher.mp.trackArtist + (launcher.mp.identity ? "  ·  " + launcher.mp.identity : "")) : ""
                        color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight
                    }

                    Item {
                        id: dScrub
                        anchors { left: parent.left; right: parent.right; top: dArtist.bottom; topMargin: 14 }
                        height: 16
                        readonly property real frac: launcher.mLen > 0 ? Math.max(0, Math.min(1, launcher.mPos / launcher.mLen)) : 0
                        Rectangle {
                            id: dTrk
                            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            height: 5; radius: 3; color: Root.Theme.surfaceVeryGlass
                            Rectangle { width: dTrk.width * dScrub.frac; height: parent.height; radius: parent.radius; color: Root.Theme.accent }
                            Rectangle { x: dTrk.width * dScrub.frac - 6; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Root.Theme.accentSoft }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            function seek(mx) { if (launcher.mp && launcher.mp.canSeek && launcher.mLen > 0) { const f = Math.max(0, Math.min(1, mx / width)); launcher.mp.position = f * launcher.mLen; launcher.mPos = f * launcher.mLen } }
                            onPressed: (m) => seek(m.x)
                            onPositionChanged: (m) => { if (pressed) seek(m.x) }
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.top: dScrub.bottom
                        anchors.topMargin: 4
                        text: launcher.fmt(launcher.mPos)
                        color: Root.Theme.textDim
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.top: dScrub.bottom
                        anchors.topMargin: 4
                        text: launcher.fmt(launcher.mLen)
                        color: Root.Theme.textDim
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                        spacing: 30
                        Text { text: "\uf048"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 17
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.previous() } }
                        Text { text: launcher.mPlaying ? "\uf04c" : "\uf04b"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 24
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.togglePlaying() } }
                        Text { text: "\uf051"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 17
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.next() } }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                        spacing: 6
                        visible: launcher.mplayers.length > 1
                        Repeater {
                            model: launcher.mplayers.length
                            delegate: Rectangle {
                                required property int index
                                width: 6; height: 6; radius: 3
                                color: index === launcher.mSel ? Root.Theme.accent : Root.Theme.textDim
                                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: launcher.mSel = index }
                            }
                        }
                    }
                }
            }
        }
    }
}