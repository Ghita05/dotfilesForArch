pragma Singleton
import QtQuick

QtObject {
    readonly property color base:        "#0a0b0f"
    readonly property color surface:      "#12141a"

    // glass surfaces
    readonly property color surfaceGlass:     "#3812141a"  // ~22%
    readonly property color surfaceGlassHi:   "#4a12141a"  // ~29% hover
    readonly property color surfaceVeryGlass: "#2212141a"  // ~13% inputs

    readonly property color text:        "#d4d9e3"
    readonly property color textDim:     "#9298a6"
    readonly property color textGlassy:  "#c4cad6"

    // accent 
    readonly property color accent:       "#7c93a0"
    readonly property color accentBright: "#8ba3b0"
    readonly property color accentSoft:   "#8a93a3"

    // FILLS 
    readonly property color selection:       "#2e7c93a0"  // ~18%
    readonly property color selectionStrong: "#6a7c93a0"  // border / focus / arcs

    readonly property color border:      "#1a8ca0c8"

    readonly property color good:  "#8aac8e"
    readonly property color warn:  "#c4b88a"
    readonly property color crit:  "#c47d8a"

    // glossier panel 
    readonly property color panel: "#b30c0e13"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}