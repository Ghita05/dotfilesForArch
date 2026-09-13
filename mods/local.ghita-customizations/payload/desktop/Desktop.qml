import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.services
import qs.modules.theme
import qs.modules.components
import "widgets"
import qs.config

// iPadOS-style APP widgets: each tile shows live content from inside one
// specific app and clicking a row opens that item in the real app.
//
// Tiles come in three fixed, iPad-style sizes (small/medium/large) — each
// widget renders a genuinely different layout per size, not a scaled copy.
// They're freely draggable (grid-snapped, not locked to fixed rows/
// columns) and position is persisted straight into desktop.json via
// Config's normal JsonAdapter auto-save. The four app-launcher icons use
// the same drag+persist mechanism individually.
//
// Positions are clamped to "at least half the tile stays on screen" in
// three places that all share the same clampAxis()/axisBounds() math: the
// live drag bounds, the post-drop snap (which used to round a boundary-
// adjacent value PAST the valid range — see the comment above
// computeDropPosition for the actual bug this fixes), and the initial x/y
// binding at load time, so a position that's stale (monitor unplugged,
// resolution changed) or was saved from a differently-sized screen
// self-heals on the next restart instead of rendering off-screen forever.
PanelWindow {
    id: desktop
    property int barSize: Config.showBackground ? 44 : 40
    property string barPosition: ["top", "bottom", "left", "right"].includes(Config.bar.position) ? Config.bar.position : "top"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "ambxst:desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    readonly property var widgetsConfig: Config.desktop.widgets
    readonly property var launchersConfig: widgetsConfig.launchers || ({})
    // Was 166 (one full grid cell) — enough to make every drop feel like it
    // "jumped elsewhere" if it landed mid-cell. A small tidy-up snap reads
    // as assistance instead of a fight.
    readonly property int gridSnap: widgetsConfig.gridSnap ?? 20

    // iPad-style fixed sizes: small is roughly square (1x1), medium is
    // twice as wide (2x1), large is twice as wide and tall (2x2).
    readonly property int tileUnit: 150
    readonly property int tileGap: 16
    readonly property var tileSizes: ({
            "small": {
                width: tileUnit,
                height: tileUnit
            },
            "medium": {
                width: tileUnit * 2 + tileGap,
                height: tileUnit
            },
            "large": {
                width: tileUnit * 2 + tileGap,
                height: tileUnit * 2 + tileGap
            }
        })

    function sizeFor(sizeName) {
        return desktop.tileSizes[sizeName] || desktop.tileSizes.medium;
    }

    // Per-app identity accent for each tile's hairline top edge — real
    // brand colours where the app has one everyone would recognise
    // (VS Code blue, Firefox orange, Spotify green as the pre-art-load
    // fallback). Thunar/XFCE doesn't have one strong canonical single
    // colour the way the others do, so this is a representative blue
    // matching its own icon's tone, not an official brand value.
    function staticAccentFor(type) {
        switch (type) {
        case "vscode":
            return "#007ACC";
        case "firefox":
            return "#FF7139";
        case "spotify":
            return "#1DB954";
        case "filemanager":
            return "#1E88E5";
        default:
            return Colors.primary;
        }
    }

    // Empty screenList means "all screens" — same convention as dock.json
    // and bar.json (see UnifiedShellPanel.qml / shell.qml).
    readonly property bool screenAllowed: {
        const list = Config.desktop.screenList;
        if (!list || list.length === 0)
            return true;
        return list.indexOf(screen ? screen.name : "") !== -1;
    }

    visible: Config.desktop.enabled && widgetsConfig.enabled && screenAllowed

    function resolveDesktopEntry(appId) {
        if (!appId)
            return null;
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id === appId)
                return apps[i];
        }
        return DesktopEntries.heuristicLookup(appId) || null;
    }

    // Valid range for one axis of a draggable item's position, given its
    // size along that axis and the available extent (workArea width or
    // height): allows the item to hang up to half its own size off either
    // edge, but never fully off — "at least half on-screen at all times."
    function axisBounds(size, extent) {
        const half = size / 2;
        const min = -half;
        const max = Math.max(min, extent - half);
        return {
            min: min,
            max: max
        };
    }

    function clampAxis(value, size, extent) {
        const b = desktop.axisBounds(size, extent);
        return Math.max(b.min, Math.min(b.max, value));
    }

    // Root cause of "drops land elsewhere": the previous version rounded
    // the dropped position to the nearest grid-snap multiple but never
    // re-clamped afterward, so a drag ending near an edge could round to a
    // multiple just past the valid boundary — e.g. the Notion launcher's
    // persisted y:1162 is exactly 7*166 (last round's snap distance), a
    // few px beyond both monitors' actual max Y. Snap first, THEN clamp,
    // every time, so the saved value can never exceed axisBounds().
    function computeDropPosition(rawX, rawY, w, h) {
        const snap = desktop.gridSnap;
        let x = snap > 0 ? Math.round(rawX / snap) * snap : rawX;
        let y = snap > 0 ? Math.round(rawY / snap) * snap : rawY;
        x = desktop.clampAxis(x, w, workArea.width);
        y = desktop.clampAxis(y, h, workArea.height);
        return {
            x: x,
            y: y
        };
    }

    // Config.desktop.widgets is a plain JS object (JsonAdapter "property
    // var"), so mutating a nested field in place would not trigger the
    // adapter's change notification — the whole object has to be
    // reassigned, which is what actually fires onAdapterUpdated ->
    // writeAdapter() and saves it.
    function saveTilePosition(index, x, y) {
        const tiles = desktop.widgetsConfig.tiles.map((t, i) => i === index ? Object.assign({}, t, {
                x: x,
                y: y
            }) : t);
        Config.desktop.widgets = Object.assign({}, desktop.widgetsConfig, {
            tiles: tiles
        });
    }

    function saveLauncherPosition(index, x, y) {
        const apps = (desktop.launchersConfig.apps || []).map((a, i) => i === index ? Object.assign({}, a, {
                x: x,
                y: y
            }) : a);
        Config.desktop.widgets = Object.assign({}, desktop.widgetsConfig, {
            launchers: Object.assign({}, desktop.launchersConfig, {
                apps: apps
            })
        });
    }

    Item {
        id: workArea
        anchors.fill: parent
        anchors.topMargin: desktop.barPosition === "top" ? desktop.barSize : 0
        anchors.bottomMargin: desktop.barPosition === "bottom" ? desktop.barSize : 0
        anchors.leftMargin: desktop.barPosition === "left" ? desktop.barSize : 0
        anchors.rightMargin: desktop.barPosition === "right" ? desktop.barSize : 0

        Repeater {
            model: desktop.widgetsConfig.tiles

            delegate: StyledRect {
                id: tile
                required property var modelData
                required property int index
                readonly property var appEntry: desktop.resolveDesktopEntry(tile.modelData.appId || "")
                readonly property var box: desktop.sizeFor(tile.modelData.size || "medium")
                // Spotify identifies itself with album art; a title bar on
                // top of that is redundant chrome, so it drags by the
                // whole card instead of a header strip.
                readonly property bool showHeader: tile.modelData.type !== "spotify"
                // Per-app identity accent, used sparingly (a hairline top
                // edge only — see contentClip below), not a full-colour
                // card. Spotify prefers its own art's extracted dominant
                // colour once a track is loaded, falling back to the
                // brand green before that.
                readonly property color accentColor: (widgetLoader.item && widgetLoader.item.dominantColor) || desktop.staticAccentFor(tile.modelData.type)

                x: desktop.clampAxis(modelData.x ?? 40, box.width, workArea.width)
                y: desktop.clampAxis(modelData.y ?? 40, box.height, workArea.height)
                width: box.width
                height: box.height
                variant: "pane"
                enableShadow: true
                // Raised from the theme's default pane opacity (0.3, tuned
                // for panels layered over the shell's own background, not
                // an arbitrary photo) so tile text reads regardless of
                // wallpaper. Per-instance override — the shared "pane"
                // variant used elsewhere is untouched.
                backgroundOpacity: 0.88
                radius: Styling.radius(4)
                // Deliberately NOT clipped here: clip:true on the same
                // item that casts enableShadow's layer.effect shadow
                // clips the shadow's own bleed too, since clip and
                // layer.effect share Qt Quick's scissor pass on this
                // item — the tiles had a shadow the whole time, it just
                // couldn't render outside its own clipped bounds. Content
                // clipping moved to contentClip below instead, which
                // isn't shadow-casting so it's free to clip.

                Rectangle {
                    id: contentClip
                    anchors.fill: parent
                    radius: tile.radius
                    color: "transparent"
                    clip: true

                    Rectangle {
                        // Thin top-edge accent — the family stays visually
                        // coherent (same card, same opacity, same shadow)
                        // while this one hairline is what makes a widget
                        // recognisable at a glance without reading it.
                        id: accentBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 3
                        color: tile.accentColor
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: accentBar.height
                        spacing: 0

                        // Header doubles as the drag handle, so dragging a
                        // tile never fights with clicking one of its rows.
                        // Small and dim on purpose — this is a label, not a
                        // title bar. Collapsed entirely for widgets that opt
                        // out (see showHeader).
                        RowLayout {
                            id: header
                            visible: tile.showHeader
                            Layout.fillWidth: true
                            Layout.preferredHeight: tile.showHeader ? 20 : 0
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.topMargin: tile.showHeader ? 6 : 0
                            spacing: 5

                        Image {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            source: tile.appEntry ? "image://icon/" + tile.appEntry.icon : "image://icon/image-missing"
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            opacity: 0.65
                        }

                        Text {
                            Layout.fillWidth: true
                            text: tile.appEntry ? tile.appEntry.name : tile.modelData.type
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-3)
                            font.weight: Font.Medium
                            color: Colors.overBackground
                            opacity: 0.55
                            elide: Text.ElideRight
                        }

                        DragHandler {
                            id: headerDragHandler
                            enabled: tile.showHeader
                            target: tile
                            cursorShape: Qt.SizeAllCursor
                            xAxis.minimum: desktop.axisBounds(tile.width, workArea.width).min
                            xAxis.maximum: desktop.axisBounds(tile.width, workArea.width).max
                            yAxis.minimum: desktop.axisBounds(tile.height, workArea.height).min
                            yAxis.maximum: desktop.axisBounds(tile.height, workArea.height).max
                            onActiveChanged: {
                                if (!active) {
                                    const p = desktop.computeDropPosition(tile.x, tile.y, tile.width, tile.height);
                                    tile.x = p.x;
                                    tile.y = p.y;
                                    desktop.saveTilePosition(tile.index, p.x, p.y);
                                }
                            }
                        }
                    }

                    Loader {
                        id: widgetLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: tile.showHeader ? 2 : 0
                        sourceComponent: {
                            switch (tile.modelData.type) {
                            case "vscode":
                                return vscodeComponent;
                            case "firefox":
                                return firefoxComponent;
                            case "spotify":
                                return spotifyComponent;
                            case "filemanager":
                                return fileManagerComponent;
                            default:
                                return null;
                            }
                        }
                        onLoaded: {
                            if (item)
                                item.size = tile.modelData.size || "medium";
                        }
                    }
                    }
                }

                // Whole-card drag for widgets with no header (Spotify).
                // TapHandler-based controls inside (play/pause, scrub bar)
                // take the grab for an actual tap; only a real drag
                // gesture reaches this handler, the same arbitration the
                // launchers below already rely on. Audited per your ask:
                // this does NOT explain the unprompted skipping (it can
                // only fire from an actual press-and-move on the card,
                // never on its own) — the scrub bar feedback loop above
                // is the confirmed cause. Hardened anyway: an explicit,
                // larger-than-default drag threshold (Qt's own default is
                // ~8px) makes normal click jitter on the small control
                // glyphs less likely to get arbitrated away from their
                // TapHandlers.
                DragHandler {
                    id: cardDragHandler
                    enabled: !tile.showHeader
                    target: tile
                    dragThreshold: 15
                    cursorShape: Qt.SizeAllCursor
                    xAxis.minimum: desktop.axisBounds(tile.width, workArea.width).min
                    xAxis.maximum: desktop.axisBounds(tile.width, workArea.width).max
                    yAxis.minimum: desktop.axisBounds(tile.height, workArea.height).min
                    yAxis.maximum: desktop.axisBounds(tile.height, workArea.height).max
                    onActiveChanged: {
                        if (!active) {
                            const p = desktop.computeDropPosition(tile.x, tile.y, tile.width, tile.height);
                            tile.x = p.x;
                            tile.y = p.y;
                            desktop.saveTilePosition(tile.index, p.x, p.y);
                        }
                    }
                }
            }
        }

        // Secondary launcher row — small, clearly not "widgets", and
        // individually draggable/persisted the same way the tiles are.
        Repeater {
            model: desktop.launchersConfig.enabled !== false ? (desktop.launchersConfig.apps || []) : []

            delegate: StyledRect {
                id: launcherTile
                required property var modelData
                required property int index
                readonly property var entry: desktop.resolveDesktopEntry(modelData.appId || "")
                readonly property int tileSize: desktop.launchersConfig.tileSize || 56

                x: desktop.clampAxis(modelData.x ?? (40 + index * (tileSize + 12)), tileSize, workArea.width)
                y: desktop.clampAxis(modelData.y ?? (workArea.height - tileSize - 24), tileSize, workArea.height)
                variant: "pane"
                enableShadow: true
                backgroundOpacity: 0.88
                width: tileSize
                height: tileSize
                radius: Styling.radius(6)

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: launcherTile.entry ? "image://icon/" + launcherTile.entry.icon : "image://icon/image-missing"
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Error)
                            source = "image://icon/image-missing";
                    }
                }

                StyledToolTip {
                    visible: launcherHover.hovered
                    tooltipText: launcherTile.entry ? launcherTile.entry.name : launcherTile.modelData.appId
                }

                HoverHandler {
                    id: launcherHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (launcherTile.entry)
                            AppSearch.launchApp(launcherTile.entry);
                    }
                }

                DragHandler {
                    id: launcherDragHandler
                    target: launcherTile
                    cursorShape: Qt.SizeAllCursor
                    xAxis.minimum: desktop.axisBounds(launcherTile.width, workArea.width).min
                    xAxis.maximum: desktop.axisBounds(launcherTile.width, workArea.width).max
                    yAxis.minimum: desktop.axisBounds(launcherTile.height, workArea.height).min
                    yAxis.maximum: desktop.axisBounds(launcherTile.height, workArea.height).max
                    onActiveChanged: {
                        if (!active) {
                            const p = desktop.computeDropPosition(launcherTile.x, launcherTile.y, launcherTile.width, launcherTile.height);
                            launcherTile.x = p.x;
                            launcherTile.y = p.y;
                            desktop.saveLauncherPosition(launcherTile.index, p.x, p.y);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: vscodeComponent
        VsCodeWidget {
            anchors.fill: parent
        }
    }

    Component {
        id: firefoxComponent
        FirefoxWidget {
            anchors.fill: parent
        }
    }

    Component {
        id: spotifyComponent
        SpotifyWidget {
            anchors.fill: parent
        }
    }

    Component {
        id: fileManagerComponent
        FileManagerWidget {
            anchors.fill: parent
        }
    }
}
