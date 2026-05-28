import QtQuick
import Quickshell
import "modules/osd"
import "modules/controlcenter"

ShellRoot {
    id: root
    
    // Toggle signal for control center (exposed to external signals)
    signal toggleCC()
    
    VolumeOSD {}
    BrightnessOSD {}
    ControlCenter { 
        id: controlCenter
    }
    
    // Connect external toggle signal to CC
    Connections {
        target: root
        onToggleCC: controlCenter.toggle()
    }
    
    // Expose toggle function to IPC
    function toggleControlCenter() {
        controlCenter.toggle()
    }
}