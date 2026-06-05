import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

Item {
    id: root
    property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property int vol: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    Process { id: act }
    function run(c) { if (act.running) act.running = false; act.command = c; act.running = true }

    Row {
        id: row
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "\uf026" : root.vol < 50 ? "\uf027" : "\uf028"
            color: hov.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent
            font.family: Root.Theme.fontFamily; font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "muted" : root.vol + "%"
            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12
        }
    }
    MouseArea {
        id: hov
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: root.run(["qs", "ipc", "call", "controlCenter", "openTab", "audio"])
        onWheel: (w) => root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (w.angleDelta.y > 0 ? "5%+" : "5%-")])
    }
}