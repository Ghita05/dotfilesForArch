import QtQuick
import Quickshell
import Quickshell.Io

BaseOSD {
    id: vol
    icon: dimmed ? "" : ""

    Process {
        id: volumeProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                const muted = line.includes("MUTED")
                const match = line.match(/Volume: ([\d.]+)/)
                if (match) {
                    const newVolume = Math.min(100, Math.round(parseFloat(match[1]) * 100))
                    if (newVolume !== vol.value || muted !== vol.dimmed) {
                        vol.value = newVolume
                        vol.dimmed = muted
                        vol.show()
                    }
                }
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: volumeProcess.running = true
    }
}