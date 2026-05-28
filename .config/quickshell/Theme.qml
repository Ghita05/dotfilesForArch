pragma Singleton
import QtQuick

QtObject {
    // Background / surfaces — deep charcoal base
    readonly property color base:        "#0a0b0f"
    readonly property color surface:     "#12141a"
    
    // Apple liquid glass — ultra transparent with better contrast
    readonly property color surfaceGlass:    "#2412141a"  // ~14% opacity — slightly more visible
    readonly property color surfaceGlassHi:  "#3012141a"  // ~19% opacity — subtle hover
    readonly property color surfaceVeryGlass: "#1512141a"  // ~8% opacity — ultra minimal
    
    // Text — medium-light grey for both light & dark backgrounds
    readonly property color text:        "#a8b0be"  // readable on both backgrounds
    readonly property color textDim:     "#7a8290"  // muted grey
    readonly property color textGlassy:  "#b0b8c6"  // premium glass text

    // Accent — keep the blue
    readonly property color accent:      "#4a6fa8"  // darker blue
    readonly property color accentBright: "#6a85c0"  // vibrant blue

    // Border — virtually invisible (liquid flow)
    readonly property color border:      "#0880a0c0"  // ~3% opacity — almost ghost

    // Font
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}