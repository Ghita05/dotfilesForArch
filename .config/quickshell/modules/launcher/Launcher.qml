import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.." as Root

PanelWindow {
    id: launcher
    property bool open: false
    property int selectedIndex: 0
    property var results: filterApps(searchField.text)

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    visible: open

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }
    onOpenChanged: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        if (open) { searchField.text = ""; selectedIndex = 0; searchField.forceActiveFocus() }
    }

    function toggle() { open = !open }
    function hide() { open = false }

    function filterApps(query) {
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (!query || query.length === 0) {
            // no query: most-used first, then alphabetical
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
            // name-match position first, frecency as the tie-breaker
            .sort((a, b) => (a.idx - b.idx) || (b.fr - a.fr) || a.app.name.localeCompare(b.app.name))
            .map(x => x.app)
    }

    function launch(app) {
        if (!app) return
        Root.PersistState.recordLaunch(app.id)
        app.execute()
        hide()
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function open(): void { launcher.open = true }
        function close(): void { launcher.hide() }
    }

    MouseArea { anchors.fill: parent; onClicked: launcher.hide() }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.16
        width: 560
        height: Math.min(540, 76 + resultsView.contentHeight + 16)
        radius: 18
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1
        clip: true
        opacity: launcher.open ? 1 : 0
        scale: launcher.open ? 1 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        MouseArea { anchors.fill: parent }

        TextField {
            id: searchField
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 14
            height: 46
            placeholderText: "Search apps…"
            color: Root.Theme.text
            placeholderTextColor: Root.Theme.textDim
            font.family: Root.Theme.fontFamily
            font.pixelSize: 15
            leftPadding: 16
            background: Rectangle {
                radius: 12
                color: Root.Theme.surfaceVeryGlass
                border.color: searchField.activeFocus ? Root.Theme.selectionStrong : "transparent"
                border.width: 1
            }
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { launcher.hide(); e.accepted = true }
                else if (e.key === Qt.Key_Down) { launcher.selectedIndex = Math.min(launcher.selectedIndex + 1, launcher.results.length - 1); resultsView.positionViewAtIndex(launcher.selectedIndex, ListView.Contain); e.accepted = true }
                else if (e.key === Qt.Key_Up) { launcher.selectedIndex = Math.max(launcher.selectedIndex - 1, 0); resultsView.positionViewAtIndex(launcher.selectedIndex, ListView.Contain); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { launcher.launch(launcher.results[launcher.selectedIndex]); e.accepted = true }
            }
            onTextChanged: launcher.selectedIndex = 0
        }

        ListView {
            id: resultsView
            anchors { left: parent.left; right: parent.right; top: searchField.bottom; bottom: parent.bottom }
            anchors.margins: 8
            anchors.topMargin: 4
            clip: true
            model: launcher.results
            spacing: 2

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 50
                radius: 10
                color: index === launcher.selectedIndex ? Root.Theme.selection : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 12
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30; height: 30; sourceSize.width: 30; sourceSize.height: 30
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text { text: modelData.name; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
                        Text {
                            text: modelData.comment || ""
                            visible: text.length > 0
                            color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11
                            elide: Text.ElideRight; width: card.width - 90
                        }
                    }
                }
                // tiny "frequent" dot for your top apps
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                    visible: Root.PersistState.frecency(modelData.id) > 0 && searchField.text.length === 0
                    text: "\uf005"; color: Root.Theme.accentSoft; font.family: Root.Theme.fontFamily; font.pixelSize: 10
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: launcher.selectedIndex = index; onClicked: launcher.launch(modelData) }
            }
        }
    }
}