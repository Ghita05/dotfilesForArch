import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Recent Firefox history, read from places.sqlite. That file is locked
// while Firefox is running, so we copy it (and its -wal sidecar, so the
// copy isn't missing not-yet-checkpointed rows) to ~/.cache/ambxst before
// querying, then delete the copy. Profile discovery checks both the
// legacy ~/.mozilla/firefox layout and this distro's XDG one
// (~/.config/mozilla/firefox), preferring installs.ini's Default= entry.
// Click opens the URL via `firefox` through DesktopService.
// runInActiveWorkspace, the same detached-launch helper the rest of the
// shell uses.
Item {
    id: root

    // "small" | "medium" | "large" — set by Desktop.qml from the tile's
    // configured size. Each renders a different layout, not a scaled copy.
    property string size: "medium"

    property var entries: []
    property bool loaded: false

    readonly property int rowLimit: size === "large" ? 5 : (size === "medium" ? 3 : 1)

    function refresh() {
        root.loaded = false;
        discoverProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function domainOf(url) {
        const m = /^[a-z]+:\/\/([^\/]+)/i.exec(url || "");
        return m ? m[1] : (url || "");
    }

    Process {
        id: discoverProcess
        command: ["bash", "-c", "for root in \"$HOME/.mozilla/firefox\" \"$HOME/.config/mozilla/firefox\"; do\n  if [ -f \"$root/installs.ini\" ]; then\n    p=$(grep -m1 '^Default=' \"$root/installs.ini\" | cut -d= -f2-)\n    if [ -n \"$p\" ] && [ -f \"$root/$p/places.sqlite\" ]; then echo \"$root/$p\"; exit 0; fi\n  fi\ndone\nfor root in \"$HOME/.mozilla/firefox\" \"$HOME/.config/mozilla/firefox\"; do\n  for d in \"$root\"/*/; do\n    [ -f \"$d/places.sqlite\" ] && echo \"${d%/}\" && exit 0\n  done\ndone\n"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const profileDir = text.trim();
                if (profileDir.length === 0) {
                    root.loaded = true;
                    root.entries = [];
                    return;
                }
                queryProcess.command = ["bash", "-c", "tmp=\"$HOME/.cache/ambxst/firefox-places-widget.sqlite\"\nmkdir -p \"$HOME/.cache/ambxst\"\nrm -f \"$tmp\" \"$tmp-wal\" \"$tmp-shm\"\ncp \"$1/places.sqlite\" \"$tmp\" 2>/dev/null || exit 0\n[ -f \"$1/places.sqlite-wal\" ] && cp \"$1/places.sqlite-wal\" \"$tmp-wal\" 2>/dev/null\nsqlite3 -separator \"$(printf '\\t')\" \"$tmp\" \"SELECT url, COALESCE(title, url) FROM moz_places WHERE last_visit_date IS NOT NULL AND hidden = 0 ORDER BY last_visit_date DESC LIMIT 5;\"\nrm -f \"$tmp\" \"$tmp-wal\" \"$tmp-shm\"\n", "_", profileDir];
                queryProcess.running = true;
            }
        }
    }

    Process {
        id: queryProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.loaded = true;
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                const list = [];
                for (let i = 0; i < lines.length && list.length < 5; i++) {
                    const parts = lines[i].split("\t");
                    if (parts.length < 1 || !parts[0])
                        continue;
                    list.push({
                        url: parts[0],
                        title: parts[1] || parts[0]
                    });
                }
                root.entries = list;
            }
        }
    }

    function openEntry(entry) {
        const escapedUrl = entry.url.replace(/'/g, "'\\''");
        DesktopService.runInActiveWorkspace("firefox '" + escapedUrl + "'");
    }

    WidgetEmptyState {
        visible: root.loaded && root.entries.length === 0
        message: "No recent history"
        iconGlyph: Icons.globe
        compact: root.size === "small"
    }

    // Small: one glanceable item, no list chrome.
    ColumnLayout {
        visible: root.size === "small" && root.entries.length > 0
        anchors.centerIn: parent
        anchors.margins: 8
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Icons.globe
            font.family: Icons.font
            font.pixelSize: Styling.fontSize(6)
            color: Styling.srItem("overprimary")
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - 16
            text: root.entries.length > 0 ? root.entries[0].title : ""
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-2)
            font.weight: Font.Medium
            color: Colors.overBackground
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: root.entries.length > 0 && root.openEntry(root.entries[0])
        }
    }

    // Medium / large: a short or full list.
    ColumnLayout {
        visible: root.size !== "small" && root.entries.length > 0
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        Item {
            Layout.fillHeight: true
            visible: root.entries.length < root.rowLimit
        }

        Repeater {
            model: root.entries.slice(0, root.rowLimit)

            delegate: WidgetRow {
                id: rowDelegate
                required property var modelData
                required property int index
                Layout.fillWidth: true
                iconGlyph: Icons.globe
                primaryText: modelData.title
                secondaryText: root.domainOf(modelData.url)
                showDivider: index < Math.min(root.entries.length, root.rowLimit) - 1
                onClicked: root.openEntry(modelData)
            }
        }

        Item {
            Layout.fillHeight: true
            visible: root.entries.length < root.rowLimit
        }
    }
}
