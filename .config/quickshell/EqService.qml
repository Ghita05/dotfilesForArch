pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false
    property bool enabled: true
    readonly property real range: 12
    readonly property var freqs: ["22", "28", "35", "43", "53", "66", "82", "102", "126", "156"]
    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property string activePreset: "Flat"

    readonly property var presetNames: ["Flat", "Bass Boost", "Treble Boost", "Vocal", "V-Shape"]
    readonly property var presets: ({
        "Flat":         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass Boost":   [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        "Treble Boost": [0, 0, 0, 0, 0, 1, 3, 5, 6, 6],
        "Vocal":        [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1],
        "V-Shape":      [5, 4, 2, 0, -2, -2, 0, 2, 4, 5]
    })

    // visual-only while dragging (audio commits on release)
    function setBand(i, v) {
        var g = gains.slice()
        g[i] = Math.max(-range, Math.min(range, v))
        gains = g
        root.activePreset = ""
    }

    function commit() {
        var args = ["bash", "/home/ghita/.config/quickshell/scripts/eq-apply.sh"]
        for (var i = 0; i < gains.length; i++)
            args.push(Number(gains[i]).toFixed(1))
        apply.command = args
        apply.running = true
    }

    function applyPreset(name) {
        if (presets[name] === undefined)
            return
        gains = presets[name].slice()
        root.activePreset = name
        commit()
    }
    function reset() { applyPreset("Flat") }

    function setEnabled(on) {
        root.enabled = on
        bypass.command = ["bash", "/home/ghita/.config/quickshell/scripts/eq-bypass.sh", on ? "false" : "true"]
        bypass.running = true
    }

    property Process apply: Process { }
    property Process bypass: Process { }

    // reload real state from the preset on startup + every open (fixes reset-to-flat)
    property Process loader: Process {
        command: ["bash", "/home/ghita/.config/quickshell/scripts/eq-read.sh"]
        stdout: StdioCollector {
            id: loadOut
            onStreamFinished: {
                try {
                    var st = JSON.parse(loadOut.text.trim())
                    if (st.gains && st.gains.length === 10)
                        root.gains = st.gains
                    root.enabled = (st.enabled !== false)
                } catch (e) { }
            }
        }
    }
    Component.onCompleted: loader.running = true

    property IpcHandler ipc: IpcHandler {
        target: "eq"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }
}