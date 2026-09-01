#pragma once

#include "NetworkBackend.h"

#include <QVector>

class QTimer;

/*!
 * Backend Wi-Fi giả lập — **chỉ dùng cho phát triển**.
 *
 * Máy dev chạy trong WSL không có card không dây (`/sys/class/net` chỉ có
 * eth0/lo), nên toàn bộ UX Wi-Fi — quét, lọc SSID, sheet mật khẩu, lỗi sai mật
 * khẩu, kết nối thành công — sẽ không bao giờ chạy được nếu không có lớp này.
 *
 * An toàn:
 *   - CHỈ được chọn khi biến môi trường `WINDRA_WIFI_MOCK=1`;
 *   - `id()` trả về "mock" và popup hiện chip "DEV MOCK" để không ai nhầm dữ
 *     liệu này là thật;
 *   - không bao giờ được chọn ở bản chạy bình thường.
 *
 * Đây là lý do `NetworkBackend` là một interface: lớp này lắp vừa mà
 * NetworkService, WifiNetworkModel và QML không đổi một dòng.
 */
class MockNetworkBackend final : public NetworkBackend
{
    Q_OBJECT
public:
    explicit MockNetworkBackend(QObject *parent = nullptr);

    //! true khi WINDRA_WIFI_MOCK=1.
    static bool requested();

    QString id() const override { return QStringLiteral("mock"); }
    bool probe() override;

    bool wirelessEnabled() const override { return m_wirelessEnabled; }
    void setWirelessEnabled(bool enabled) override;

    void requestScan() override;
    void refresh() override;

    void connectToNetwork(const QString &ssid, const QString &password) override;
    void disconnectCurrent() override;

private:
    struct MockAp {
        QString ssid;
        QString password;   //!< rỗng = không cần mật khẩu
        QString security;   //!< open | owe | psk | sae | enterprise
        int strength = 0;
        bool known = false;
    };

    void publish();
    void driftStrength();

    QVector<MockAp> m_aps;
    QString m_activeSsid;
    QTimer *m_drift = nullptr;
    bool m_wirelessEnabled = true;
};
