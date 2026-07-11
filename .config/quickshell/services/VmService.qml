pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ name: string, uuid: string, running: bool }]
    property var vms: []
    property int runningCount: 0

    // Details for the currently expanded VM
    property string infoUuid: ""
    property var info: ({})

    property var _all: []

    function refresh() {
        listProc.running = true
    }

    function start(uuid) {
        Quickshell.execDetached(["VBoxManage", "startvm", uuid, "--type", "gui"])
        settle.restart()
    }

    function startHeadless(uuid) {
        Quickshell.execDetached(["VBoxManage", "startvm", uuid, "--type", "headless"])
        settle.restart()
    }

    function shutdown(uuid) {
        Quickshell.execDetached(["VBoxManage", "controlvm", uuid, "acpipowerbutton"])
        settle.restart()
    }

    function forceOff(uuid) {
        Quickshell.execDetached(["VBoxManage", "controlvm", uuid, "poweroff"])
        settle.restart()
    }

    function fetchInfo(uuid) {
        infoUuid = uuid
        info = ({})
        infoProc.command = ["VBoxManage", "showvminfo", uuid, "--machinereadable"]
        infoProc.running = true
    }

    function _parse(text) {
        const out = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(/^"(.*)" \{([0-9a-fA-F-]+)\}\s*$/)
            if (m)
                out.push({ name: m[1], uuid: m[2] })
        }
        return out
    }

    Process {
        id: listProc
        command: ["VBoxManage", "list", "vms"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._all = root._parse(text)
                runningProc.running = true
            }
        }
    }

    Process {
        id: runningProc
        command: ["VBoxManage", "list", "runningvms"]
        stdout: StdioCollector {
            onStreamFinished: {
                const live = root._parse(text).map(v => v.uuid)
                root.vms = root._all.map(v => ({
                    name: v.name,
                    uuid: v.uuid,
                    running: live.indexOf(v.uuid) !== -1
                }))
                root.runningCount = live.length
            }
        }
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = ({})
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/^([A-Za-z0-9_]+)="?([^"]*)"?\s*$/)
                    if (m)
                        out[m[1]] = m[2]
                }
                root.info = out
            }
        }
    }

    // VirtualBox needs ~a second to register power transitions
    Timer {
        id: settle
        interval: 1500
        onTriggered: {
            root.refresh()
            if (root.infoUuid !== "")
                root.fetchInfo(root.infoUuid)
        }
    }

    // Background poll so the bar dots stay truthful even when the
    // popup is closed (catches VMs started/stopped outside the shell)
    Timer {
        running: true
        interval: 15000
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}