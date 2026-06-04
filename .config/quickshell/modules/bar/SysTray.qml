import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../.." as Root

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 22

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items
            delegate: Item {
                required property var modelData
                width: 18
                height: 18

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (m) => {
                        if (m.button === Qt.LeftButton) modelData.activate()
                        else modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}