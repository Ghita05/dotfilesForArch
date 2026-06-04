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

    Component.onCompleted: {
        if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay
    }
    onOpenChanged: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    }
    
    function toggle() { open ? hide() : show() }
    function show() {
        open = true
        searchField.text = ""
        selectedIndex = 0
        searchField.forceActiveFocus()
    }
    function hide() { open = false }

    function filterApps(query) {
        const all = DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
        if (!query || query.length === 0) {
            return all.slice().sort((a, b) => a.name.localeCompare(b.name))
        }
        const q = query.toLowerCase()
        return all
            .map(a => ({ app: a, idx: a.name.toLowerCase().indexOf(q) }))
            .filter(x => x.idx !== -1)
            .sort((a, b) => a.idx - b.idx || a.app.name.localeCompare(b.app.name))
            .map(x => x.app)
    }

    function launch(app) {
        if (!app) return
        app.execute()
        hide()
    }

    IpcHandler {
        target: "launcher"
        function toggle() { launcher.toggle() }
        function open() { launcher.show() }
        function close() { launcher.hide() }
    }

    // Transparent click-catcher — closes on outside click, hides NOTHING.
    // No fill = your desktop and windows stay fully visible behind the card.
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
    }

    // Centered floating card — same glass material as the bar pills.
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.18
        width: 560
        height: Math.min(520, 72 + resultsView.contentHeight + 16)
        radius: 18
        color: "#8c16181f"               // <-- glass: change "8c" toward "cc" for more opacity
        border.color: "#1c8ca0c8"
        border.width: 1
        clip: true

        opacity: launcher.open ? 1 : 0
        transform: Translate { y: launcher.open ? 0 : 12 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // clicks on the card must NOT fall through to the close-catcher
        MouseArea { anchors.fill: parent }

        TextField {
            id: searchField
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 14
            height: 44
            placeholderText: "Search apps…"
            color: Root.Theme.text
            placeholderTextColor: Root.Theme.textDim
            font.family: Root.Theme.fontFamily
            font.pixelSize: 15
            leftPadding: 16
            background: Rectangle {
                radius: 12
                color: "#14ffffff"
                border.color: searchField.activeFocus ? "#558ca0c8" : "transparent"
                border.width: 1
            }

            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { launcher.hide(); e.accepted = true }
                else if (e.key === Qt.Key_Down) {
                    launcher.selectedIndex = Math.min(launcher.selectedIndex + 1, launcher.results.length - 1)
                    resultsView.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                    e.accepted = true
                } else if (e.key === Qt.Key_Up) {
                    launcher.selectedIndex = Math.max(launcher.selectedIndex - 1, 0)
                    resultsView.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                    e.accepted = true
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    launcher.launch(launcher.results[launcher.selectedIndex])
                    e.accepted = true
                }
            }
            onTextChanged: launcher.selectedIndex = 0
        }

        ListView {
            id: resultsView
            anchors {
                left: parent.left; right: parent.right
                top: searchField.bottom; bottom: parent.bottom
            }
            anchors.margins: 8
            anchors.topMargin: 4
            clip: true
            model: launcher.results
            spacing: 2

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 48
                radius: 10
                color: index === launcher.selectedIndex ? "#338ca0c8" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 12

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28
                        sourceSize.width: 28; sourceSize.height: 28
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: modelData.name
                            color: Root.Theme.text
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: modelData.comment || ""
                            visible: text.length > 0
                            color: Root.Theme.textDim
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: card.width - 90
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: launcher.selectedIndex = index
                    onClicked: launcher.launch(modelData)
                }
            }
        }
    }
}