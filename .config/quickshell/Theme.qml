pragma Singleton
import QtQuick

QtObject {
    readonly property color base:        "#0a0b0f"
    readonly property color surface:     "#12141a"

    // Glass surfaces — more presence for contrast, still translucent over blur
    readonly property color surfaceGlass:     "#4012141a"  // ~25% — default card
    readonly property color surfaceGlassHi:   "#5512141a"  // ~33% — hover
    readonly property color surfaceVeryGlass: "#2812141a"  // ~16% — inputs

    // Text — brighter ramp for clear legibility
    readonly property color text:        "#d4d9e3"
    readonly property color textDim:     "#9298a6"
    readonly property color textGlassy:  "#c4cad6"

    readonly property color accent:       "#5a7fb8"
    readonly property color accentBright: "#6a85c0"
    readonly property color accentSoft:   "#7d9bc4"

    readonly property color selection:       "#387d9bc4"
    readonly property color selectionStrong: "#807d9bc4"

    readonly property color border:      "#1f8ca0c8"  // ~12% — edges now read

    readonly property color good:  "#8aac8e"
    readonly property color warn:  "#c4b88a"
    readonly property color crit:  "#c47d8a"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}