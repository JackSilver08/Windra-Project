#pragma once

#include "NetworkBackend.h"

#include <QStringList>

class QTimer;

/*!
 * Fallback prototype: NetworkManager qua `nmcli`.
 *
 * Chỉ dùng khi không nói chuyện được với NetworkManager qua D-Bus (thường là
 * máy dev thiếu quyền bus). Mật khẩu đi qua argv của nmcli nên backend D-Bus
 * luôn được ưu tiên; xem docs/system-panels.md.
 */
class NmcliBackend final : public NetworkBackend
{
    Q_OBJECT
public:
    explicit NmcliBackend(QObject *parent = nullptr);

    QString id() const override { return QStringLiteral("nmcli"); }
    bool probe() override;

    bool wirelessEnabled() const override { return m_wirelessEnabled; }
    void setWirelessEnabled(bool enabled) override;

    void requestScan() override;
    void refresh() override;

    void connectToNetwork(const QString &ssid, const QString &password) override;
    void disconnectCurrent() override;

private:
    void readRadio();
    void readSaved();
    void readNetworks();
    static QStringList splitEscaped(const QString &line);

    QStringList m_savedSsids;
    QTimer *m_poll = nullptr;
    bool m_wirelessEnabled = false;
    bool m_scanning = false;
};
