import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.config

// Shared empty state for every desktop app widget, so a tile with nothing
// to show still looks intentional instead of a blank/broken card.
ColumnLayout {
    id: root
    property string message: "No data"
    property string iconGlyph: Icons.info
    property bool compact: false

    anchors.centerIn: parent
    spacing: 4

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: !root.compact
        text: root.iconGlyph
        font.family: Icons.font
        font.pixelSize: Styling.fontSize(6)
        color: Colors.overBackground
        opacity: 0.2
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: root.parent ? root.parent.width - 20 : 200
        text: root.message
        font.family: Config.theme.font
        font.pixelSize: Styling.fontSize(root.compact ? -3 : -2)
        color: Colors.overBackground
        opacity: 0.4
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
