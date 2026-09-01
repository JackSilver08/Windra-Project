#pragma once

#include "NetworkBackend.h"

#include <QDBusObjectPath>
#include <QHash>

class QTimer;

/*!
 * Backend chính thức: NetworkManager qua D-Bus system bus.
 *
 * Mạng mới được tạo qua AddAndActivateConnection; mạng đã lưu được nối lại
 * bằng ActivateConnection để NetworkManager dùng đúng profile và secret cũ.
 * Mật khẩu Wi-Fi mới được đưa thẳng vào NetworkManager.
 * NetworkManager tự lưu vào kho riêng của nó (/etc/NetworkManager/system-connections,
 * chỉ root đọc được). Windra không ghi mật khẩu ra bất kỳ file cấu hình nào của mình
 * và không giữ lại chuỗi mật khẩu sau khi gọi.
 */
class NetworkManagerBackend final : public NetworkBackend
{
    Q_OBJECT
public:
    explicit NetworkManagerBackend(QObject *parent = nullptr);

    QString id() const override { return QStringLiteral("networkmanager-dbus"); }
    bool probe() override;

    bool wirelessEnabled() const override { return m_wirelessEnabled; }
    void setWirelessEnabled(bool enabled) override;

    void requestScan() override;
    void refresh() override;

    void connectToNetwork(const QString &ssid, const QString &password) override;
    void disconnectCurrent() override;

private slots:
    void onDevicePropertiesChanged(const QString &interfaceName,
                                   const QVariantMap &changed,
                                   const QStringList &invalidated);
    void onManagerPropertiesChanged(const QString &interfaceName,
                                    const QVariantMap &changed,
                                    const QStringList &invalidated);
    void onActiveConnectionStateChanged(uint state, uint reason);

private:
    QVariant deviceProperty(const QString &path, const QString &iface, const QString &name) const;
    QVariant property(const QString &path, const QString &iface, const QString &name) const;
    bool findWirelessDevice();
    void reloadSavedConnections();
    void readAccessPoints();
    void watchActiveConnection(const QDBusObjectPath &path);
    void finishConnect(bool ok, const QString &error);
    static QString reasonToText(uint reason);

    QString m_devicePath;
    QString m_activeConnectionPath;
    QString m_pendingConnectionPath;   //!< profile vừa tạo, xoá nếu kết nối hỏng
    QString m_pendingSsid;
    //! SSID -> object path của connection profile đã lưu trong NetworkManager.
    QHash<QString, QString> m_savedConnections;
    QTimer *m_scanTimer = nullptr;
    QTimer *m_connectTimeout = nullptr;
    bool m_wirelessEnabled = false;
    bool m_scanning = false;
};
