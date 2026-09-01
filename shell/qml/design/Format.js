.pragma library

/*
 * Định dạng ngày giờ cho Windra Shell.
 *
 * Nếu hệ thống đang dùng locale Việt (vi_VN) thì lấy tên thứ/tháng từ Qt locale.
 * Ngoài ra, giao diện Windra vẫn là tiếng Việt nên dùng bảng tên bên dưới thay
 * vì rơi về tiếng Anh giữa chừng. Mọi giá trị ngày giờ đều lấy từ đồng hồ hệ
 * thống, không hardcode ở đâu cả.
 */

var weekdaysLong = [
    "Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"
]

//! Nhãn cột lịch, tuần bắt đầu từ Thứ Hai.
var weekdayHeaders = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

function isVietnamese(localeName) {
    return typeof localeName === "string" && localeName.indexOf("vi") === 0
}

function weekdayName(date) {
    return weekdaysLong[date.getDay()]
}

function monthName(month) {
    return "Tháng " + (month + 1)
}

//! "Thứ Ba, 1 tháng 9"
function shortHeader(date) {
    return weekdayName(date) + ", " + date.getDate() + " tháng " + (date.getMonth() + 1)
}

//! "Thứ Ba, 1 tháng 9 năm 2026"
function longDate(date) {
    return weekdayName(date) + ", " + date.getDate()
        + " tháng " + (date.getMonth() + 1)
        + " năm " + date.getFullYear()
}

//! "Tháng 9 2026"
function monthTitle(year, month) {
    return monthName(month) + " " + year
}

function isSameDay(a, b) {
    return a.getFullYear() === b.getFullYear()
        && a.getMonth() === b.getMonth()
        && a.getDate() === b.getDate()
}

/*!
 * Ma trận 6x7 cho lưới lịch, tuần bắt đầu Thứ Hai.
 * Trả về mảng phần tử { day, inMonth, date }.
 */
function monthGrid(year, month) {
    var first = new Date(year, month, 1)
    // JS: 0 = Chủ Nhật. Đổi sang 0 = Thứ Hai.
    var offset = (first.getDay() + 6) % 7

    var cells = []
    for (var i = 0; i < 42; ++i) {
        var date = new Date(year, month, 1 + i - offset)
        cells.push({
            day: date.getDate(),
            inMonth: date.getMonth() === month,
            date: date
        })
    }
    return cells
}
