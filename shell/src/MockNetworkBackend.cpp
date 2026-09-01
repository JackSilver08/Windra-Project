#include "MockNetworkBackend.h"

#include <QRandomGenerator>
#include <QTimer>

namespace {
constexpr auto kMockEnv = "WINDRA_WIFI_MOCK";
}

bool MockNetworkBackend::requested()
{
    return qEnvironmentVariable(kMockEnv) == QLatin1String("1");
}

MockNetworkBackend::MockNetworkBackend(QObject *parent)
    : NetworkBackend(parent)
{
}

bool MockNetworkBackend::probe()
{
    if (!requested())
        return false;

    // Mật khẩu đúng của mọi mạng có khoá là "windra123" — xem docs/system-panels.md.
    // Cố ý phủ đủ các kiểu bảo mật để kiểm được cả nhánh WPA3 và 802.1X.
    m_aps = {
        {QStringLiteral("MyHomeWifi"),      QStringLiteral("windra123"), QStringLiteral("psk"),        88, true},
        {QStringLiteral("FPT Telecom"),     QStringLiteral("windra123"), QStringLiteral("psk"),        74, false},
        {QStringLiteral("MyPhone"),         QStringLiteral("windra123"), QStringLiteral("sae"),        61, false},
        {QStringLiteral("Coffee House"),    QString(),                   QStringLiteral("open"),       47, false},
        {QStringLiteral("Cafe Secure"),     QString(),                   QStringLiteral("owe"),        41, false},
        {QStringLiteral("Another Network"), QStringLiteral("windra123"), QStringLiteral("psk"),        33, false},
        {QStringLiteral("Company-WPA2"),    QString(),                   QStringLiteral("enterprise"), 26, false},
        {QStringLiteral("Neighbour 5G"),    QStringLiteral("windra123"), QStringLiteral("sae"),        18, false},
    };
    m_activeSsid = QStringLiteral("MyHomeWifi");

    // Cường độ nhấp nhô nhẹ để UI trông sống, giống sóng thật.
    m_drift = new QTimer(this);
    m_drift->setInterval(5000);
    connect(m_drift, &QTimer::timeout, this, &MockNetworkBackend::driftStrength);
    m_drift->start();

    QTimer::singleShot(0, this, &MockNetworkBackend::publish);
    return true;
}

void MockNetworkBackend::publish()
{
    if (!m_wirelessEnabled) {
        emit networksChanged({});
        return;
    }

    QVector<WifiNetwork> networks;
    networks.reserve(m_aps.size());
    for (const MockAp &ap : std::as_const(m_aps)) {
        WifiNetwork network;
        network.ssid = ap.ssid;
        network.path = QStringLiteral("/mock/") + ap.ssid;
        network.strength = ap.strength;
        network.security = ap.security;
        network.secured = ap.security == QLatin1String("psk")
            || ap.security == QLatin1String("sae");
        network.known = ap.known;
        network.active = ap.ssid == m_activeSsid;
        networks.append(network);
    }

    std::sort(networks.begin(), networks.end(), [](const WifiNetwork &a, const WifiNetwork &b) {
        if (a.active != b.active) return a.active;
        if (a.strength != b.strength) return a.strength > b.strength;
        return a.ssid.localeAwareCompare(b.ssid) < 0;
    });

    emit networksChanged(networks);
}

void MockNetworkBackend::driftStrength()
{
    if (!m_wirelessEnabled)
        return;
    for (MockAp &ap : m_aps) {
        const int delta = QRandomGenerator::global()->bounded(-3, 4);
        ap.strength = qBound(5, ap.strength + delta, 99);
    }
    publish();
}

void MockNetworkBackend::setWirelessEnabled(bool enabled)
{
    if (m_wirelessEnabled == enabled)
        return;
    m_wirelessEnabled = enabled;
    if (!enabled)
        m_activeSsid.clear();
    emit wirelessEnabledChanged();
    publish();
}

void MockNetworkBackend::requestScan()
{
    if (!m_wirelessEnabled)
        return;

    emit scanningChanged(true);
    // Quét thật mất khoảng 1-3 giây; giữ đúng cảm giác đó.
    QTimer::singleShot(1600, this, [this] {
        driftStrength();
        emit scanningChanged(false);
    });
}

void MockNetworkBackend::refresh()
{
    publish();
}

void MockNetworkBackend::connectToNetwork(const QString &ssid, const QString &password)
{
    const int index = [this, &ssid] {
        for (int i = 0; i < m_aps.size(); ++i) {
            if (m_aps.at(i).ssid == ssid)
                return i;
        }
        return -1;
    }();

    if (index < 0) {
        QTimer::singleShot(600, this, [this] {
            emit connectFinished(false, QStringLiteral("Không tìm thấy mạng này nữa."));
        });
        return;
    }

    const MockAp ap = m_aps.at(index);

    if (ap.security == QLatin1String("enterprise")) {
        QTimer::singleShot(500, this, [this] {
            emit connectFinished(
                false, QStringLiteral("Windra chưa hỗ trợ mạng doanh nghiệp (802.1X)."));
        });
        return;
    }

    // Mạng đã lưu thì không cần mật khẩu, giống hành vi của NetworkManager.
    const bool needsPassword = !ap.password.isEmpty() && !ap.known;
    const bool ok = !needsPassword || password == ap.password;

    QTimer::singleShot(ok ? 1200 : 1900, this, [this, index, ok] {
        if (ok) {
            m_aps[index].known = true;
            m_activeSsid = m_aps.at(index).ssid;
            publish();
            emit connectFinished(true, QString());
        } else {
            publish();
            emit connectFinished(
                false,
                QStringLiteral("Không thể kết nối. Hãy kiểm tra mật khẩu và thử lại."));
        }
    });
}

void MockNetworkBackend::disconnectCurrent()
{
    if (m_activeSsid.isEmpty())
        return;
    m_activeSsid.clear();
    publish();
}
