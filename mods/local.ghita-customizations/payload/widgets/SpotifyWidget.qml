import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Spotify-specific now-playing widget, iOS-Now-Playing style: art bleeds
// to the card edges (the tile's own clip:true + radius does the corner
// rounding, no separate mask shader needed), text sits over the art on a
// gradient scrim, controls are minimal glyphs with no header — Desktop.qml
// skips the header entirely for this widget type and drags the whole card
// instead.
//
// Finds the Spotify MPRIS player directly by dbusName rather than going
// through MprisController's "whichever player is active" concept, so it
// keeps showing Spotify even while some other app is the active player
// elsewhere. No API key — MPRIS is local D-Bus, the same mechanism the
// dashboard's own player already uses.
//
// Perf: audited rather than assumed, since Spotify isn't running on this
// machine to profile live. Position polling was already 1Hz and gated on
// isPlaying (not the bug). Album art WAS bound straight to the remote
// mpris:artUrl in three places — any spurious re-evaluation of the
// upstream `player` binding could have re-triggered an Image network
// fetch. Fixed categorically regardless of how often that actually
// happened: art is downloaded to ~/.cache/ambxst/spotify-art/ exactly
// once per distinct art URL (guarded by lastFetchedUrl, never inside a
// naive property-change handler), and every Image below binds to that
// local cached path, never the remote URL.
Item {
    id: root

    // "small" | "medium" | "large" — set by Desktop.qml from the tile's
    // configured size.
    property string size: "medium"

    readonly property var player: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if ((players[i].dbusName || "").toLowerCase().includes("spotify"))
                return players[i];
        }
        return null;
    }

    readonly property bool hasPlayer: root.player !== null
    readonly property bool isPlaying: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing
    readonly property bool hasArt: root.cachedArtPath.length > 0

    property string cachedArtPath: ""
    property color dominantColor: Styling.srItem("overprimary")
    property string lastFetchedUrl: ""

    // Snapshot of the most recently seen track, kept around after the
    // player disappears so the empty state can show it dimmed instead of
    // a bare "isn't running" glyph in a mostly-empty card — an idle
    // now-playing widget is still a now-playing widget. Never cleared;
    // only overwritten by a genuinely new track.
    property string lastTitle: ""
    property string lastArtist: ""
    property string lastArtPath: ""
    property color lastColor: Styling.srItem("overprimary")

    // hasContent: is there anything at all to show (live or remembered)?
    // hasPlayer already means "live and controllable" — kept separate so
    // the layouts below can show remembered info while still disabling
    // the transport controls that would have nothing to act on.
    readonly property bool hasContent: root.hasPlayer || root.lastTitle.length > 0
    readonly property string displayTitle: root.hasPlayer ? (root.player.trackTitle || "Unknown track") : root.lastTitle
    readonly property string displayArtist: root.hasPlayer ? (root.player.trackArtist || "") : root.lastArtist
    readonly property string displayArtPath: root.hasPlayer ? root.cachedArtPath : root.lastArtPath
    readonly property bool hasDisplayArt: root.displayArtPath.length > 0
    readonly property color displayColor: root.hasPlayer ? root.dominantColor : root.lastColor

    function snapshotLast() {
        if (!root.hasPlayer)
            return;
        const title = root.player.trackTitle || "";
        if (title.length === 0)
            return;
        root.lastTitle = title;
        root.lastArtist = root.player.trackArtist || "";
        if (root.hasArt)
            root.lastArtPath = root.cachedArtPath;
        root.lastColor = root.dominantColor;
    }

    function openSpotify() {
        DesktopService.runInActiveWorkspace("spotify");
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0));
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function togglePlaying() {
        if (root.hasPlayer && root.player.canTogglePlaying)
            root.player.togglePlaying();
    }

    function previous() {
        if (root.hasPlayer && root.player.canGoPrevious)
            root.player.previous();
    }

    function next() {
        if (root.hasPlayer && root.player.canGoNext)
            root.player.next();
    }

    // Fetch + cache art and its average color exactly once per distinct
    // URL. Guarded on lastFetchedUrl so it's a no-op no matter how often
    // this gets called from a re-evaluated binding.
    function ensureArtCached() {
        const url = (root.hasPlayer && root.player.trackArtUrl) || "";
        if (url === root.lastFetchedUrl)
            return;
        root.lastFetchedUrl = url;
        if (!url) {
            root.cachedArtPath = "";
            root.dominantColor = Styling.srItem("overprimary");
            return;
        }
        artFetchProcess.command = ["bash", "-c", "cachedir=\"$HOME/.cache/ambxst/spotify-art\"\nmkdir -p \"$cachedir\"\nkey=$(basename \"$1\" | sed 's/[^A-Za-z0-9._-]/_/g')\n[ -z \"$key\" ] && key=\"art\"\nimgfile=\"$cachedir/$key.jpg\"\nif [ ! -s \"$imgfile\" ]; then\n  curl -sL --max-time 8 \"$1\" -o \"$imgfile.tmp\" && mv \"$imgfile.tmp\" \"$imgfile\" || { rm -f \"$imgfile.tmp\"; exit 1; }\nfi\n[ -s \"$imgfile\" ] || exit 1\ncolor=$(magick \"$imgfile\" -resize 1x1 txt:- 2>/dev/null | grep -oE '#[0-9A-Fa-f]{6}' | head -1)\nfind \"$cachedir\" -type f -mtime +30 -delete 2>/dev/null\necho \"$imgfile\"\necho \"${color:-#888888}\"\n", "_", url];
        artFetchProcess.running = true;
    }

    Process {
        id: artFetchProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 1 && lines[0].length > 0) {
                    root.cachedArtPath = "file://" + lines[0];
                }
                if (lines.length >= 2 && /^#[0-9A-Fa-f]{6}$/.test(lines[1])) {
                    root.dominantColor = lines[1];
                }
                root.snapshotLast();
            }
        }
    }

    onPlayerChanged: {
        root.ensureArtCached();
        root.snapshotLast();
    }
    Component.onCompleted: root.ensureArtCached()

    Connections {
        target: root.player
        function onTrackArtUrlChanged() {
            root.ensureArtCached();
        }
        function onTrackTitleChanged() {
            root.snapshotLast();
        }
    }

    // MPRIS doesn't push position continuously, so it's polled — but only
    // at 1Hz, and only while actually playing (already correct; this was
    // the other suspected cause, ruled out by inspection).
    property bool isSeeking: false

    function syncScrub() {
        if (scrubBar.isDragging || root.isSeeking)
            return;
        scrubBar.value = (root.hasPlayer && root.player.length > 0) ? root.player.position / root.player.length : 0;
    }

    Timer {
        running: root.isPlaying && root.visible
        interval: 1000
        repeat: true
        onTriggered: {
            root.syncScrub();
            root.player && root.player.positionChanged();
        }
    }

    Timer {
        id: seekUnlockTimer
        interval: 1000
        repeat: false
        onTriggered: root.isSeeking = false
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            root.syncScrub();
        }
    }

    // Only the true "never played anything" state — once there's a
    // remembered track, the sized layouts below take over (dimmed) instead
    // of this.
    WidgetEmptyState {
        visible: !root.hasContent
        message: "Nothing played yet"
        iconGlyph: Icons.player
        compact: root.size === "small"

        TapHandler {
            onTapped: root.openSpotify()
        }
    }

    // Full-bleed art background for every size (medium/large draw text and
    // controls on top of this same Image via a scrim; small just needs the
    // play/pause overlay). Uses the last-known track's art, dimmed, when
    // nothing's currently playing — an idle now-playing widget still earns
    // its space instead of going blank.
    Image {
        id: art
        anchors.fill: parent
        source: root.hasDisplayArt ? root.displayArtPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: root.hasContent && root.hasDisplayArt
        opacity: root.hasPlayer ? 1.0 : 0.45
    }

    Rectangle {
        anchors.fill: parent
        visible: root.hasContent && !root.hasDisplayArt
        color: Colors.surfaceVariant
    }

    // Tap-to-launch affordance for the whole card while idle — sits above
    // the art but below the size-specific content below it, so it never
    // steals the tap from a real transport control when one is live.
    TapHandler {
        enabled: root.hasContent && !root.hasPlayer
        onTapped: root.openSpotify()
    }

    // --- Small: play/pause overlay only, no text ---
    Item {
        visible: root.size === "small" && root.hasContent
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.hasPlayer ? 0.2 : 0.4
        }

        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: width / 2
            color: root.displayColor

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (root.hasPlayer && root.isPlaying) ? 0 : 1
                text: root.hasPlayer ? (root.isPlaying ? Icons.pause : Icons.play) : Icons.play
                font.family: Icons.font
                font.pixelSize: Styling.fontSize(2)
                color: "white"
            }

            TapHandler {
                enabled: root.hasPlayer
                onTapped: root.togglePlaying()
            }
        }
    }

    // --- Medium: text + minimal controls over a bottom scrim ---
    Item {
        visible: root.size === "medium" && root.hasContent
        anchors.fill: parent

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.62
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, root.hasPlayer ? 0.72 : 0.82)
                }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: controls.left
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.rightMargin: 4
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.displayTitle
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                font.weight: Font.Bold
                color: "white"
                opacity: root.hasPlayer ? 1.0 : 0.7
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? root.displayArtist : "Not Playing"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
                color: "white"
                opacity: root.hasPlayer ? 0.8 : 0.6
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: controls
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            spacing: 10

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Text {
                    anchors.centerIn: parent
                    text: root.hasPlayer ? (root.isPlaying ? Icons.pause : Icons.play) : Icons.launch
                    font.family: Icons.font
                    font.pixelSize: Styling.fontSize(3)
                    color: "white"
                    opacity: root.hasPlayer ? 1.0 : 0.7
                }

                TapHandler {
                    enabled: root.hasPlayer
                    onTapped: root.togglePlaying()
                }
            }
        }
    }

    // --- Large: text + full transport + scrub bar over a bottom scrim ---
    Item {
        visible: root.size === "large" && root.hasContent
        anchors.fill: parent

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.45
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, root.hasPlayer ? 0.8 : 0.85)
                }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.displayTitle
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(1)
                font.weight: Font.Bold
                color: "white"
                opacity: root.hasPlayer ? 1.0 : 0.7
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? root.displayArtist : "Not Playing"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: "white"
                opacity: root.hasPlayer ? 0.8 : 0.6
                elide: Text.ElideRight
            }

            // Collapsed entirely (not just disabled) while idle — there's
            // no live position to show, and an inert scrub bar reads as
            // broken rather than idle.
            StyledSlider {
                id: scrubBar
                Layout.fillWidth: true
                Layout.preferredHeight: root.hasPlayer ? 10 : 0
                Layout.topMargin: root.hasPlayer ? 4 : 0
                visible: root.hasPlayer
                vertical: false
                enabled: root.hasPlayer && (root.player.canSeek ?? false)
                progressColor: root.dominantColor
                backgroundColor: Qt.rgba(1, 1, 1, 0.25)
                thickness: 3
                handleSpacing: 2
                wavy: false
                icon: ""
                iconPos: "start"
                updateOnRelease: true
                onValueChanged: {
                    // CONFIRMED BUG (2026-09-13): this fired on ANY value
                    // change, including syncScrub()'s own programmatic
                    // write every 1Hz tick — value := position/length,
                    // then this handler wrote position := value*length
                    // straight back, a closed feedback loop. Float drift
                    // (or position briefly hitting/exceeding length right
                    // as a track ends) pushed the reapplied position past
                    // the track end, which Spotify's MPRIS implementation
                    // treats as "seek past end" -> skip to next track.
                    // StyledSlider has no interaction-only signal (no
                    // onMoved/onReleased of its own — checked its source),
                    // but its internal MouseArea always sets root.value
                    // BEFORE clearing isDragging on release (confirmed by
                    // reading StyledSlider.qml lines 403-411), so gating
                    // on isDragging here passes through every real user
                    // gesture while blocking every syncScrub() write
                    // (which only ever runs while !isDragging, per its own
                    // guard) — the loop is now impossible by construction,
                    // not just rate-limited.
                    if (scrubBar.isDragging && root.hasPlayer && root.player.canSeek) {
                        root.isSeeking = true;
                        root.player.position = value * root.player.length;
                        seekUnlockTimer.restart();
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Item {
                    // Collapsed while idle — prev/next have nothing to act
                    // on, and showing them dimmed next to a working "open"
                    // button read as broken controls rather than idle ones.
                    Layout.preferredWidth: root.hasPlayer ? 32 : 0
                    Layout.preferredHeight: 32
                    visible: root.hasPlayer

                    Text {
                        anchors.centerIn: parent
                        text: Icons.previous
                        font.family: Icons.font
                        font.pixelSize: Styling.fontSize(1)
                        color: "white"
                        opacity: root.player && root.player.canGoPrevious ? 0.9 : 0.35
                    }

                    TapHandler {
                        onTapped: root.previous()
                    }
                }

                Item {
                    Layout.preferredWidth: root.hasPlayer ? 40 : 48
                    Layout.preferredHeight: root.hasPlayer ? 40 : 48

                    Text {
                        anchors.centerIn: parent
                        text: root.hasPlayer ? (root.isPlaying ? Icons.pause : Icons.play) : Icons.launch
                        font.family: Icons.font
                        font.pixelSize: Styling.fontSize(root.hasPlayer ? 4 : 3)
                        color: "white"
                    }

                    TapHandler {
                        onTapped: root.hasPlayer ? root.togglePlaying() : root.openSpotify()
                    }
                }

                Item {
                    Layout.preferredWidth: root.hasPlayer ? 32 : 0
                    Layout.preferredHeight: 32
                    visible: root.hasPlayer

                    Text {
                        anchors.centerIn: parent
                        text: Icons.next
                        font.family: Icons.font
                        font.pixelSize: Styling.fontSize(1)
                        color: "white"
                        opacity: root.player && root.player.canGoNext ? 0.9 : 0.35
                    }

                    TapHandler {
                        onTapped: root.next()
                    }
                }
            }
        }
    }
}
