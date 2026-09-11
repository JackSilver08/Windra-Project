.pragma library

// Windra Geometric Design 0.3
// Shape is the brand signature. Effects stay restrained.
var cutSmall = 8
var cutMedium = 14
var cutLarge = 20
var cutXLarge = 28

var ink = "#0b0d0e"
var paper = "#e9eef3"
var paperStrong = "#f7f9fb"
var edge = "#b7c2cc"
var shadow = "#55000000"
var sapphire = "#1f80ff"
var sapphireDark = "#1158ad"
var text = "#10202e"
var textMuted = "#53616d"
var chromeDark = "#0b1320"
var chromeMid = "#162437"
var chromeEdge = "#71869a"

var motionFast = 90
var motionNormal = 150
var hoverScale = 1.03
var pressScale = 0.975

function cutFor(size) {
    if (size === "small") return cutSmall
    if (size === "large") return cutLarge
    if (size === "xlarge") return cutXLarge
    return cutMedium
}
