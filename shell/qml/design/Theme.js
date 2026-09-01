.pragma library

var ink = "#0b0d0e"
var textMuted = "#5c6468"
var surface = "#f5f7f3"
var surfaceStrong = "#ffffff"
var glass = "#dce4e4"
var accent = "#22a7df"
var accentWarm = "#f6b83b"
var success = "#58a66b"
var danger = "#df5d5d"

// Homepage chrome: lấy cảm hứng từ mockup Windra mới và logo xanh gió/toàn cầu.
// Không dùng blur nặng để giữ mục tiêu lightweight; cảm giác kính được tạo bằng
// alpha, viền sáng và một đường glow mảnh.
var chromeGlass = "#a61a2627"
var chromeGlassStrong = "#bd263334"
var chromeBorder = "#70bfefff"
var chromeGlow = "#29b8ff"
var chromeGlowSoft = "#5c29b8ff"
var chromeText = "#f7fbff"
var chromeMuted = "#c8d6dd"
var searchGlass = "#b8d6dcde"
var searchBorder = "#8de7f7ff"
var brandBlue = "#0f91f5"
var brandBlueDeep = "#1264ff"

// Bề mặt phụ dùng trong popup (hover, groove slider, chip).
var hover = "#eef2ef"
var hoverStrong = "#e4eae6"
var divider = "#dde3df"
// Định dạng #AARRGGBB — .pragma library không phụ thuộc QML context.
var popupSurface = "#f7f6f9f7"
var popupBorder = "#b2ffffff"
var popupShadow = "#14000000"

var radiusSmall = 10
var radiusMedium = 16
var radiusLarge = 24

var motionFast = 110
var motionNormal = 190
var motionSlow = 280
var stagger = 42
var panelOpacity = 0.88

// --- Windra Motion Design cho system popup ---------------------------------
// opacity 0 -> 1, translate 6-12px -> 0, 140-180ms. Không blur/particle/bounce.
var popupDuration = 160
var popupSlide = 10
var popupFadeReduced = 90   // khi Reduce Motion: chỉ fade rất nhanh, không slide
var hoverDuration = 120
var hoverScale = 1.04
var pressScale = 0.965

//! Thời lượng thực tế cho popup, tôn trọng Reduce Motion.
function popupMs(reduceMotion) {
    return reduceMotion ? popupFadeReduced : popupDuration
}

//! Khoảng trượt thực tế; Reduce Motion bỏ hẳn slide.
function slideFor(reduceMotion) {
    return reduceMotion ? 0 : popupSlide
}

//! Màu của icon pin theo mức dung lượng.
function batteryColor(level) {
    if (level === "critical") return danger
    if (level === "low") return accentWarm
    return chromeText
}
