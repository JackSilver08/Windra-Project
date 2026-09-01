pragma ComponentBehavior: Bound

import QtQuick
import "../controls"
import "../design/Theme.js" as Theme

/*!
 * Popup Wi-Fi đầy đủ: bật/tắt, mạng đang kết nối, danh sách quét thật,
 * tìm/lọc SSID, refresh và sheet nhập mật khẩu.
 *
 * Mật khẩu chỉ tồn tại trong ô nhập rồi đi thẳng xuống NetworkManager; popup
 * xoá nó ngay sau khi gửi và không ghi ra bất kỳ file nào.
 */
WindraPopup {
    id: root

    implicitWidth: 328
    // Không có NetworkManager thì popup co lại quanh thông báo, không để một
    // khoảng trống 400px trông như đang tải mãi.
    implicitHeight: networkService.available ? 420 : 164

    property string pendingSsid: ""
    property bool pendingSecured: false

    function closeSheet() {
        pendingSsid = ""
        passwordField.text = ""
        showPassword.checked = false
    }

    onOpenChanged: {
        if (!open) {
            closeSheet()
            networkService.networks.filter = ""
            searchField.text = ""
        }
    }

    Connections {
        target: networkService
        function onConnectSucceeded(ssid) { root.closeSheet() }
    }

    // ------------------------------------------------------------- danh sách
    Item {
        anchors.fill: parent
        anchors.margins: root.padding
        opacity: root.pendingSsid.length > 0 ? 0.12 : 1
        enabled: root.pendingSsid.length === 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.popupMs(root.reduceMotion) }
        }

        Row {
            id: header
            width: parent.width
            height: 26

            Text {
                text: "Wi-Fi"
                font.pixelSize: 17
                font.bold: true
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - toggle.width - mockBadge.width - 8
            }

            // Dữ liệu giả lập phải nhìn ra ngay, không bao giờ được nhầm là thật.
            Rectangle {
                id: mockBadge
                anchors.verticalCenter: parent.verticalCenter
                visible: networkService.backendId === "mock"
                width: visible ? mockLabel.implicitWidth + 12 : 0
                height: 18
                radius: 9
                color: Theme.accentWarm

                Text {
                    id: mockLabel
                    anchors.centerIn: parent
                    text: "DEV MOCK"
                    font.pixelSize: 9
                    font.bold: true
                    color: "#3a2a00"
                }
            }

            Item { width: 8; height: 1 }

            WindraToggle {
                id: toggle
                anchors.verticalCenter: parent.verticalCenter
                checked: networkService.wirelessEnabled
                enabled: networkService.available
                reduceMotion: root.reduceMotion
                onToggled: function(next) { networkService.setWirelessEnabled(next) }
            }
        }

        // Trạng thái không khả dụng — nói rõ thay vì hiện danh sách rỗng khó hiểu.
        Column {
            anchors.top: header.bottom
            anchors.topMargin: 18
            width: parent.width
            spacing: 6
            visible: !networkService.available

            Text {
                width: parent.width
                text: "Wi-Fi không khả dụng"
                font.pixelSize: 14
                font.bold: true
                color: Theme.ink
            }
            Text {
                width: parent.width
                text: "Không tìm thấy NetworkManager trên máy này, hoặc máy không có card Wi-Fi."
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }

        Column {
            id: body
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 10
            visible: networkService.available

            // --- đang kết nối
            Column {
                width: parent.width
                spacing: 4
                visible: networkService.connected

                WindraSectionTitle { text: "ĐÃ KẾT NỐI" }

                WindraListItem {
                    width: parent.width
                    title: networkService.activeSsid
                    subtitle: "Connected"
                    highlighted: true
                    reduceMotion: root.reduceMotion
                    leadingWidth: 20
                    trailingWidth: 22
                    leading: Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.success
                    }
                    trailing: SignalBars { bars: networkService.activeBars }
                    onClicked: networkService.disconnectCurrent()
                }
            }

            // --- tắt Wi-Fi
            Text {
                width: parent.width
                visible: !networkService.wirelessEnabled
                text: "Wi-Fi đang tắt. Bật công tắc ở trên để tìm mạng."
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: 12
            }

            // --- mạng khả dụng
            WindraSectionTitle {
                text: "MẠNG KHẢ DỤNG"
                visible: networkService.wirelessEnabled
            }

            WindraTextField {
                id: searchField
                width: parent.width
                visible: networkService.wirelessEnabled
                placeholderText: "Tìm mạng..."
                reduceMotion: root.reduceMotion
                onTextChanged: networkService.networks.filter = text
            }

            Item {
                width: parent.width
                height: body.height - y - footer.height - 10
                visible: networkService.wirelessEnabled
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    model: networkService.networks
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: WindraListItem {
                        id: networkRow

                        required property string ssid
                        required property int bars
                        required property bool secured
                        required property string security
                        required property bool known

                        function securityLabel() {
                            if (security === "enterprise") return "Mạng doanh nghiệp"
                            if (security === "owe") return "Mạng mở (có mã hoá)"
                            if (security === "sae") return "Cần mật khẩu · WPA3"
                            if (security === "psk") return "Cần mật khẩu"
                            return "Mạng mở"
                        }

                        width: list.width
                        title: networkRow.ssid
                        subtitle: networkRow.known && networkRow.secured
                            ? "Đã lưu"
                            : networkRow.securityLabel()
                        reduceMotion: root.reduceMotion
                        leadingWidth: 22
                        trailingWidth: 22
                        leading: SignalBars { bars: networkRow.bars }
                        trailing: LockIcon {
                            width: 11
                            height: 13
                            visible: networkRow.secured
                        }
                        onClicked: {
                            networkService.clearError()
                            // Mạng mở/OWE hoặc đã lưu profile -> kết nối luôn.
                            // 802.1X cũng gửi xuống để backend trả lời bằng
                            // thông báo rõ ràng thay vì mở sheet mật khẩu vô ích.
                            if (!networkRow.secured || networkRow.known) {
                                networkService.connectTo(networkRow.ssid, "")
                                return
                            }
                            root.pendingSecured = true
                            root.pendingSsid = networkRow.ssid
                            passwordField.forceFocus()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: list.count === 0
                        text: networkService.scanning
                            ? "Đang tìm mạng..."
                            : (networkService.networks.totalCount > 0
                               ? "Không có mạng nào khớp."
                               : "Chưa tìm thấy mạng nào.")
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }

            // --- footer
            Item {
                id: footer
                width: parent.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - refreshButton.width - 10
                    text: networkService.lastError.length > 0
                        ? networkService.lastError
                        : networkService.statusText
                    color: networkService.lastError.length > 0 ? Theme.danger : Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                WindraButton {
                    id: refreshButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkService.scanning ? "Đang quét..." : "Làm mới"
                    enabled: networkService.available && networkService.wirelessEnabled
                        && !networkService.scanning
                    reduceMotion: root.reduceMotion
                    onClicked: networkService.scan()
                }
            }
        }
    }

    // -------------------------------------------------------- sheet mật khẩu
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.popupSurface
        visible: opacity > 0.01
        opacity: root.pendingSsid.length > 0 ? 1 : 0
        enabled: root.pendingSsid.length > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.popupMs(root.reduceMotion)
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.padding
            spacing: 12

            WindraSectionTitle { text: "KẾT NỐI WI-FI" }

            Text {
                width: parent.width
                text: root.pendingSsid
                font.pixelSize: 16
                font.bold: true
                color: Theme.ink
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "Mật khẩu"
                color: Theme.textMuted
                font.pixelSize: 12
            }

            WindraTextField {
                id: passwordField
                width: parent.width
                echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                placeholderText: "Nhập mật khẩu"
                reduceMotion: root.reduceMotion
                onAccepted: connectButton.clicked()
            }

            Row {
                spacing: 8

                Rectangle {
                    id: showPassword
                    property bool checked: false
                    width: 16
                    height: 16
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: checked ? Theme.accent : Theme.surfaceStrong
                    border.width: 1
                    border.color: checked ? Theme.accent : Theme.divider

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.pixelSize: 11
                        color: "#ffffff"
                        visible: showPassword.checked
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showPassword.checked = !showPassword.checked
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Hiện mật khẩu"
                    color: Theme.ink
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showPassword.checked = !showPassword.checked
                    }
                }
            }

            Text {
                width: parent.width
                visible: networkService.lastError.length > 0
                text: networkService.lastError
                color: Theme.danger
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.padding
            spacing: 8

            WindraButton {
                text: "Hủy"
                reduceMotion: root.reduceMotion
                onClicked: {
                    networkService.clearError()
                    root.closeSheet()
                }
            }

            WindraButton {
                id: connectButton
                text: networkService.connecting ? "Đang kết nối..." : "Kết nối"
                primary: true
                enabled: !networkService.connecting && passwordField.text.length > 0
                reduceMotion: root.reduceMotion
                onClicked: {
                    var password = passwordField.text
                    networkService.connectTo(root.pendingSsid, password)
                    // Không giữ lại mật khẩu trong UI sau khi đã gửi xuống NM.
                    passwordField.text = ""
                }
            }
        }
    }
}
