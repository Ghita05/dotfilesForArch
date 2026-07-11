import QtQuick
import "../.." as Root
import qs.services

Rectangle {
    id: root

    // surface & palette — darker, high-contrast card
    readonly property color cSurface: "#f20d0f14"
    readonly property color cSurfaceHi: "#ff161a22"
    readonly property color cRow: "#cc12151c"
    readonly property color cAccent: "#6a85a8"
    readonly property color cText: "#e2e6ee"
    readonly property color cDim: "#8a90a0"
    readonly property color cFaint: "#565c6a"
    readonly property color cGood: "#7fa886"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property bool open: Root.PopupState.active === "vms"

    property string expandedUuid: ""

    width: 340
    height: col.implicitHeight + 32
    radius: 20
    color: cSurface
    border.width: 1
    border.color: Qt.alpha("#ffffff", 0.08)

    visible: opacity > 0
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.96
    transformOrigin: Item.Top

    Behavior on opacity {
        NumberAnimation { duration: 180 }
    }

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Swallow clicks on the popup body so the fullscreen
    // click-catcher underneath doesn't dismiss us
    MouseArea {
        anchors.fill: parent
    }

    onOpenChanged: {
        if (open) {
            VmService.refresh()
        } else {
            expandedUuid = ""
        }
    }

    Timer {
        running: root.open
        interval: 5000
        repeat: true
        onTriggered: VmService.refresh()
    }

    Column {
        id: col
        width: parent.width - 32
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        // ---------- header ----------
        Item {
            width: col.width
            height: 26

            Text {
                id: hdrIcon
                text: "\uf1b2"
                color: root.cAccent
                font.family: root.fontFamily
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: hdrTitle
                anchors.left: hdrIcon.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Virtual Machines"
                color: root.cText
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                anchors.left: hdrTitle.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: VmService.runningCount > 0
                width: badge.implicitWidth + 14
                height: 18
                radius: 9
                color: Qt.alpha(root.cGood, 0.15)
                border.width: 1
                border.color: Qt.alpha(root.cGood, 0.4)

                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: VmService.runningCount + " up"
                    color: root.cGood
                    font.family: root.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: refreshMouse.containsMouse
                    ? Qt.alpha(root.cAccent, 0.2)
                    : Qt.alpha("#ffffff", 0.04)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "\uf021"
                    color: refreshMouse.containsMouse ? root.cAccent : root.cDim
                    font.family: root.fontFamily
                    font.pixelSize: 10
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VmService.refresh()
                }
            }
        }


        Text {
            visible: VmService.vms.length === 0
            text: "No VMs registered"
            color: root.cDim
            font.family: root.fontFamily
            font.pixelSize: 11
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // ---------- VM rows ----------
        Repeater {
            model: VmService.vms

            delegate: Rectangle {
                id: vmRow
                required property var modelData
                readonly property bool expanded: root.expandedUuid === modelData.uuid
                readonly property bool infoReady:
                    VmService.infoUuid === modelData.uuid
                    && VmService.info.VMState !== undefined

                width: col.width
                height: 44 + (expanded ? detail.height + 14 : 0)
                radius: 14
                clip: true
                color: vmRow.expanded
                    ? root.cSurfaceHi
                    : (headMouse.containsMouse
                        ? Qt.lighter(root.cRow, 1.25)
                        : root.cRow)
                border.width: 1
                border.color: modelData.running
                    ? Qt.alpha(root.cGood, 0.35)
                    : Qt.alpha("#ffffff", 0.06)

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                // ---- collapsed header row ----
                Item {
                    id: head
                    width: parent.width
                    height: 44

                    MouseArea {
                        id: headMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (vmRow.expanded) {
                                root.expandedUuid = ""
                            } else {
                                root.expandedUuid = vmRow.modelData.uuid
                                VmService.fetchInfo(vmRow.modelData.uuid)
                            }
                        }
                    }

                    // status dot with a soft halo when running
                    Rectangle {
                        id: halo
                        width: 16
                        height: 16
                        radius: 8
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: vmRow.modelData.running
                            ? Qt.alpha(root.cGood, 0.18)
                            : "transparent"

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.centerIn: parent
                            color: vmRow.modelData.running
                                ? root.cGood
                                : Qt.alpha(root.cFaint, 0.8)
                        }
                    }

                    Text {
                        anchors.left: halo.right
                        anchors.leftMargin: 10
                        anchors.right: statePill.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: vmRow.modelData.name
                        color: root.cText
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.bold: vmRow.modelData.running
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: statePill
                        anchors.right: chev.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: stateTxt.implicitWidth + 14
                        height: 18
                        radius: 9
                        color: vmRow.modelData.running
                            ? Qt.alpha(root.cGood, 0.12)
                            : Qt.alpha(root.cFaint, 0.12)

                        Text {
                            id: stateTxt
                            anchors.centerIn: parent
                            text: vmRow.modelData.running ? "on" : "off"
                            color: vmRow.modelData.running ? root.cGood : root.cDim
                            font.family: root.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    Text {
                        id: chev
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf078"
                        color: root.cFaint
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        rotation: vmRow.expanded ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // ---- expanded detail ----
                Column {
                    id: detail
                    anchors.top: head.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10
                    opacity: vmRow.expanded ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 180 }
                    }

                    // aligned key/value grid
                    Grid {
                        columns: 2
                        columnSpacing: 14
                        rowSpacing: 4

                        Text {
                            text: "os"
                            color: root.cFaint
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            text: vmRow.infoReady
                                ? (VmService.info.ostype || "\u2014")
                                : "\u2026"
                            color: root.cDim
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "memory"
                            color: root.cFaint
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            text: vmRow.infoReady && VmService.info.memory !== undefined
                                ? VmService.info.memory + " MB"
                                : "\u2026"
                            color: root.cDim
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "cpus"
                            color: root.cFaint
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            text: vmRow.infoReady && VmService.info.cpus !== undefined
                                ? VmService.info.cpus
                                : "\u2026"
                            color: root.cDim
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "state"
                            color: root.cFaint
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            text: vmRow.infoReady
                                ? (VmService.info.VMState || "\u2014")
                                : "\u2026"
                            color: root.cDim
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    // action buttons: filled primary + outlined secondary
                    Row {
                        spacing: 8

                        Repeater {
                            model: vmRow.modelData.running
                                ? [
                                    { icon: "\uf011", label: "shutdown", act: "shutdown", primary: true },
                                    { icon: "\uf1e6", label: "kill", act: "force", primary: false }
                                ]
                                : [
                                    { icon: "\uf04b", label: "start", act: "start", primary: true },
                                    { icon: "\uf2d2", label: "headless", act: "headless", primary: false }
                                ]

                            delegate: Rectangle {
                                required property var modelData
                                width: btnRow.implicitWidth + 24
                                height: 28
                                radius: 14
                                color: modelData.primary
                                    ? (btnMouse.containsMouse
                                        ? Qt.lighter(root.cAccent, 1.15)
                                        : root.cAccent)
                                    : (btnMouse.containsMouse
                                        ? Qt.alpha(root.cAccent, 0.15)
                                        : "transparent")
                                border.width: modelData.primary ? 0 : 1
                                border.color: Qt.alpha(root.cAccent, 0.4)

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Row {
                                    id: btnRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        color: modelData.primary ? "#0d0f14" : root.cAccent
                                        font.family: root.fontFamily
                                        font.pixelSize: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        color: modelData.primary ? "#0d0f14" : root.cText
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        font.bold: modelData.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const u = vmRow.modelData.uuid
                                        switch (modelData.act) {
                                        case "start":    VmService.start(u); break
                                        case "headless": VmService.startHeadless(u); break
                                        case "shutdown": VmService.shutdown(u); break
                                        case "force":    VmService.forceOff(u); break
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 4 }
                }
            }
        }
    }
}