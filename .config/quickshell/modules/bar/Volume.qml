import QtQuick
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

    Row {
        id: row
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "\uf026" : root.vol < 50 ? "\uf027" : "\uf028"
            color: hover.containsMouse ? Root.Theme.accentSoft : Root.Theme.accent
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "muted" : root.vol + "%"
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("volume")
        onWheel: (w) => {
            if (!root.sink || !root.sink.audio) return
            const step = w.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
        }
    }
}