import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Recent VS Code (OSS) workspaces, read from state.vscdb's
// history.recentlyOpenedPathsList (the same data "File > Open Recent"
// reads). That key only exists once you've had more than one workspace
// open, so on a fresh profile we fall back to storage.json's
// windowsState.lastActiveWindow so the tile isn't empty. Click opens the
// workspace via `code-oss` through DesktopService.runInActiveWorkspace
// (the same detached-launch helper the rest of the shell uses).
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

    function uriToPath(uri) {
        if (!uri)
            return "";
        let p = uri.replace(/^file:\/\//, "");
        try {
            p = decodeURIComponent(p);
        } catch (e) {}
        return p;
    }

    function baseName(p) {
        const parts = (p || "").replace(/\/+$/, "").split("/");
        return parts[parts.length - 1] || p || "";
    }

    function parentDir(p) {
        const parts = (p || "").replace(/\/+$/, "").split("/");
        parts.pop();
        return parts.join("/") || "/";
    }

    Process {
        id: discoverProcess
        command: ["sh", "-c", "ls \"$HOME\"/.config/Code*/User/globalStorage/state.vscdb 2>/dev/null | head -1"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const dbPath = text.trim();
                if (dbPath.length === 0) {
                    root.loaded = true;
                    root.entries = [];
                    return;
                }
                queryProcess.dbPath = dbPath;
                queryProcess.command = ["sqlite3", "file:" + dbPath + "?mode=ro", "SELECT value FROM ItemTable WHERE key='history.recentlyOpenedPathsList';"];
                queryProcess.running = true;
            }
        }
    }

    Process {
        id: queryProcess
        property string dbPath: ""
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                let list = [];
                const raw = text.trim();
                if (raw.length > 0) {
                    try {
                        const data = JSON.parse(raw);
                        const rawEntries = (data && data.entries) || [];
                        for (let i = 0; i < rawEntries.length && list.length < 5; i++) {
                            const e = rawEntries[i];
                            const uri = e.folderUri || (e.workspace && e.workspace.configPath) || e.fileUri;
                            if (!uri)
                                continue;
                            const path = root.uriToPath(uri);
                            list.push({
                                label: e.label || root.baseName(path),
                                path: path,
                                uri: uri,
                                isFolder: !!e.folderUri
                            });
                        }
                    } catch (err) {
                        console.warn("VsCodeWidget: failed to parse recentlyOpenedPathsList:", err);
                    }
                }

                if (list.length > 0) {
                    root.loaded = true;
                    root.entries = list;
                } else {
                    // No "recently opened" history accumulated yet on this
                    // profile — show the currently/last active folder
                    // instead of an empty tile.
                    fallbackProcess.command = ["cat", queryProcess.dbPath.replace(/state\.vscdb$/, "storage.json")];
                    fallbackProcess.running = true;
                }
            }
        }
    }

    Process {
        id: fallbackProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.loaded = true;
                try {
                    const data = JSON.parse(text);
                    const folder = (data.windowsState && data.windowsState.lastActiveWindow && data.windowsState.lastActiveWindow.folder) || (data.backupWorkspaces && data.backupWorkspaces.folders && data.backupWorkspaces.folders[0] && data.backupWorkspaces.folders[0].folderUri);
                    const path = root.uriToPath(folder);
                    root.entries = folder ? [{
                            label: root.baseName(path),
                            path: path,
                            uri: folder,
                            isFolder: true
                        }] : [];
                } catch (e) {
                    root.entries = [];
                }
            }
        }
    }

    function openEntry(entry) {
        // code-oss's CLI takes plain filesystem paths, not file:// URIs
        // (no --folder-uri/--file-uri flags in this build's --help output).
        const escapedPath = entry.path.replace(/'/g, "'\\''");
        DesktopService.runInActiveWorkspace("code-oss '" + escapedPath + "'");
    }

    WidgetEmptyState {
        visible: root.loaded && root.entries.length === 0
        message: "No recent workspaces"
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
            text: root.entries.length > 0 ? (root.entries[0].isFolder ? Icons.folder : Icons.file) : ""
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
                iconGlyph: modelData.isFolder ? Icons.folder : Icons.file
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
