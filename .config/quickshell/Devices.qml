pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ===== device data (KDE Connect) =====
    property var devices: []
    property string lastRaw: ""
    readonly property var connected: devices.filter(function (d) { return d.reachable === true })

    function deviceById(id) {
        for (var i = 0; i < devices.length; i++)
            if (devices[i].id === id)
                return devices[i]
        return null
    }

    property Process poll: Process {
        command: ["bash", "/home/ghita/.config/quickshell/scripts/kdeconnect-devices.sh"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                var t = collector.text.trim()
                if (t === root.lastRaw)
                    return
                root.lastRaw = t
                try {
                    root.devices = JSON.parse(t)
                } catch (e) {
                    root.devices = []
                }
            }
        }
    }

    property Timer ticker: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll.running = true
    }

    // ===== detail popup state =====
    property string detailId: ""
    function openDetail(id) {
        root.detailId = (root.detailId === id ? "" : id)
    }
    function closeDetail() {
        root.detailId = ""
    }

    // ===== LocalSend: SEND flow =====
    property string pendingFile: ""
    property var sendTargets: []
    property bool picking: false

    property Process picker: Process {
        command: ["zenity", "--file-selection", "--title=Send via LocalSend"]
        stdout: StdioCollector {
            id: pickerOut
            onStreamFinished: {
                var f = pickerOut.text.trim()
                if (f === "")
                    return
                root.pendingFile = f
                root.scan.running = true
            }
        }
    }

    property Process scan: Process {
        command: ["bash", "/home/ghita/.config/quickshell/scripts/localsend-scan.sh"]
        stdout: StdioCollector {
            id: scanOut
            onStreamFinished: {
                try {
                    root.sendTargets = JSON.parse(scanOut.text.trim())
                } catch (e) {
                    root.sendTargets = []
                }
                root.picking = true
            }
        }
    }

    property Process sender: Process {
        property string targetIp: ""
        property string filePath: ""
        command: ["/home/ghita/go/bin/localsend-cli", "send",
                  "--ip", sender.targetIp, "-f", sender.filePath]
    }
    function sendTo(ip) {
        sender.targetIp = ip
        sender.filePath = root.pendingFile
        sender.running = true
        root.picking = false
        root.pendingFile = ""
    }

    function pickAndSend() {
        root.picker.running = true
    }
    function cancelPick() {
        root.picking = false
        root.pendingFile = ""
    }

    // ===== LocalSend: RECEIVE daemon (toggle) =====
    property Process receiver: Process {
        command: ["/home/ghita/go/bin/localsend-cli", "recv",
                  "-n", "vivo-arch", "-d", "/home/ghita/LocalSend"]
    }
    readonly property bool receiving: receiver.running
    function toggleReceive() {
        receiver.running = !receiver.running
    }
}