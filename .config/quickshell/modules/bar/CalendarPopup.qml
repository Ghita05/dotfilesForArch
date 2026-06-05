import QtQuick
import "../.." as Root

Item {
    id: root
    readonly property bool shown: Root.PopupState.active === "calendar"
    property int monthOffset: 0
    property bool expanded: false
    property int selectedDay: 0
    onShownChanged: if (shown) { monthOffset = 0; expanded = false; selectedDay = 0 }

    implicitWidth: 300
    implicitHeight: card.height
    visible: shown

    readonly property var vd: new Date(new Date().getFullYear(), new Date().getMonth() + monthOffset, 1)
    readonly property int year: vd.getFullYear()
    readonly property int month: vd.getMonth()
    readonly property var today: new Date()

    function buildCells() {
        const first = new Date(year, month, 1)
        const lead = (first.getDay() + 6) % 7
        const count = new Date(year, month + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < lead; i++) cells.push(0)
        for (let d = 1; d <= count; d++) cells.push(d)
        return cells
    }
    readonly property var cells: buildCells()
    function isToday(d) { return d > 0 && monthOffset === 0 && d === today.getDate() && month === today.getMonth() && year === today.getFullYear() }

    Rectangle {
        id: card
        width: parent.width
        height: content.implicitHeight + 32
        radius: 18
        color: Root.Theme.surfaceGlass; border.color: Root.Theme.border; border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        clip: true
        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 12

            Item {
                width: parent.width; height: 20
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
                        text: root.expanded ? "\uf078" : "\uf077"   // chevron down / up
                        color: root.expanded ? Root.Theme.accent : Root.Theme.textDim
                        font.family: Root.Theme.fontFamily; font.pixelSize: 11
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = !root.expanded }
                    }
                }
            }

            Row {
                width: parent.width
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Item {
                        required property var modelData
                        width: parent.width / 7; height: 18
                        Text { anchors.centerIn: parent; text: modelData; color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 10 }
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 7
                Repeater {
                    model: root.cells
                    delegate: Item {
                        required property var modelData
                        width: parent.width / 7
                        height: root.expanded ? 36 : 26
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData > 0
                            width: root.expanded ? 30 : 22; height: width; radius: width / 2
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
                                font.pixelSize: root.expanded ? 13 : 11
                                font.weight: root.isToday(modelData) ? Font.Bold : Font.Normal
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (modelData > 0) root.selectedDay = modelData }
                        }
                    }
                }
            }

            // expanded detail panel
            Rectangle {
                width: parent.width; radius: 12
                color: Root.Theme.surfaceVeryGlass
                visible: root.expanded
                height: root.expanded ? 64 : 0
                Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Column {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
                    spacing: 3
                    Text {
                        text: root.selectedDay > 0
                            ? Qt.formatDate(new Date(root.year, root.month, root.selectedDay), "dddd, MMMM d")
                            : "Pick a day"
                        color: Root.Theme.text; font.family: Root.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    }
                    Text {
                        text: "No events"
                        color: Root.Theme.textDim; font.family: Root.Theme.fontFamily; font.pixelSize: 11
                    }
                }
            }
        }
    }
}