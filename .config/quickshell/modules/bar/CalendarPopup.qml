import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "calendar"
    property int monthOffset: 0
    property bool expanded: false
    property int selectedDay: 0
    onShownChanged: if (shown) { monthOffset = 0; expanded = false; selectedDay = today.getDate() }

    implicitWidth: 320
    implicitHeight: card.implicitHeight
    visible: shown

    readonly property var vd: new Date(new Date().getFullYear(), new Date().getMonth() + monthOffset, 1)
    readonly property int year: vd.getFullYear()
    readonly property int month: vd.getMonth()
    readonly property var today: new Date()

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function dateKey(d) { return root.year + "-" + pad(root.month + 1) + "-" + pad(d) }
    function buildCells() {
        const f = new Date(year, month, 1)
        const lead = (f.getDay() + 6) % 7
        const c = new Date(year, month + 1, 0).getDate()
        const out = []
        for (let i = 0; i < lead; i++) out.push(0)
        for (let d = 1; d <= c; d++) out.push(d)
        return out
    }
    readonly property var cells: buildCells()
    function isToday(d) { return d > 0 && monthOffset === 0 && d === today.getDate() && month === today.getMonth() && year === today.getFullYear() }
    function hasEvents(d) { return d > 0 && Root.PersistState.eventsFor(dateKey(d)).length > 0 }
    readonly property var selEvents: selectedDay > 0 ? Root.PersistState.eventsFor(dateKey(selectedDay)) : []

    function addEvent() {
        if (addInput.text.length === 0) return
        const raw = timeInput.text.replace(":", "")
        const hasTime = raw.length === 4
        const label = (hasTime ? timeInput.text + "  " : "") + addInput.text
        Root.PersistState.addEvent(dateKey(selectedDay), label)
        if (hasTime) {
            const hh = parseInt(timeInput.text.substring(0, 2))
            const mm = parseInt(timeInput.text.substring(3, 5))
            if (hh < 24 && mm < 60) {
                const when = new Date(year, month, selectedDay, hh, mm).getTime()
                if (when > Date.now()) Root.PersistState.addReminder(when, addInput.text)
            }
        }
        addInput.text = ""; timeInput.text = ""
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: content.implicitHeight + 32
        radius: 18
        color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        clip: true
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 12

            // header
            Item {
                Layout.fillWidth: true
                height: 20
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "\uf053"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset-- }
                }
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(root.vd, "MMMM yyyy")
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                }
                Row {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    Text {
                        text: "\uf054"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 12
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset++ }
                    }
                    Text {
                        text: root.expanded ? "\uf078" : "\uf077"
                        color: root.expanded ? Root.Theme.accent : Root.Theme.textDim
                        font.family: Root.Theme.fontFamily; font.pixelSize: 11
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = !root.expanded }
                    }
                }
            }

            // weekday header
            Row {
                Layout.fillWidth: true
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Item {
                        required property var modelData
                        width: (content.width) / 7; height: 18
                        Text { anchors.centerIn: parent; text: modelData; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                    }
                }
            }

            // day grid
            Grid {
                Layout.fillWidth: true
                columns: 7
                Repeater {
                    model: root.cells
                    delegate: Item {
                        required property var modelData
                        width: (content.width) / 7
                        height: root.expanded ? 34 : 26
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData > 0
                            width: root.expanded ? 28 : 22; height: width; radius: width / 2
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            property bool sel: modelData === root.selectedDay
                            color: root.isToday(modelData) ? Root.Theme.selection : (sel ? Root.Theme.surfaceGlassHi : "transparent")
                            border.color: root.isToday(modelData) ? Root.Theme.selectionStrong : (sel ? Root.Theme.border : "transparent")
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData > 0 ? modelData : ""
                                color: root.isToday(modelData) ? Root.Theme.text : Root.Theme.textGlassy
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: root.expanded ? 12 : 11
                                font.weight: root.isToday(modelData) ? Font.Bold : Font.Normal
                            }
                            Rectangle {
                                visible: root.hasEvents(modelData)
                                width: 4; height: 4; radius: 2; color: Root.Theme.accent
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (modelData > 0) { root.selectedDay = modelData; root.expanded = true } }
                        }
                    }
                }
            }

            // expanded detail
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.expanded

                Text {
                    Layout.fillWidth: true
                    text: root.selectedDay > 0 ? Qt.formatDate(new Date(root.year, root.month, root.selectedDay), "dddd, MMMM d") : "Pick a day"
                    color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium
                }

                Repeater {
                    model: root.selEvents
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30; radius: 8
                        color: Root.Theme.surfaceVeryGlass
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                            Text { text: "\uf111"; color: Root.Theme.accent; font.family: Root.Theme.fontFamily; font.pixelSize: 7 }
                            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.text; color: Root.Theme.textGlassy; font.family: Root.Theme.fontFamily; font.pixelSize: 11 }
                            Text {
                                text: "\uf00d"; color: evHov.containsMouse ? Root.Theme.crit : Root.Theme.textDim
                                font.family: Root.Theme.fontFamily; font.pixelSize: 11
                                MouseArea { id: evHov; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Root.PersistState.removeEvent(root.dateKey(root.selectedDay), modelData.text) }
                            }
                        }
                    }
                }

                // add row: time + text + button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.selectedDay > 0

                    Rectangle {
                        Layout.preferredWidth: 60; Layout.preferredHeight: 32; radius: 8
                        color: Root.Theme.surfaceVeryGlass; border.color: timeInput.activeFocus ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
                        TextInput {
                            id: timeInput
                            anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter
                            inputMask: "99:99"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11; selectByMouse: true
                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "HH:MM"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; visible: timeInput.text.replace(":", "").length === 0 && !timeInput.activeFocus }
                        }
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onPressed: timeInput.forceActiveFocus() }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 8
                        color: Root.Theme.surfaceVeryGlass; border.color: addInput.activeFocus ? Root.Theme.selectionStrong : Root.Theme.border; border.width: 1
                        TextInput {
                            id: addInput
                            anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter; clip: true; selectByMouse: true
                            color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 11
                            onAccepted: root.addEvent()
                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Add event…"; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11; visible: addInput.text.length === 0 && !addInput.activeFocus }
                        }
                        MouseArea { anchors.fill: parent; onClicked: addInput.forceActiveFocus() }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8
                        color: Root.Theme.selection; border.color: Root.Theme.selectionStrong; border.width: 1
                        Text { anchors.centerIn: parent; text: "\uf067"; color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.addEvent() }
                    }
                }
            }
        }
    }
}