import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 14
    property var monitors: []
    readonly property int activeCount: {
        let c = 0; for (const m of monitors) if (!m.disabled) c++; return c
    }

    Process {
        id: probe
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(m => ({
                        name: m.name, desc: m.description || "",
                        w: m.width, h: m.height, hz: m.refreshRate, scale: m.scale,
                        x: m.x, y: m.y, transform: m.transform || 0,
                        disabled: m.disabled === true, focused: m.focused === true,
                        modes: m.availableModes || []
                    }))
                } catch (e) { root.monitors = [] }
            }
        }
    }
    Process { id: applyProc }
    function refresh() { probe.running = true }
    function apply(arg) { applyProc.command = ["hyprctl", "keyword", "monitor", arg]; applyProc.running = true; Qt.callLater(root.refresh) }
    Component.onCompleted: refresh()
    Timer { interval: 4000; running: true; repeat: true; onTriggered: root.refresh() }

    RowLayout {
        Layout.fillWidth: true
        Text { text: "Displays"; color: Root.Theme.text; Layout.fillWidth: true; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
        Text {
            text: "\uf021"; color: refHov.containsMouse ? Root.Theme.text : Root.Theme.textDim
            font.family: Root.Theme.fontFamily; font.pixelSize: 14
            MouseArea { id: refHov; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.refresh() }
        }
    }

    Repeater {
        model: root.monitors
        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: col.implicitHeight + 28
            radius: 16
            color: Root.Theme.surfaceVeryGlass
            border.color: modelData.focused ? Root.Theme.selectionStrong : Root.Theme.border
            border.width: 1

            property string selRes: modelData.w + "x" + modelData.h
            property real selHz: modelData.hz
            property real selScale: modelData.scale
            property int selTransform: modelData.transform
            readonly property bool canDisable: root.activeCount > 1 || modelData.disabled

            function uniqRes() { const seen = {}, out = []; for (const m of modelData.modes) { const r = m.split("@")[0]; if (!seen[r]) { seen[r] = 1; out.push(r) } } return out }
            function hzFor(res) { const out = []; for (const m of modelData.modes) { const p = m.split("@"); if (p[0] !== res) continue; const hz = parseFloat(p[1]); if (!isNaN(hz)) out.push(hz) } return out.sort((a, b) => b - a) }
            function commit() { root.apply(modelData.name + "," + selRes + "@" + selHz.toFixed(2) + "," + modelData.x + "x" + modelData.y + "," + selScale.toFixed(2) + ",transform," + selTransform) }

            opacity: 0; scale: 0.8; transformOrigin: Item.Center
            Component.onCompleted: cardAnim.start()
            SequentialAnimation {
                id: cardAnim
                PauseAnimation { duration: card.index * 90 }
                ParallelAnimation {
                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                }
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true; spacing: 14
                    Item {
                        width: 78; height: 78
                        Rectangle { anchors.centerIn: parent; width: 78; height: 78; radius: 39; color: "transparent"; border.color: Root.Theme.border; border.width: 1; opacity: 0.7 }
                        Rectangle {
                            anchors.centerIn: parent; width: 58; height: 58; radius: 29
                            color: !card.modelData.disabled ? Root.Theme.selection : Root.Theme.surfaceGlassHi
                            border.color: !card.modelData.disabled ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
                            Text { anchors.centerIn: parent; text: "\uf108"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 20 }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: card.modelData.name + (card.modelData.focused ? "  \uf005" : ""); color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { visible: card.modelData.desc.length > 0; text: card.modelData.desc; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: card.modelData.w + "×" + card.modelData.h + " @ " + Math.round(card.modelData.hz) + "Hz · " + card.modelData.scale.toFixed(2) + "×"; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                    }
                    Rectangle {
                        width: 44; height: 22; radius: 11
                        opacity: card.canDisable ? 1 : 0.4
                        color: !card.modelData.disabled ? Root.Theme.accent : Root.Theme.surfaceGlassHi
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Rectangle { width: 16; height: 16; radius: 8; color: Root.Theme.text; anchors.verticalCenter: parent.verticalCenter; x: !card.modelData.disabled ? parent.width - width - 3 : 3; Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: card.canDisable
                            onClicked: card.modelData.disabled ? root.apply(card.modelData.name + ",preferred,auto,1") : root.apply(card.modelData.name + ",disable")
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true; spacing: 6; visible: !card.modelData.disabled
                    Repeater {
                        model: card.uniqRes()
                        delegate: Rectangle {
                            required property var modelData
                            property bool sel: card.selRes === modelData
                            implicitWidth: rl.implicitWidth + 18; height: 28; radius: 9
                            color: sel ? Root.Theme.selection : Root.Theme.surfaceGlassHi
                            border.color: sel ? Root.Theme.selectionStrong : "transparent"; border.width: 1
                            Text { id: rl; anchors.centerIn: parent; text: modelData; color: parent.sel ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { card.selRes = modelData; const hzs = card.hzFor(modelData); if (hzs.length) card.selHz = hzs[0] } }
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true; spacing: 6; visible: !card.modelData.disabled
                    Repeater {
                        model: card.hzFor(card.selRes)
                        delegate: Rectangle {
                            required property var modelData
                            property bool sel: Math.abs(card.selHz - modelData) < 0.1
                            implicitWidth: hl.implicitWidth + 16; height: 26; radius: 9
                            color: sel ? Root.Theme.selection : Root.Theme.surfaceGlassHi
                            border.color: sel ? Root.Theme.selectionStrong : "transparent"; border.width: 1
                            Text { id: hl; anchors.centerIn: parent; text: Math.round(modelData) + "Hz"; color: parent.sel ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.selHz = modelData }
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true; spacing: 6; visible: !card.modelData.disabled
                    Repeater {
                        model: [1, 1.25, 1.5, 2]
                        delegate: Rectangle {
                            required property var modelData
                            property bool sel: Math.abs(card.selScale - modelData) < 0.01
                            width: 42; height: 26; radius: 9
                            color: sel ? Root.Theme.selection : Root.Theme.surfaceGlassHi
                            border.color: sel ? Root.Theme.selectionStrong : "transparent"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData + "×"; color: parent.sel ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.selScale = modelData }
                        }
                    }
                    Repeater {
                        model: [{ t: 0, l: "0°" }, { t: 1, l: "90°" }, { t: 2, l: "180°" }, { t: 3, l: "270°" }]
                        delegate: Rectangle {
                            required property var modelData
                            property bool sel: card.selTransform === modelData.t
                            width: 38; height: 26; radius: 9
                            color: sel ? Root.Theme.selection : Root.Theme.surfaceGlassHi
                            border.color: sel ? Root.Theme.selectionStrong : "transparent"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.l; color: parent.sel ? Root.Theme.text : Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.selTransform = modelData.t }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 12; visible: !card.modelData.disabled
                    color: applyHov.containsMouse ? Root.Theme.selectionStrong : Root.Theme.selection
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "Apply"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                    MouseArea { id: applyHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.commit() }
                }
            }
        }
    }
    Text { visible: root.monitors.length === 0; text: "No monitors reported."; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
}