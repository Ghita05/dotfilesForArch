pragma Singleton
import QtQuick

QtObject {
    // Background / surfaces — deeper, more charcoal
    readonly property color base:        "#0a0b0f"
    readonly property color surface:     "#12141a"
    // ~60% opacity for liquid feel
    readonly property color surfaceGlass: "#9912141a"

    // Text — softer, less white
    readonly property color text:        "#c8ccd6"
    readonly property color textDim:     "#5a5f6b"

    // Accent — dimmer, greyer blue
    readonly property color accent:      "#6a85a8"
    readonly property color accentBright: "#85a0c0"

    // Border — barely-there cool-grey
    readonly property color border:      "#2080a0c0"

    // Font
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}