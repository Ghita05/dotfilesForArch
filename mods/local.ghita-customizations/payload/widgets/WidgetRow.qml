import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.config

// Shared clickable row for list-style desktop app widgets (VS Code,
// Firefox, File Manager). No per-row background box — separation comes
// from type hierarchy (bold full-opacity primary line, small dim
// secondary line) and a hairline divider, with a faint wash on hover/
// press instead of a solid container.
Item {
    id: root

    property string iconGlyph: ""
    property string primaryText: ""
    property string secondaryText: ""
    property bool showDivider: true

    signal clicked

    implicitHeight: contentRow.implicitHeight + 10

    Rectangle {
        anchors.fill: parent
        radius: Styling.radius(-8)
        color: Colors.overBackground
        opacity: hoverHandler.hovered ? (tapHandler.pressed ? 0.1 : 0.05) : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 6
        spacing: 7

        Text {
            visible: root.iconGlyph.length > 0
            text: root.iconGlyph
            font.family: Icons.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            opacity: 0.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.primaryText
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                font.weight: Font.Medium
                color: Colors.overBackground
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.secondaryText.length > 0
                text: root.secondaryText
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
                color: Colors.overBackground
                opacity: 0.5
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        visible: root.showDivider
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.overBackground
        opacity: 0.08
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }
}
