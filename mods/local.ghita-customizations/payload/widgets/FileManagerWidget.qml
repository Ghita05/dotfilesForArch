import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Recent and pinned Thunar directories. Thunar itself keeps no history of
// its own beyond the GTK bookmarks sidebar (~/.config/gtk-3.0/bookmarks,
// static/curated, not recency-based) — the only real per-directory
// recency data on this system is the freedesktop shared
// ~/.local/share/recently-used.xbel (used by every GTK/xdg-aware app, but
// mostly tracks individual FILES; only a handful of its entries are
// actual directories). This widget merges both: xbel directory entries
// first (real recency, most-recent first), then GTK bookmarks not already
// covered, deduped by path. Click opens the directory via `thunar`
// through DesktopService.runInActiveWorkspace.
Item {
    id: root

    // "small" | "medium" | "large" — set by Desktop.qml from the tile's
    // configured size.
    property string size: "medium"

    property var entries: []
    property bool loaded: false

    readonly property int rowLimit: size === "large" ? 6 : (size === "medium" ? 3 : 1)

    function refresh() {
        root.loaded = false;
        queryProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function parentDir(p) {
        const parts = (p || "").replace(/\/+$/, "").split("/");
        parts.pop();
        return parts.join("/") || "/";
    }

    Process {
        id: queryProcess
        command: ["python3", "-c", "import os, xml.etree.ElementTree as ET\nfrom urllib.parse import unquote, urlparse\n\nhome = os.path.expanduser('~')\nresults = []\nseen = set()\n\nxbel_path = os.path.join(home, '.local/share/recently-used.xbel')\nif os.path.isfile(xbel_path):\n    try:\n        tree = ET.parse(xbel_path)\n        ns = {'mime': 'http://www.freedesktop.org/standards/shared-mime-info'}\n        xentries = []\n        for bm in tree.getroot().findall('bookmark'):\n            href = bm.get('href', '')\n            visited = bm.get('visited', '')\n            mime_el = bm.find('.//mime:mime-type', ns)\n            mime = mime_el.get('type') if mime_el is not None else ''\n            if mime == 'inode/directory' and href.startswith('file://'):\n                path = unquote(urlparse(href).path)\n                if os.path.isdir(path):\n                    xentries.append((path, visited))\n        xentries.sort(key=lambda e: e[1], reverse=True)\n        for path, visited in xentries:\n            if path not in seen:\n                seen.add(path)\n                results.append(path)\n    except Exception:\n        pass\n\nbookmarks_path = os.path.join(home, '.config/gtk-3.0/bookmarks')\nif os.path.isfile(bookmarks_path):\n    with open(bookmarks_path) as f:\n        for line in f:\n            line = line.strip()\n            if not line:\n                continue\n            uri = line.split(' ', 1)[0]\n            if uri.startswith('file://'):\n                path = unquote(urlparse(uri).path)\n                if path not in seen and os.path.isdir(path):\n                    seen.add(path)\n                    results.append(path)\n\nfor path in results[:8]:\n    label = os.path.basename(path.rstrip('/')) or path\n    print(f'{label}\\t{path}')\n"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.loaded = true;
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                const list = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("\t");
                    if (parts.length < 2)
                        continue;
                    list.push({
                        label: parts[0],
                        path: parts[1]
                    });
                }
                root.entries = list;
            }
        }
    }

    function openEntry(entry) {
        const escapedPath = entry.path.replace(/'/g, "'\\''");
        DesktopService.runInActiveWorkspace("thunar '" + escapedPath + "'");
    }

    WidgetEmptyState {
        visible: root.loaded && root.entries.length === 0
        message: "No recent or bookmarked folders"
        iconGlyph: Icons.folder
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
            text: Icons.folder
            font.family: Icons.font
            font.pixelSize: Styling.fontSize(6)
            color: Styling.srItem("overprimary")
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - 16
            text: root.entries.length > 0 ? root.entries[0].label : ""
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
                iconGlyph: Icons.folder
                primaryText: modelData.label
                secondaryText: root.parentDir(modelData.path)
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
