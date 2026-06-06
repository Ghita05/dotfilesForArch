import QtQuick
import Quickshell
import "modules/osd"
import "modules/controlcenter"
import "modules/bar"
import "modules/launcher"
import "modules/notifications"
import "modules/powermenu"
import "modules/wallpaper"

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
        function onToggleCC() { controlCenter.toggle() }
    }
    
    // Expose toggle function to IPC
    function toggleControlCenter() {
        controlCenter.toggle()
    }

    Bar{}
    BarPopups {}
    Launcher{}
    Notifications{}
    PowerMenu {}
    WallpaperSwitcher {}
}