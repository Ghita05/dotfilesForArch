import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "reminders"
    implicitWidth: 300
    implicitHeight: card.height
    visible: shown

    Rectangle {
        id: card
        width: parent.width; height: content.implicitHeight + 32; radius: 18
        color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 10
            Text { text: "Reminders"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }

            Repeater {
                model: Root.PersistState.reminders.slice().sort((a, b) => a.ts - b.ts)
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 32; radius: 8; color: Root.Theme.surfaceVeryGlass
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text { text: Qt.formatDateTime(new Date(modelData.ts), "MMM d HH:mm"); color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                        Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.text; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                        Text {
                            text: "\uf00d"; color: rmHov.containsMouse ? Root.Theme.crit : Root.Theme.textDim
                            font.family: Root.Theme.fontFamily; font.pixelSize: 11
                            MouseArea { id: rmHov; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Root.PersistState.removeReminder(modelData.ts, modelData.text) }
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 64; Layout.preferredHeight: 32; radius: 8
                    color: Root.Theme.surfaceVeryGlass; border.color: minInput.activeFocus ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
                    TextInput {
                        id: minInput
                        anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter
                        text: "10"; validator: IntValidator { bottom: 1; top: 1440 }
                        color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11; selectByMouse: true
                    }
                }
                Text { text: "min"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 8
                    color: Root.Theme.surfaceVeryGlass; border.color: txtInput.activeFocus ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
                    TextInput {
                        id: txtInput
                        anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter; clip: true; selectByMouse: true
                        color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11
                        onAccepted: root.addNow()
                        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "What…"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; visible: txtInput.text.length === 0 && !txtInput.activeFocus }
                    }
                    MouseArea { anchors.fill: parent; onClicked: txtInput.forceActiveFocus() }
                }

                Rectangle {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8
                    color: Root.Theme.selection; border.color: Root.Theme.selectionStrong; border.width: 1
                    Text { anchors.centerIn: parent; text: "\uf067"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.addNow() }
                }
            }
        }
    }

    function addNow() {
        const mins = parseInt(minInput.text) || 10
        if (txtInput.text.length === 0) return
        Root.PersistState.addReminder(Date.now() + mins * 60000, txtInput.text)
        txtInput.text = ""
    }
}