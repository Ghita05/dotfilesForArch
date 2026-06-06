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

    // ── SET YOUR PHOTO HERE (absolute path)
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

    // upcoming reminders (read from PersistState)
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

    // media
    readonly property var mplayers: Mpris.players ? Mpris.players.values : []
    readonly property var mp: mplayers.length ? mplayers[0] : null
    readonly property bool mPlaying: mp && mp.playbackState === MprisPlaybackState.Playing

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function open(): void { launcher.open = true }
        function close(): void { launcher.hide() }
    }

    // near-clear scrim — wallpaper stays visible, only a soft global dim
    Rectangle {
        anchors.fill: parent
        color: "#7305060a"
        opacity: launcher.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240 } }
        MouseArea { anchors.fill: parent; onClicked: launcher.hide() }
    }

    // ── reusable glass card with a staggered bloom ──
    component GlassCard: Rectangle {
        id: glasscard
        property int delay: 0
        radius: 22
        color: Root.Theme.panel
        border.color: Root.Theme.border
        border.width: 1
        clip: true
        opacity: 0
        transformOrigin: Item.Center
        SequentialAnimation {
            running: launcher.open
            PauseAnimation { duration: glasscard.delay }
            ParallelAnimation {
                NumberAnimation { target: glasscard; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: glasscard; property: "scale";   from: 0.95; to: 1; duration: 440; easing.type: Easing.OutBack; easing.overshoot: 1.22 }
            }
        }
    }

    // ── dashboard container ──
    Item {
        id: dash
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1240)
        height: Math.min(parent.height - 80, 680)

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
                Text {
                    id: sIcon
                    anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 13
                }
                TextField {
                    id: searchField
                    anchors { left: sIcon.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                    placeholderText: "Search applications…"
                    color: Root.Theme.text
                    placeholderTextColor: Root.Theme.textDim
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
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 46; height: 46; sourceSize.width: 46; sourceSize.height: 46
                                source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: tile.width - 16; horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                color: tile.selected ? Root.Theme.text : Root.Theme.textGlassy
                                font.family: Root.Theme.fontFamily; font.pixelSize: 11
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                            }
                        }
                        Text {
                            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                            visible: searchField.text.length === 0 && Root.PersistState.frecency(cell.modelData.id) > 0
                            text: "\uf005"; color: Root.Theme.accentSoft; font.family: Root.Theme.fontFamily; font.pixelSize: 9
                        }
                        MouseArea {
                            id: tHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: launcher.selectedIndex = cell.index
                            onClicked: launcher.launch(cell.modelData)
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: grid
                visible: launcher.results.length === 0
                text: "No matches"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 13
            }
        }

        // ===== RIGHT column =====
        Item {
            id: rightCol
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 300

            // power tiles
            GlassCard {
                id: powerCard
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 250
                delay: 120

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

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
                            anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
                            spacing: 14
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

            // reminders
            GlassCard {
                id: remCard
                anchors { left: parent.left; right: parent.right; top: powerCard.bottom; bottom: parent.bottom; topMargin: 16 }
                delay: 160

                Text {
                    id: remHeader
                    anchors { left: parent.left; top: parent.top; leftMargin: 18; topMargin: 16 }
                    text: "\uf0f3   Reminders"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium
                }
                ListView {
                    anchors { left: parent.left; right: parent.right; top: remHeader.bottom; bottom: parent.bottom; margins: 14; topMargin: 12 }
                    clip: true; spacing: 6
                    model: launcher.upcoming
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: 44; radius: 11
                        color: Root.Theme.surfaceVeryGlass
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 12; anchors.right: delBtn.left; anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text { text: modelData.text; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight; width: remCard.width - 90 }
                                Text { text: launcher.relTime(modelData.when); color: Root.Theme.accentSoft; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                            }
                        }
                        Text {
                            id: delBtn
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            text: "\uf00d"; color: dHov.containsMouse ? Root.Theme.crit : Root.Theme.textDim
                            font.family: Root.Theme.fontFamily; font.pixelSize: 12
                            MouseArea { id: dHov; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Root.PersistState.removeReminder(modelData.id) }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: launcher.upcoming.length === 0
                    text: "No upcoming reminders"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
            }
        }

        // ===== CENTER column =====
        Item {
            id: centerCol
            anchors { left: appCard.right; right: rightCol.left; top: parent.top; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }

            // clock + avatar hero
            GlassCard {
                id: clockCard
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 320
                delay: 80

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clockTick.now, "HH:mm")
                        color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 64; font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clockTick.now, "dddd, d MMMM")
                        color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 14
                    }
                    ClippingRectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 92; height: 92; radius: width / 2
                        color: Root.Theme.surfaceVeryGlass
                        border.color: Root.Theme.border; border.width: 1
                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            source: launcher.avatarPath !== "" ? "file://" + launcher.avatarPath : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: avatarImg.status !== Image.Ready
                            text: "\uf007"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 34
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 7
                        Repeater {
                            model: 7
                            delegate: Rectangle {
                                required property int index
                                width: 6; height: 6; radius: 3
                                color: Root.Theme.accentSoft
                                opacity: 0.35 + 0.4 * Math.abs(Math.sin(dotPhase.v + index))
                            }
                        }
                    }
                }
                QtObject { id: dotPhase; property real v: 0 }
                Timer { interval: 600; running: launcher._show; repeat: true; onTriggered: dotPhase.v += 0.6 }
            }
            Item { id: clockTick; property var now: new Date(); Timer { interval: 1000; running: launcher._show; repeat: true; onTriggered: clockTick.now = new Date() } }

            // now-playing strip
            GlassCard {
                id: mediaCard
                anchors { left: parent.left; right: parent.right; top: clockCard.bottom; bottom: parent.bottom; topMargin: 16 }
                delay: 110

                Item {
                    anchors.fill: parent
                    anchors.margins: 18
                    visible: launcher.mp

                    ClippingRectangle {
                        id: art
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        width: 64; height: 64; radius: 14
                        color: Root.Theme.surfaceVeryGlass
                        Image { anchors.fill: parent; source: launcher.mp && launcher.mp.trackArtUrl ? launcher.mp.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                        Text { anchors.centerIn: parent; visible: !launcher.mp || !launcher.mp.trackArtUrl; text: "\uf001"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 22 }
                    }
                    Column {
                        anchors.left: art.right; anchors.leftMargin: 14; anchors.right: ctrls.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text { text: launcher.mp ? launcher.mp.trackTitle : ""; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                        Text { text: launcher.mp ? launcher.mp.trackArtist : ""; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                    }
                    Row {
                        id: ctrls
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf048"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 15
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.previous() } }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: launcher.mPlaying ? "\uf04c" : "\uf04b"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 20
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.togglePlaying() } }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf051"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 15
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: if (launcher.mp) launcher.mp.next() } }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: !launcher.mp
                    text: "Nothing playing"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                }
            }
        }
    }
}