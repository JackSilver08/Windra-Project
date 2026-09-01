#pragma once

#include <QObject>
#include <QString>

// Q_PROPERTY expose WifiNetworkModel* nên moc cần định nghĩa đầy đủ, không
// chỉ forward declaration.
#include "WifiNetworkModel.h"

class NetworkBackend;

/*!
 * Mặt tiền mạng cho QML.
 *
 * Chọn backend một lần lúc khởi động: NetworkManager D-Bus trước, nmcli sau,
 * không có thì `available` = false và popup báo Wi-Fi không khả dụng thay vì
 * hiển thị danh sách giả.
 */
class NetworkService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(QString backendId READ backendId NOTIFY changed)
    Q_PROPERTY(bool wirelessEnabled READ wirelessEnabled WRITE setWirelessEnabled NOTIFY changed)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(QString activeSsid READ activeSsid NOTIFY changed)
    Q_PROPERTY(int activeStrength READ activeStrength NOTIFY changed)
    Q_PROPERTY(int activeBars READ activeBars NOTIFY changed)
    Q_PROPERTY(bool scanning READ scanning NOTIFY changed)
    Q_PROPERTY(bool connecting READ connecting NOTIFY changed)
    Q_PROPERTY(QString lastError READ lastError NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(QString tooltipText READ tooltipText NOTIFY changed)
    Q_PROPERTY(QString level READ level NOTIFY changed)
    Q_PROPERTY(WifiNetworkModel *networks READ networks CONSTANT)

public:
    explicit NetworkService(QObject *parent = nullptr);

    bool available() const { return m_backend != nullptr; }
    QString backendId() const;
    bool wirelessEnabled() const;
    bool connected() const { return !m_activeSsid.isEmpty(); }
    QString activeSsid() const { return m_activeSsid; }
    int activeStrength() const { return m_activeStrength; }
    int activeBars() const;
    bool scanning() const { return m_scanning; }
    bool connecting() const { return m_connecting; }
    QString lastError() const { return m_lastError; }
    QString statusText() const;
    QString tooltipText() const;

    //! off | none | weak | fair | good — dùng để vẽ icon Wi-Fi.
    QString level() const;

    WifiNetworkModel *networks() const { return m_model; }

    Q_INVOKABLE void setWirelessEnabled(bool enabled);
    Q_INVOKABLE void scan();
    Q_INVOKABLE void connectTo(const QString &ssid, const QString &password);
    Q_INVOKABLE void disconnectCurrent();
    Q_INVOKABLE void clearError();

    //! Popup mở => scan ngay; popup đóng => ngừng quét chủ động.
    Q_INVOKABLE void setActive(bool active);

signals:
    void changed();
    void connectSucceeded(const QString &ssid);

private:
    NetworkBackend *m_backend = nullptr;
    WifiNetworkModel *m_model = nullptr;
    QString m_activeSsid;
    QString m_lastError;
    QString m_pendingSsid;
    int m_activeStrength = 0;
    bool m_scanning = false;
    bool m_connecting = false;
};
