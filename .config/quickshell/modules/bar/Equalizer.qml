import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

// Bottom-left EQ. Coexists with other overlays (mask = card only).
// Toggle: qs ipc call eq toggle  •  Close: Escape or the X.
PanelWindow {
    id: root
    visible: Root.EqService.open
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore

    // input region tracks the card's REAL geometry (no transform desync)
    mask: Region { item: card }

    Component.onCompleted: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.layer = WlrLayer.Overlay
    }
    onVisibleChanged: {
        if (this.WlrLayershell != null)
            this.WlrLayershell.keyboardFocus = visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    }

    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: Root.EqService.open = false

        Rectangle {
            id: card
            width: 560
            height: 372
            radius: 20

            // anchored bottom-left; slide-in by animating the REAL margin (mask follows)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottomMargin: root.visible ? 16 : -(card.height + 40)
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

            opacity: root.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // mostly-solid: opaque slate, readable on any wallpaper
            color: Qt.rgba(0.07, 0.08, 0.10, 0.96)
            border.color: Root.Theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                // ---- header ----
                Item {
                    width: parent.width
                    height: 28
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9
                        Text {
                            text: "\uf001"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            color: Root.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Equalizer"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            color: Root.Theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 30
                            height: 24
                            radius: 12
                            color: Root.EqService.enabled ? Root.Theme.accent : Root.Theme.surface
                            border.color: Root.EqService.enabled ? Root.Theme.accent : Root.Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 180 } }
                            Text {
                                anchors.centerIn: parent
                                text: "\uf011"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 11
                                color: Root.EqService.enabled ? Root.Theme.base : Root.Theme.textDim
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Root.EqService.setEnabled(!Root.EqService.enabled)
                            }
                        }
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: closeHov.containsMouse ? Root.Theme.surface : "transparent"
                            border.color: Root.Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Text {
                                anchors.centerIn: parent
                                text: "\uf00d"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: closeHov.containsMouse ? Root.Theme.text : Root.Theme.textDim
                            }
                            MouseArea {
                                id: closeHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Root.EqService.open = false
                            }
                        }
                    }
                }

                // ---- band sliders ----
                Row {
                    id: bandRow
                    width: parent.width
                    height: 214
                    spacing: (width - (10 * 40)) / 9

                    Repeater {
                        model: 10
                        delegate: Item {
                            id: band
                            required property int index
                            width: 40
                            height: bandRow.height
                            opacity: Root.EqService.enabled ? 1 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            readonly property real g: Root.EqService.gains[index]
                            readonly property int trackH: 150

                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (band.g > 0 ? "+" : "") + band.g.toFixed(0)
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Math.abs(band.g) < 0.5 ? Root.Theme.textDim : Root.Theme.accent
                                }

                                Item {
                                    id: sliderArea
                                    width: 30
                                    height: band.trackH
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        id: track
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 5
                                        height: parent.height
                                        radius: 2.5
                                        color: Root.Theme.surface
                                        border.color: Root.Theme.border
                                        border.width: 1
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: parent.height / 2
                                        width: 13
                                        height: 1
                                        color: Root.Theme.border
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 5
                                        radius: 2.5
                                        color: Root.Theme.accent
                                        property real centerY: sliderArea.height / 2
                                        property real thumbY: sliderArea.height * (Root.EqService.range - band.g) / (2 * Root.EqService.range)
                                        y: Math.min(centerY, thumbY)
                                        height: Math.abs(centerY - thumbY)
                                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                    }
                                    Rectangle {
                                        id: thumb
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 16
                                        height: 16
                                        radius: 8
                                        y: sliderArea.height * (Root.EqService.range - band.g) / (2 * Root.EqService.range) - height / 2
                                        color: grab.containsMouse || grab.pressed ? Root.Theme.accentBright : Root.Theme.text
                                        border.color: Root.Theme.accent
                                        border.width: 1
                                        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        scale: grab.pressed ? 1.18 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                    }
                                    MouseArea {
                                        id: grab
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        function apply(my) {
                                            var yy = Math.max(0, Math.min(sliderArea.height, my))
                                            var gain = Root.EqService.range * (1 - 2 * yy / sliderArea.height)
                                            Root.EqService.setBand(band.index, gain)
                                        }
                                        onPressed: function (m) { apply(m.y) }
                                        onPositionChanged: function (m) { if (pressed) apply(m.y) }
                                        onReleased: Root.EqService.commit()
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Root.EqService.freqs[band.index]
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Root.Theme.textDim
                                }
                            }
                        }
                    }
                }

                // ---- preset segmented buttons ----
                Row {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: Root.EqService.presetNames
                        delegate: Rectangle {
                            id: preset
                            required property var modelData
                            readonly property bool active: Root.EqService.activePreset === modelData
                            height: 30
                            width: (parent.width - (4 * 7)) / 5
                            radius: 10
                            color: active ? Root.Theme.accent
                                          : (pHov.containsMouse ? Root.Theme.surface : Root.Theme.surfaceVeryGlass)
                            border.color: active ? Root.Theme.accent
                                                 : (pHov.containsMouse ? Root.Theme.selectionStrong : Root.Theme.border)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 160 } }

                            scale: pHov.pressed ? 0.96 : 1.0
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    visible: preset.active
                                    text: "\uf00c"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Root.Theme.base
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: preset.modelData
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    color: preset.active ? Root.Theme.base : Root.Theme.text
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: pHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Root.EqService.applyPreset(preset.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}