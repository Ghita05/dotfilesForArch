import QtQuick
import Quickshell
import Quickshell.Io

BaseOSD {
    id: bri
    icon: ""

    Process {
        id: brightnessProcess
        command: ["sh", "-c", "echo $(($(brightnessctl get) * 100 / $(brightnessctl max)))"]
        stdout: StdioCollector {
            onStreamFinished: {
                const newValue = parseInt(text.trim())
                if (!isNaN(newValue) && newValue !== bri.value) {
                    bri.value = newValue
                    bri.show()
                }
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: brightnessProcess.running = true
    }
}