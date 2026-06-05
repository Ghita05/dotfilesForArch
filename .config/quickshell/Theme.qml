pragma Singleton
import QtQuick

QtObject {
    readonly property color base:        "#0a0b0f"
    readonly property color surface:      "#12141a"

    // glass surfaces — a touch more transparent (Hyprland blur frosts them)
    readonly property color surfaceGlass:     "#3812141a"  // ~22%
    readonly property color surfaceGlassHi:   "#4a12141a"  // ~29% hover
    readonly property color surfaceVeryGlass: "#2212141a"  // ~13% inputs

    readonly property color text:        "#d4d9e3"
    readonly property color textDim:     "#9298a6"
    readonly property color textGlassy:  "#c4cad6"

    // accent stays blue — but only for small glyphs/arcs, where it reads as a pop
    readonly property color accent:       "#5a7fb8"
    readonly property color accentBright: "#6a85c0"
    readonly property color accentSoft:   "#8a93a3"  // softened

    // FILLS — desaturated frosted slate (this is what was "straight blue")
    readonly property color selection:       "#2e8a93a3"  // ~18% glossy slate
    readonly property color selectionStrong: "#6a8a93a3"  // border / focus

    readonly property color border:      "#1a8ca0c8"

    readonly property color good:  "#8aac8e"
    readonly property color warn:  "#c4b88a"
    readonly property color crit:  "#c47d8a"

    // glossier panel (more see-through than the old #cc)
    readonly property color panel: "#b30c0e13"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}