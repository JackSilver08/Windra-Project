#include "NetworkService.h"

#include "MockNetworkBackend.h"
#include "NetworkManagerBackend.h"
#include "NmcliBackend.h"
#include "WifiNetworkModel.h"

NetworkService::NetworkService(QObject *parent)
    : QObject(parent), m_model(new WifiNetworkModel(this))
{
    // WINDRA_WIFI_MOCK=1 chỉ dùng khi phát triển UI trên máy không có card
    // không dây. Kiểm tra trước để có thể ép dùng mock ngay cả trên máy có
    // NetworkManager thật.
    if (MockNetworkBackend::requested()) {
        auto *mock = new MockNetworkBackend(this);
        if (mock->probe())
            m_backend = mock;
        else
            delete mock;
    }

    if (!m_backend) {
        auto *dbus = new NetworkManagerBackend(this);
        if (dbus->probe()) {
            m_backend = dbus;
        } else {
            delete dbus;
            auto *cli = new NmcliBackend(this);
            if (cli->probe())
                m_backend = cli;
            else
                delete cli;
        }
    }

    if (!m_backend)
        return;

    connect(m_backend, &NetworkBackend::networksChanged, this,
            [this](const QVector<WifiNetwork> &networks) {
        m_model->setNetworks(networks);
        const WifiNetwork active = m_model->activeNetwork();
        if (active.ssid != m_activeSsid || active.strength != m_activeStrength) {
            m_activeSsid = active.ssid;
            m_activeStrength = active.strength;
            emit changed();
        } else {
            emit changed(); // số lượng mạng có thể đã đổi
        }
    });

    connect(m_backend, &NetworkBackend::wirelessEnabledChanged, this, &NetworkService::changed);

    connect(m_backend, &NetworkBackend::scanningChanged, this, [this](bool scanning) {
        if (m_scanning == scanning)
            return;
        m_scanning = scanning;
        emit changed();
    });

    connect(m_backend, &NetworkBackend::connectFinished, this,
            [this](bool ok, const QString &error) {
        m_connecting = false;
        m_lastError = ok ? QString() : error;
        const QString ssid = m_pendingSsid;
        m_pendingSsid.clear();
        emit changed();
        if (ok && !ssid.isEmpty())
            emit connectSucceeded(ssid);
    });
}

QString NetworkService::backendId() const
{
    return m_backend ? m_backend->id() : QStringLiteral("none");
}

bool NetworkService::wirelessEnabled() const
{
    return m_backend && m_backend->wirelessEnabled();
}

int NetworkService::activeBars() const
{
    if (m_activeStrength >= 75) return 4;
    if (m_activeStrength >= 50) return 3;
    if (m_activeStrength >= 25) return 2;
    if (m_activeStrength > 0) return 1;
    return 0;
}

QString NetworkService::level() const
{
    if (!available() || !wirelessEnabled())
        return QStringLiteral("off");
    if (!connected())
        return QStringLiteral("none");
    if (m_activeStrength >= 67) return QStringLiteral("good");
    if (m_activeStrength >= 34) return QStringLiteral("fair");
    return QStringLiteral("weak");
}

QString NetworkService::statusText() const
{
    if (!available())
        return QStringLiteral("Wi-Fi không khả dụng");
    if (!wirelessEnabled())
        return QStringLiteral("Wi-Fi đang tắt");
    if (m_connecting)
        return QStringLiteral("Đang kết nối...");
    if (connected())
        return m_activeSsid;
    return QStringLiteral("Chưa kết nối");
}

QString NetworkService::tooltipText() const
{
    if (!available())
        return QStringLiteral("Không tìm thấy NetworkManager");
    if (!wirelessEnabled())
        return QStringLiteral("Wi-Fi đang tắt");
    if (connected())
        return QStringLiteral("%1 · %2%").arg(m_activeSsid).arg(m_activeStrength);
    return QStringLiteral("Chưa kết nối Wi-Fi");
}

void NetworkService::setWirelessEnabled(bool enabled)
{
    if (!m_backend)
        return;
    m_backend->setWirelessEnabled(enabled);
}

void NetworkService::scan()
{
    if (!m_backend)
        return;
    clearError();
    m_backend->requestScan();
}

void NetworkService::connectTo(const QString &ssid, const QString &password)
{
    if (!m_backend || ssid.isEmpty() || m_connecting)
        return;

    m_lastError.clear();
    m_pendingSsid = ssid;
    m_connecting = true;
    emit changed();

    m_backend->connectToNetwork(ssid, password);
}

void NetworkService::disconnectCurrent()
{
    if (m_backend)
        m_backend->disconnectCurrent();
}

void NetworkService::clearError()
{
    if (m_lastError.isEmpty())
        return;
    m_lastError.clear();
    emit changed();
}

void NetworkService::setActive(bool active)
{
    if (!m_backend)
        return;
    if (active) {
        m_backend->refresh();
        m_backend->requestScan();
    }
}
