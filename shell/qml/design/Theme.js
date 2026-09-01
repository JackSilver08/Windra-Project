.pragma library

var ink = "#0b0d0e"
var textMuted = "#5c6468"
var surface = "#f5f7f3"
var surfaceStrong = "#ffffff"
var glass = "#dce4e4"
var accent = "#4da3ff"
var accentWarm = "#f6b83b"
var success = "#58a66b"
var danger = "#df5d5d"

// Windra desktop chrome: calm, compact and readable.
// No expensive blur/shader is required. Alpha surfaces and a very subtle
// border provide enough separation from the wallpaper while staying light.
var chromeGlass = "#c51b232c"
var chromeGlassStrong = "#d21b232c"
var chromeBorder = "#2effffff"
var chromeGlow = "#4da3ff"
var chromeGlowSoft = "#334da3ff"
var chromeText = "#f4f7fb"
var chromeMuted = "#b9c4d0"
var searchGlass = "#e9f4f6f7"
var searchBorder = "#42ffffff"
var brandBlue = "#168cf0"
var brandBlueDeep = "#1264d8"

// Secondary surfaces used by system popups and application chrome.
var hover = "#eef2ef"
var hoverStrong = "#e4eae6"
var divider = "#dde3df"
var popupSurface = "#f5f6f8f7"
var popupBorder = "#8fffffff"
var popupShadow = "#19000000"

var radiusSmall = 10
var radiusMedium = 14
var radiusLarge = 20

var motionFast = 100
var motionNormal = 165
var motionSlow = 220
var stagger = 32
var panelOpacity = 0.92

// Motion stays restrained: a small fade/translate is enough for spatial cue.
var popupDuration = 150
var popupSlide = 8
var popupFadeReduced = 80
var hoverDuration = 100
var hoverScale = 1.018
var pressScale = 0.975

function popupMs(reduceMotion) {
    return reduceMotion ? popupFadeReduced : popupDuration
}

function slideFor(reduceMotion) {
    return reduceMotion ? 0 : popupSlide
}

function batteryColor(level) {
    if (level === "critical") return danger
    if (level === "low") return accentWarm
    return ink
}

function batteryChromeColor(level) {
    if (level === "critical") return danger
    if (level === "low") return accentWarm
    return chromeText
}
