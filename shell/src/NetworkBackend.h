#pragma once

#include <QObject>
#include <QString>
#include <QVector>

//! Một mạng Wi-Fi nhìn thấy được.
struct WifiNetwork {
    QString ssid;
    QString path;        //!< object path (D-Bus) hoặc BSSID (nmcli)

    /*!
     * Kiểu bảo mật thật, không chỉ "có khoá hay không":
     *   open       - không mã hoá
     *   owe        - Enhanced Open, có mã hoá nhưng không cần mật khẩu
     *   psk        - WPA/WPA2 (kể cả WPA2/WPA3 transition mode)
     *   sae        - WPA3 thuần
     *   enterprise - 802.1X, Windra chưa hỗ trợ
     *
     * Cần phân biệt vì `key-mgmt` gửi xuống NetworkManager khác nhau:
     * đoán đại "wpa-psk" sẽ làm mạng WPA3 luôn kết nối thất bại.
     */
    QString security = QStringLiteral("open");

    int strength = 0;    //!< 0..100
    bool secured = false; //!< true khi cần người dùng nhập mật khẩu (psk/sae)
    bool known = false;  //!< đã có connection profile lưu sẵn
    bool active = false;

    bool operator==(const WifiNetwork &other) const
    {
        // `path` là định danh AP/connection cụ thể. Sau một lần scan,
        // NetworkManager có thể trả object path mới dù SSID và cường độ giữ nguyên.
        // Nếu bỏ qua path, WifiNetworkModel sẽ tưởng dữ liệu chưa đổi và giữ lại
        // object path cũ, khiến thao tác kết nối/activate dùng reference đã stale.
        return ssid == other.ssid && path == other.path
            && strength == other.strength && security == other.security
            && secured == other.secured && known == other.known
            && active == other.active;
    }
};

/*!
 * Giao diện backend mạng.
 *
 * NetworkService chỉ phụ thuộc vào interface này. Backend chính thức là
 * NetworkManager qua D-Bus; nmcli chỉ là fallback prototype cho máy dev
 * thiếu quyền truy cập bus.
 */
class NetworkBackend : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;

    //! networkmanager-dbus | nmcli
    virtual QString id() const = 0;

    //! Thử kết nối tới backend. false => không dùng được trên máy này.
    virtual bool probe() = 0;

    virtual bool wirelessEnabled() const = 0;
    virtual void setWirelessEnabled(bool enabled) = 0;

    virtual void requestScan() = 0;
    virtual void refresh() = 0;

    //! password rỗng => mạng mở, hoặc dùng lại profile đã lưu.
    virtual void connectToNetwork(const QString &ssid, const QString &password) = 0;
    virtual void disconnectCurrent() = 0;

signals:
    void networksChanged(const QVector<WifiNetwork> &networks);
    void wirelessEnabledChanged();
    void scanningChanged(bool scanning);
    //! friendlyError đã được dịch sang ngôn ngữ người dùng, không phải raw D-Bus.
    void connectFinished(bool ok, const QString &friendlyError);
};
