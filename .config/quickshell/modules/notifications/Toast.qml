import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../.." as Root

Rectangle {
    id: toast
    property var notif

    implicitHeight: Math.max(content.implicitHeight, iconImg.visible ? 40 : 0) + 28
    radius: 16
    color: Root.Theme.surfaceGlass
    border.width: 1
    border.color: (notif && notif.urgency === NotificationUrgency.Critical)
                  ? Root.Theme.crit
                  : Root.Theme.border

    // slide-in from the right + fade
    opacity: 0
    x: 24
    Component.onCompleted: { opacity = 1; x = 0 }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on x       { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // mako parity: low 4s, normal 5s, critical persists; hover pauses
    Timer {
        interval: (notif && notif.urgency === NotificationUrgency.Low) ? 4000 : 5000
        running: notif && notif.urgency !== NotificationUrgency.Critical && !hover.containsMouse
        onTriggered: if (notif) notif.dismiss()
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (notif) notif.dismiss()   // click anywhere = dismiss
    }

    Item {
        anchors.fill: parent
        anchors.margins: 14

        Image {
            id: iconImg
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40
            sourceSize.width: 40; sourceSize.height: 40
            fillMode: Image.PreserveAspectFit
            visible: source != ""
            source: {
                if (!notif) return ""
                if (notif.image && notif.image !== "") return notif.image
                if (notif.appIcon && notif.appIcon !== "")
                    return Quickshell.iconPath(notif.appIcon, "dialog-information")
                return ""
            }
        }

        Column {
            id: content
            anchors.left: iconImg.visible ? iconImg.right : parent.left
            anchors.leftMargin: iconImg.visible ? 12 : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                visible: text.length > 0
                width: parent.width
                text: notif ? notif.appName : ""
                color: Root.Theme.textDim
                font.family: Root.Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: notif ? notif.summary : ""
                color: Root.Theme.text
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.SemiBold
                elide: Text.ElideRight
            }
            Text {
                visible: text.length > 0
                width: parent.width
                text: notif ? notif.body : ""
                color: Root.Theme.textGlassy
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                textFormat: Text.StyledText        // renders pango subset (<b>, <i>, <a>)
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // action buttons, only if the app sent any
            Row {
                spacing: 6
                visible: notif && notif.actions.length > 0
                Repeater {
                    model: notif ? notif.actions : []
                    delegate: Rectangle {
                        required property var modelData
                        height: 24
                        width: actLabel.implicitWidth + 20
                        radius: 8
                        color: actHover.containsMouse ? Root.Theme.selection : Root.Theme.surfaceVeryGlass
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: actLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Root.Theme.text
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: actHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}