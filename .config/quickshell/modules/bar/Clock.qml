import QtQuick
import "../.." as Root

Item {
    id: root
    property var now: new Date()
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root.now, "ddd, MMM d")
            color: Root.Theme.textDim
            font.family: Root.Theme.fontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Root.PopupState.toggle("calendar")
    }
}