import QtQuick
import "../design/Theme.js" as Theme

//! Tiêu đề nhóm nhỏ trong popup ("Mạng khả dụng", "Chạy nền"...).
Text {
    color: Theme.textMuted
    font.pixelSize: 12
    font.bold: true
    font.letterSpacing: 0.3
    elide: Text.ElideRight
}
