import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Qt.labs.folderlistmodel
import "../.." as Root

PanelWindow {
    id: root

    // ── adjust if your username differs (FolderListModel needs an absolute path) ──
    property string wallDir: "/home/ghita/dotfiles/wallpapers"
    property string transitionType: "fade"
    property string currentPath: ""

    property bool open: false
    property bool _show: false

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    visible: _show

    Component.onCompleted: { if (this.WlrLayershell != null) this.WlrLayershell.layer = WlrLayer.Overlay }
    onOpenChanged: {
        if (open) { _show = true; queryProc.running = true }
        else closeTimer.restart()
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    }
    Timer { id: closeTimer; interval: 360; onTriggered: if (!root.open) root._show = false }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    Process { id: queryProc }   

    Process { id: applyProc }
    function apply(path) {
        if (applyProc.running) applyProc.running = false
        applyProc.command = ["sh", "-c",
            "awww img " + JSON.stringify(path) +
            " --transition-type " + root.transitionType +
            " --transition-fps 60 --transition-step 10 && " +
            "printf '%s' " + JSON.stringify(path) +
            " > /home/ghita/.config/quickshell/.current-wallpaper"]
        applyProc.running = true
        root.currentPath = path
    }

    FolderListModel {
        id: wallModel
        folder: "file://" + root.wallDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        focus: root._show
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Escape) { root.open = false; e.accepted = true }
            else if (e.key === Qt.Key_Left)  { view.decrementCurrentIndex(); e.accepted = true }
            else if (e.key === Qt.Key_Right) { view.incrementCurrentIndex(); e.accepted = true }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (wallModel.count > 0) root.apply(wallModel.get(view.currentIndex, "filePath"))
                e.accepted = true
            }
        }

        // the whole ribbon is raked slightly in 3D, like the video's tilted plane
        PathView {
            id: view
            anchors.fill: parent
            anchors.verticalCenterOffset: -10
            model: wallModel
            pathItemCount: 9
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem
            highlightMoveDuration: 300
            flickDeceleration: 1500
            maximumFlickVelocity: 2600

            readonly property real cardW: 250
            readonly property real cardH: 300

            // A nearly-straight horizontal line spanning the whole width, so cards
            // sit shoulder-to-shoulder as a continuous strip. The slight Y dip at the
            // ends + the per-item skew ramp give the raked-plane look.
            path: Path {
                startX: -view.cardW * 0.6
                startY: view.height / 2 + 26
                PathAttribute { name: "skew";    value: 50 }
                PathAttribute { name: "scale";   value: 0.92 }
                PathAttribute { name: "opacity"; value: 0.7 }
                PathAttribute { name: "z";       value: 0 }

                PathLine { x: view.width / 2; y: view.height / 2 }
                PathAttribute { name: "skew";    value: 0 }
                PathAttribute { name: "scale";   value: 1.0 }
                PathAttribute { name: "opacity"; value: 1.0 }
                PathAttribute { name: "z";       value: 100 }

                PathLine { x: view.width + view.cardW * 0.6; y: view.height / 2 + 26 }
                PathAttribute { name: "skew";    value: -50 }
                PathAttribute { name: "scale";   value: 0.92 }
                PathAttribute { name: "opacity"; value: 0.7 }
                PathAttribute { name: "z";       value: 0 }
            }

            delegate: Item {
                id: dele
                required property string filePath
                required property url fileUrl
                required property int index
                width: view.cardW; height: view.cardH
                z: PathView.z === undefined ? 0 : PathView.z
                opacity: PathView.opacity === undefined ? 0.7 : PathView.opacity
                property real pvScale: PathView.scale === undefined ? 0.92 : PathView.scale
                property real skew: PathView.skew === undefined ? 0 : PathView.skew

                // centre expands smoothly as it lands
                scale: pvScale
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                transform: Rotation {
                    origin.x: dele.width / 2
                    origin.y: dele.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: dele.skew
                }

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 3            // tiny margin = tight, shoulder-to-shoulder
                    radius: 14
                    property bool isCenter: dele.PathView.isCurrentItem
                    property bool isLive: dele.filePath === root.currentPath
                    color: Root.Theme.surface
                    border.color: isLive ? Root.Theme.selectionStrong
                                : isCenter ? Root.Theme.accentSoft
                                : "#22000000"
                    border.width: (isLive || isCenter) ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Image {
                        anchors.fill: parent
                        source: dele.fileUrl
                        sourceSize.width: 360
                        sourceSize.height: 440
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    // darken non-centre cards so the focus pops, like the video
                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: parent.isCenter ? 0 : 0.32
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        visible: parent.isLive
                        width: 24; height: 24; radius: 12
                        color: Root.Theme.selectionStrong
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            color: Root.Theme.text
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (dele.PathView.isCurrentItem) root.apply(dele.filePath)
                        else view.currentIndex = dele.index
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: wallModel.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No wallpapers in\n" + root.wallDir
            color: Root.Theme.textDim
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
        }
    }
}