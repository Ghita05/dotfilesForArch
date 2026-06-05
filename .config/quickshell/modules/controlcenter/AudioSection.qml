import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

ColumnLayout {
    id: root
    spacing: 14

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAu: sink ? sink.audio : null
    readonly property var srcAu:  source ? source.audio : null

    function devs(wantSink) {
        const out = []
        for (const n of Pipewire.nodes.values) {
            if (!n.audio || n.isStream) continue
            if (n.isSink === wantSink) out.push(n)
        }
        return out
    }
    readonly property var sinks:   devs(true)
    readonly property var sources: devs(false)

    PwObjectTracker {
        objects: {
            const l = []
            if (root.sink) l.push(root.sink)
            if (root.source) l.push(root.source)
            for (const n of root.sinks) l.push(n)
            for (const n of root.sources) l.push(n)
            return l
        }
    }

    // all mutations run through a real Process (execDetached doesn't fire here)
    Process { id: act }
    function run(cmd) { if (act.running) act.running = false; act.command = cmd; act.running = true }

    function cycleSink() {
        if (root.sinks.length < 2) return
        const i = root.sinks.findIndex(s => s.id === (root.sink ? root.sink.id : -1))
        const n = root.sinks[(i + 1) % root.sinks.length]
        if (n) root.run(["wpctl", "set-default", String(n.id)])
    }

    // ---------- radial dial ----------
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 300

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 210; height: 210; radius: 105
            color: "transparent"; border.color: Root.Theme.border; border.width: 1
            opacity: 0; scale: 0.6
            Component.onCompleted: ringAnim.start()
            ParallelAnimation {
                id: ringAnim
                NumberAnimation { target: ring; property: "opacity"; to: 0.7; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }

        Item {
            id: hub
            anchors.centerIn: parent
            width: 150; height: 150
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: hubAnim.start()
            ParallelAnimation {
                id: hubAnim
                NumberAnimation { target: hub; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: hub; property: "scale"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            }
            Canvas {
                id: dial
                anchors.fill: parent
                property real value: root.sinkAu ? Math.max(0, Math.min(1, root.sinkAu.volume)) : 0
                property bool muted: root.sinkAu ? root.sinkAu.muted : false
                onValueChanged: requestPaint()
                onMutedChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    var cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 8
                    ctx.lineWidth = 7; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.strokeStyle = Root.Theme.surfaceGlassHi; ctx.stroke()
                    if (value > 0) {
                        ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * value)
                        ctx.strokeStyle = muted ? Root.Theme.textDim : Root.Theme.accent; ctx.stroke()
                    }
                }
            }
            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: dial.muted ? "\uf026" : "\uf028"
                    color: dial.muted ? Root.Theme.textDim : Root.Theme.accent
                    font.family: Root.Theme.fontFamily; font.pixelSize: 20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: dial.muted ? "muted" : Math.round(dial.value * 100) + "%"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily
                    font.pixelSize: 18; font.weight: Font.Bold
                }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                onWheel: (w) => root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (w.angleDelta.y > 0 ? "5%+" : "5%-")])
            }
        }

        // round − / + buttons (left / right)
        component StepBtn: Rectangle {
            id: sb
            property string glyph
            property int delay: 0
            signal activated()
            width: 50; height: 50; radius: 25
            color: sbHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass
            border.color: Root.Theme.border; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: sbAnim.start()
            SequentialAnimation {
                id: sbAnim
                PauseAnimation { duration: sb.delay }
                ParallelAnimation {
                    NumberAnimation { target: sb; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: sb; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                }
            }
            Text { anchors.centerIn: parent; text: sb.glyph; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 20 }
            MouseArea { id: sbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sb.activated() }
        }

        component Sat: Rectangle {
            id: sat
            property string label
            property string value
            property int delay: 0
            signal activated()
            width: 130; height: 44; radius: 12
            color: satHov.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass
            border.color: Root.Theme.border; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
            opacity: 0; scale: 0.5; transformOrigin: Item.Center
            Component.onCompleted: satAnim.start()
            SequentialAnimation {
                id: satAnim
                PauseAnimation { duration: sat.delay }
                ParallelAnimation {
                    NumberAnimation { target: sat; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { target: sat; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                }
            }
            Column {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                spacing: 1
                Text { text: sat.value; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; width: parent.width; elide: Text.ElideRight }
                Text { text: sat.label; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 9 }
            }
            MouseArea { id: satHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sat.activated() }
        }

        Rectangle { width: 2; height: 20; anchors.bottom: hub.top; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }
        Rectangle { width: 2; height: 20; anchors.top: hub.bottom; anchors.horizontalCenter: hub.horizontalCenter; color: Root.Theme.border; opacity: 0.6 }

        Sat {
            label: "Output · tap to switch"
            value: root.sink ? (root.sink.description || root.sink.name) : "—"
            delay: 240
            anchors.bottom: hub.top; anchors.bottomMargin: 20; anchors.horizontalCenter: hub.horizontalCenter
            onActivated: root.cycleSink()
        }
        StepBtn {
            glyph: "\uf068"   // minus
            delay: 300
            anchors.right: hub.left; anchors.rightMargin: 16; anchors.verticalCenter: hub.verticalCenter
            onActivated: root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
        }
        StepBtn {
            glyph: "\uf067"   // plus
            delay: 340
            anchors.left: hub.right; anchors.leftMargin: 16; anchors.verticalCenter: hub.verticalCenter
            onActivated: root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"])
        }
        Sat {
            label: root.srcAu && root.srcAu.muted ? "Mic · muted" : "Mic · tap to mute"
            value: "\uf130  " + (root.srcAu ? Math.round(root.srcAu.volume * 100) + "%" : "—")
            delay: 400
            anchors.top: hub.bottom; anchors.topMargin: 20; anchors.horizontalCenter: hub.horizontalCenter
            onActivated: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        }
    }

    // ---------- device lists ----------
    component DevList: ColumnLayout {
        id: dl
        property var items: []
        property var current
        property int delay: 0
        Layout.fillWidth: true
        spacing: 4
        Repeater {
            model: dl.items
            delegate: Rectangle {
                id: drow
                required property var modelData
                required property int index
                property bool isCur: modelData.id === (dl.current ? dl.current.id : -1)
                Layout.fillWidth: true
                implicitHeight: 36; radius: 10
                color: isCur ? Root.Theme.selection : (dha.containsMouse ? Root.Theme.surfaceGlassHi : Root.Theme.surfaceVeryGlass)
                Behavior on color { ColorAnimation { duration: 120 } }
                opacity: 0; scale: 0.7; transformOrigin: Item.Center
                Component.onCompleted: drowAnim.start()
                SequentialAnimation {
                    id: drowAnim
                    PauseAnimation { duration: dl.delay + drow.index * 45 }
                    ParallelAnimation {
                        NumberAnimation { target: drow; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { target: drow; property: "scale"; to: 1; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }
                }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                    Text { text: "\uf00c"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 12; visible: drow.isCur }
                    Text { text: modelData.description || modelData.nickname || modelData.name || "device"; color: drow.isCur ? Root.Theme.text : Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                MouseArea { id: dha; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["wpctl", "set-default", String(modelData.id)]) }
            }
        }
    }

    Text { text: "Output devices"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    DevList { items: root.sinks; current: root.sink; delay: 440 }
    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Theme.border; opacity: 0.5 }
    Text { text: "Input devices"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
    DevList { items: root.sources; current: root.source; delay: 520 }
}