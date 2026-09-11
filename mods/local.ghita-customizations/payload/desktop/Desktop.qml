import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.services
import qs.modules.theme
import qs.modules.components
import qs.config

// Desktop widget tiles: persistent, always-visible quick-launch cards living
// on the wallpaper, in the visual language of the dashboard's own cards
// (StyledRect "pane" variant — same gradient/border/shadow resolution as
// theme.json drives everywhere else). Replaces the old file-icon desktop
// grid entirely (dropped, not hidden behind a toggle — icon and widget
// layers were not meant to coexist here).
PanelWindow {
    id: desktop

    property int barSize: Config.showBackground ? 44 : 40
    property string barPosition: ["top", "bottom", "left", "right"].includes(Config.bar.position) ? Config.bar.position : "top"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "ambxst:desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    visible: Config.desktop.enabled && Config.desktop.widgets.enabled

    readonly property var widgetsConfig: Config.desktop.widgets
    readonly property bool anchorTop: widgetsConfig.position.indexOf("top") === 0
    readonly property bool anchorLeft: widgetsConfig.position.indexOf("left") !== -1

    Column {
        id: tileColumn
        spacing: desktop.widgetsConfig.spacing

        anchors {
            top: desktop.anchorTop ? parent.top : undefined
            bottom: desktop.anchorTop ? undefined : parent.bottom
            left: desktop.anchorLeft ? parent.left : undefined
            right: desktop.anchorLeft ? undefined : parent.right
            topMargin: (desktop.anchorTop && desktop.barPosition === "top" ? desktop.barSize : 0) + desktop.widgetsConfig.margin
            bottomMargin: (!desktop.anchorTop && desktop.barPosition === "bottom" ? desktop.barSize : 0) + desktop.widgetsConfig.margin
            leftMargin: (desktop.anchorLeft && desktop.barPosition === "left" ? desktop.barSize : 0) + desktop.widgetsConfig.margin
            rightMargin: (!desktop.anchorLeft && desktop.barPosition === "right" ? desktop.barSize : 0) + desktop.widgetsConfig.margin
        }

        Repeater {
            model: desktop.widgetsConfig.tiles

            delegate: StyledRect {
                id: tile
                required property string modelData
                readonly property var entry: DesktopEntries.heuristicLookup(modelData)

                variant: "pane"
                enableShadow: true
                width: desktop.widgetsConfig.tileSize
                height: desktop.widgetsConfig.tileSize
                radius: Styling.radius(4)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (tile.entry) {
                            AppSearch.launchApp(tile.entry);
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: desktop.widgetsConfig.tileSize * 0.4
                            Layout.preferredHeight: desktop.widgetsConfig.tileSize * 0.4
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            source: tile.entry ? "image://icon/" + tile.entry.icon : "image://icon/image-missing"
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "image://icon/image-missing";
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: desktop.widgetsConfig.tileSize - 16
                            text: tile.entry ? tile.entry.name : tile.modelData
                            color: Config.resolveColor(Config.desktop.textColor)
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }
                }
            }
        }
    }
}
