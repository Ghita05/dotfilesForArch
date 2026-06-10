import QtQuick
import "../.." as Root

// Bar cluster: SEND button + RECEIVE toggle + one icon chip per connected device.
Row {
    id: deviceStatus
    spacing: 7

    // ---- SEND: pick file -> scan -> picker overlay ----
    Rectangle {
        id: sendBtn
        height: 24
        width: 28
        radius: height / 2
        color: sendHov.containsMouse ? Root.Theme.surface : Root.Theme.surfaceGlass
        border.color: Root.Theme.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        transform: Scale {
            origin.x: sendBtn.width / 2
            origin.y: sendBtn.height / 2
            xScale: sendHov.containsMouse ? 1.08 : 1.0
            yScale: sendHov.containsMouse ? 1.08 : 1.0
            Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        Text {
            anchors.centerIn: parent
            text: "\uf1d8"                  // paper-plane (send)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            color: sendHov.containsMouse ? Root.Theme.accent : Root.Theme.text
        }
        MouseArea {
            id: sendHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.Devices.pickAndSend()
        }
    }

    // ---- RECEIVE: toggle recv daemon; filled accent when armed ----
    Rectangle {
        id: recvBtn
        height: 24
        width: 28
        radius: height / 2
        color: Root.Devices.receiving
               ? Root.Theme.accent
               : (recvHov.containsMouse ? Root.Theme.surface : Root.Theme.surfaceGlass)
        border.color: Root.Devices.receiving ? Root.Theme.accent : Root.Theme.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        transform: Scale {
            origin.x: recvBtn.width / 2
            origin.y: recvBtn.height / 2
            xScale: recvHov.containsMouse ? 1.08 : 1.0
            yScale: recvHov.containsMouse ? 1.08 : 1.0
            Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        Text {
            anchors.centerIn: parent
            text: "\uf019"                  // download (receive)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            color: Root.Devices.receiving
                   ? Root.Theme.base
                   : (recvHov.containsMouse ? Root.Theme.accent : Root.Theme.text)
        }
        MouseArea {
            id: recvHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.Devices.toggleReceive()
        }
    }

    // ---- connected device chips (icon only) ----
    Repeater {
        model: Root.Devices.connected
        delegate: Rectangle {
            id: chip
            required property var modelData
            height: 24
            width: 28
            radius: height / 2
            color: (chipHov.containsMouse || Root.Devices.detailId === chip.modelData.id)
                   ? Root.Theme.surface : Root.Theme.surfaceGlass
            border.color: Root.Theme.accent
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
            scale: 0.0
            Component.onCompleted: chip.scale = 1.0
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
            transform: Scale {
                origin.x: chip.width / 2
                origin.y: chip.height / 2
                xScale: chipHov.containsMouse ? 1.08 : 1.0
                yScale: chipHov.containsMouse ? 1.08 : 1.0
                Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            function typeGlyph(n) {
                var s = String(n)
                if (s.indexOf("iPad") !== -1)   return "\uf10a"
                if (s.indexOf("iPhone") !== -1) return "\uf10b"
                return "\uf179"
            }
            Text {
                anchors.centerIn: parent
                text: chip.typeGlyph(chip.modelData.name)
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                color: Root.Theme.accent
            }
            MouseArea {
                id: chipHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.Devices.openDetail(chip.modelData.id)
            }
        }
    }
}