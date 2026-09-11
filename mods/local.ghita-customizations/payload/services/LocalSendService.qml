pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ported from ~/.config/quickshell/Devices.qml — LocalSend-only logic (that
// file also had KDE Connect device tracking; unrelated to this request, not
// ported). Talks to the same localsend-cli binary and scan script the old
// shell used, both left where they are on disk rather than duplicated.
Singleton {
    id: root

    property string pendingFile: ""
    property var sendTargets: []
    readonly property bool receiving: receiver.running

    signal targetsReady

    function pickAndSend() {
        picker.running = true;
    }

    function sendTo(ip) {
        sender.targetIp = ip;
        sender.filePath = root.pendingFile;
        sender.running = true;
        root.pendingFile = "";
    }

    function toggleReceive() {
        receiver.running = !receiver.running;
    }

    property Process picker: Process {
        command: ["zenity", "--file-selection", "--title=Send via LocalSend"]
        stdout: StdioCollector {
            id: pickerOut
            onStreamFinished: {
                const f = pickerOut.text.trim();
                if (f === "")
                    return;
                root.pendingFile = f;
                scan.running = true;
            }
        }
    }

    property Process scan: Process {
        command: ["bash", "/home/ghita/.config/quickshell/scripts/localsend-scan.sh"]
        stdout: StdioCollector {
            id: scanOut
            onStreamFinished: {
                try {
                    root.sendTargets = JSON.parse(scanOut.text.trim());
                } catch (e) {
                    root.sendTargets = [];
                }
                root.targetsReady();
            }
        }
    }

    property Process sender: Process {
        property string targetIp: ""
        property string filePath: ""
        command: ["/home/ghita/go/bin/localsend-cli", "send", "--ip", sender.targetIp, "-f", sender.filePath]
    }

    property Process receiver: Process {
        command: ["/home/ghita/go/bin/localsend-cli", "recv", "-n", "vivo-arch", "-d", "/home/ghita/LocalSend"]
    }
}
