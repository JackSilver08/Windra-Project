#include "NetworkManagerBackend.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QTimer>

using NmConnectionSettings = QMap<QString, QVariantMap>;
Q_DECLARE_METATYPE(NmConnectionSettings)

namespace {

constexpr auto kNm = "org.freedesktop.NetworkManager";
constexpr auto kNmPath = "/org/freedesktop/NetworkManager";
constexpr auto kNmIface = "org.freedesktop.NetworkManager";
constexpr auto kSettingsPath = "/org/freedesktop/NetworkManager/Settings";
constexpr auto kSettingsIface = "org.freedesktop.NetworkManager.Settings";
constexpr auto kConnectionIface = "org.freedesktop.NetworkManager.Settings.Connection";
constexpr auto kDeviceIface = "org.freedesktop.NetworkManager.Device";
constexpr auto kWirelessIface = "org.freedesktop.NetworkManager.Device.Wireless";
constexpr auto kApIface = "org.freedesktop.NetworkManager.AccessPoint";
constexpr auto kActiveIface = "org.freedesktop.NetworkManager.Connection.Active";
constexpr auto kPropsIface = "org.freedesktop.DBus.Properties";

constexpr uint kDeviceTypeWifi = 2;
constexpr uint kActiveStateActivated = 2;
constexpr uint kActiveStateDeactivated = 4;

// NM80211ApFlags / NM80211ApSecurityFlags
constexpr uint kApFlagPrivacy = 0x1;
constexpr uint kSecKeyMgmtPsk = 0x100;
constexpr uint kSecKeyMgmt8021X = 0x200;
constexpr uint kSecKeyMgmtSae = 0x400;
constexpr uint kSecKeyMgmtOwe = 0x800;
constexpr uint kSecKeyMgmtOweTm = 0x1000;
constexpr uint kSecKeyMgmtEapSuiteB = 0x2000;

/*!
 * Suy ra kiểu bảo hành thật từ cờ của access point.
 *
 * Thứ tự quan trọng: router ở chế độ WPA2/WPA3 transition bật cả PSK lẫn SAE.
 * Ưu tiên PSK trong trường hợp đó vì nó tương thích rộng hơn; chỉ mạng WPA3
 * thuần (chỉ có SAE) mới dùng key-mgmt "sae".
 */
QString securityFor(uint flags, uint wpaFlags, uint rsnFlags)
{
    const uint combined = wpaFlags | rsnFlags;
    if (combined & (kSecKeyMgmt8021X | kSecKeyMgmtEapSuiteB))
        return QStringLiteral("enterprise");
    if (combined & (kSecKeyMgmtOwe | kSecKeyMgmtOweTm))
        return QStringLiteral("owe");
    if (combined & kSecKeyMgmtPsk)
        return QStringLiteral("psk");
    if (combined & kSecKeyMgmtSae)
        return QStringLiteral("sae");
    if (combined != 0 || (flags & kApFlagPrivacy))
        return QStringLiteral("psk");   // WEP hoặc cờ lạ — vẫn hỏi mật khẩu
    return QStringLiteral("open");
}

QDBusConnection bus()
{
    return QDBusConnection::systemBus();
}

} // namespace

NetworkManagerBackend::NetworkManagerBackend(QObject *parent)
    : NetworkBackend(parent)
{
    qDBusRegisterMetaType<NmConnectionSettings>();
}

// ------------------------------------------------------------- helpers ------

QVariant NetworkManagerBackend::property(const QString &path,
                                         const QString &iface,
                                         const QString &name) const
{
    if (path.isEmpty() || path == QLatin1String("/"))
        return {};

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), path, QLatin1String(kPropsIface), QStringLiteral("Get"));
    call << iface << name;

    const QDBusMessage reply = bus().call(call, QDBus::Block, 1500);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty())
        return {};

    const QVariant value = reply.arguments().constFirst();
    if (value.canConvert<QDBusVariant>())
        return value.value<QDBusVariant>().variant();
    return value;
}

QVariant NetworkManagerBackend::deviceProperty(const QString &path,
                                               const QString &iface,
                                               const QString &name) const
{
    return property(path, iface, name);
}

// --------------------------------------------------------------- probe ------

bool NetworkManagerBackend::probe()
{
    if (!bus().isConnected())
        return false;

    const QVariant version = property(QLatin1String(kNmPath), QLatin1String(kNmIface),
                                      QStringLiteral("Version"));
    if (!version.isValid())
        return false;

    if (!findWirelessDevice())
        return false;

    m_wirelessEnabled = property(QLatin1String(kNmPath), QLatin1String(kNmIface),
                                 QStringLiteral("WirelessEnabled")).toBool();

    bus().connect(QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kPropsIface),
                  QStringLiteral("PropertiesChanged"), this,
                  SLOT(onManagerPropertiesChanged(QString, QVariantMap, QStringList)));

    bus().connect(QLatin1String(kNm), m_devicePath, QLatin1String(kPropsIface),
                  QStringLiteral("PropertiesChanged"), this,
                  SLOT(onDevicePropertiesChanged(QString, QVariantMap, QStringList)));

    // Refresh định kỳ để cập nhật signal strength (NM không phát property cho từng AP).
    m_scanTimer = new QTimer(this);
    m_scanTimer->setInterval(10000);
    connect(m_scanTimer, &QTimer::timeout, this, &NetworkManagerBackend::readAccessPoints);
    m_scanTimer->start();

    reloadSavedConnections();
    readAccessPoints();
    return true;
}

bool NetworkManagerBackend::findWirelessDevice()
{
    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kNmIface),
        QStringLiteral("GetAllDevices"));

    QDBusMessage reply = bus().call(call, QDBus::Block, 1500);
    if (reply.type() != QDBusMessage::ReplyMessage) {
        // NM cũ chỉ có GetDevices.
        call = QDBusMessage::createMethodCall(
            QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kNmIface),
            QStringLiteral("GetDevices"));
        reply = bus().call(call, QDBus::Block, 1500);
        if (reply.type() != QDBusMessage::ReplyMessage)
            return false;
    }

    QList<QDBusObjectPath> devices;
    const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
    argument >> devices;

    for (const QDBusObjectPath &device : std::as_const(devices)) {
        const uint type = property(device.path(), QLatin1String(kDeviceIface),
                                   QStringLiteral("DeviceType")).toUInt();
        if (type == kDeviceTypeWifi) {
            m_devicePath = device.path();
            return true;
        }
    }
    return false;
}

void NetworkManagerBackend::reloadSavedConnections()
{
    m_savedConnections.clear();

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), QLatin1String(kSettingsPath), QLatin1String(kSettingsIface),
        QStringLiteral("ListConnections"));
    const QDBusMessage reply = bus().call(call, QDBus::Block, 1500);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty())
        return;

    QList<QDBusObjectPath> connections;
    const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
    argument >> connections;

    for (const QDBusObjectPath &connection : std::as_const(connections)) {
        QDBusMessage settingsCall = QDBusMessage::createMethodCall(
            QLatin1String(kNm), connection.path(), QLatin1String(kConnectionIface),
            QStringLiteral("GetSettings"));
        const QDBusMessage settingsReply = bus().call(settingsCall, QDBus::Block, 1200);
        if (settingsReply.type() != QDBusMessage::ReplyMessage || settingsReply.arguments().isEmpty())
            continue;

        NmConnectionSettings settings;
        const QDBusArgument settingsArgument =
            settingsReply.arguments().constFirst().value<QDBusArgument>();
        settingsArgument >> settings;

        const QVariantMap connectionSettings = settings.value(QStringLiteral("connection"));
        if (connectionSettings.value(QStringLiteral("type")).toString()
            != QLatin1String("802-11-wireless")) {
            continue;
        }

        const QVariantMap wireless = settings.value(QStringLiteral("802-11-wireless"));
        if (wireless.isEmpty())
            continue;

        const QByteArray raw = wireless.value(QStringLiteral("ssid")).toByteArray();
        const QString ssid = QString::fromUtf8(raw);
        if (!ssid.isEmpty() && !m_savedConnections.contains(ssid))
            m_savedConnections.insert(ssid, connection.path());
    }
}

// ------------------------------------------------------- access points ------

void NetworkManagerBackend::readAccessPoints()
{
    if (m_devicePath.isEmpty())
        return;

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), m_devicePath, QLatin1String(kWirelessIface),
        QStringLiteral("GetAllAccessPoints"));
    const QDBusMessage reply = bus().call(call, QDBus::Block, 2500);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        emit networksChanged({});
        return;
    }

    QList<QDBusObjectPath> accessPoints;
    const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
    argument >> accessPoints;

    const QString activePath = property(m_devicePath, QLatin1String(kWirelessIface),
                                        QStringLiteral("ActiveAccessPoint"))
                                   .value<QDBusObjectPath>().path();

    QHash<QString, WifiNetwork> best;
    for (const QDBusObjectPath &apPath : std::as_const(accessPoints)) {
        const QByteArray rawSsid =
            property(apPath.path(), QLatin1String(kApIface), QStringLiteral("Ssid")).toByteArray();
        const QString ssid = QString::fromUtf8(rawSsid);
        if (ssid.isEmpty())
            continue; // mạng ẩn

        WifiNetwork network;
        network.ssid = ssid;
        network.path = apPath.path();
        network.strength = property(apPath.path(), QLatin1String(kApIface),
                                    QStringLiteral("Strength")).toUInt();

        const uint wpaFlags = property(apPath.path(), QLatin1String(kApIface),
                                       QStringLiteral("WpaFlags")).toUInt();
        const uint rsnFlags = property(apPath.path(), QLatin1String(kApIface),
                                       QStringLiteral("RsnFlags")).toUInt();
        const uint flags = property(apPath.path(), QLatin1String(kApIface),
                                    QStringLiteral("Flags")).toUInt();
        network.security = securityFor(flags, wpaFlags, rsnFlags);
        network.secured = network.security == QLatin1String("psk")
            || network.security == QLatin1String("sae");
        network.known = m_savedConnections.contains(ssid);
        network.active = !activePath.isEmpty() && activePath == apPath.path();

        // Cùng SSID nhiều AP -> giữ cái mạnh nhất, nhưng ưu tiên cái đang kết nối.
        const auto existing = best.constFind(ssid);
        if (existing == best.constEnd()
            || network.active
            || (!existing->active && network.strength > existing->strength)) {
            best.insert(ssid, network);
        }
    }

    QVector<WifiNetwork> networks;
    networks.reserve(best.size());
    for (auto it = best.cbegin(); it != best.cend(); ++it)
        networks.append(it.value());

    std::sort(networks.begin(), networks.end(), [](const WifiNetwork &a, const WifiNetwork &b) {
        if (a.active != b.active) return a.active;
        if (a.strength != b.strength) return a.strength > b.strength;
        return a.ssid.localeAwareCompare(b.ssid) < 0;
    });

    emit networksChanged(networks);
}

void NetworkManagerBackend::onDevicePropertiesChanged(const QString &interfaceName,
                                                      const QVariantMap &changed,
                                                      const QStringList &)
{
    if (interfaceName != QLatin1String(kWirelessIface)
        && interfaceName != QLatin1String(kDeviceIface)) {
        return;
    }

    if (changed.contains(QStringLiteral("LastScan"))) {
        if (m_scanning) {
            m_scanning = false;
            emit scanningChanged(false);
        }
    }
    readAccessPoints();
}

void NetworkManagerBackend::onManagerPropertiesChanged(const QString &interfaceName,
                                                       const QVariantMap &changed,
                                                       const QStringList &)
{
    if (interfaceName != QLatin1String(kNmIface))
        return;

    if (changed.contains(QStringLiteral("WirelessEnabled"))) {
        m_wirelessEnabled = changed.value(QStringLiteral("WirelessEnabled")).toBool();
        emit wirelessEnabledChanged();
        if (!m_wirelessEnabled)
            emit networksChanged({});
        else
            requestScan();
    }
}

// --------------------------------------------------------------- actions ----

void NetworkManagerBackend::setWirelessEnabled(bool enabled)
{
    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kPropsIface),
        QStringLiteral("Set"));
    call << QLatin1String(kNmIface) << QStringLiteral("WirelessEnabled")
         << QVariant::fromValue(QDBusVariant(enabled));
    bus().asyncCall(call);
}

void NetworkManagerBackend::requestScan()
{
    if (m_devicePath.isEmpty() || !m_wirelessEnabled)
        return;

    if (!m_scanning) {
        m_scanning = true;
        emit scanningChanged(true);
    }

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), m_devicePath, QLatin1String(kWirelessIface),
        QStringLiteral("RequestScan"));
    call << QVariant::fromValue(QVariantMap());

    auto *watcher = new QDBusPendingCallWatcher(bus().asyncCall(call), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *self) {
        self->deleteLater();
        // Kết quả scan tới qua PropertiesChanged; đây chỉ là lưới an toàn.
        QTimer::singleShot(4000, this, [this] {
            if (m_scanning) {
                m_scanning = false;
                emit scanningChanged(false);
            }
            readAccessPoints();
        });
    });
}

void NetworkManagerBackend::refresh()
{
    reloadSavedConnections();
    m_wirelessEnabled = property(QLatin1String(kNmPath), QLatin1String(kNmIface),
                                 QStringLiteral("WirelessEnabled")).toBool();
    emit wirelessEnabledChanged();
    readAccessPoints();
}

void NetworkManagerBackend::connectToNetwork(const QString &ssid, const QString &password)
{
    if (m_devicePath.isEmpty()) {
        emit connectFinished(false, QStringLiteral("Không tìm thấy card Wi-Fi."));
        return;
    }

    m_pendingSsid = ssid;
    m_pendingConnectionPath.clear();

    if (!m_connectTimeout) {
        m_connectTimeout = new QTimer(this);
        m_connectTimeout->setSingleShot(true);
        m_connectTimeout->setInterval(35000);
        connect(m_connectTimeout, &QTimer::timeout, this, [this] {
            finishConnect(false, QStringLiteral("Kết nối quá lâu. Hãy thử lại."));
        });
    }
    m_connectTimeout->start();

    // Tìm AP tương ứng để NM chọn đúng band/BSSID, đồng thời lấy kiểu bảo mật
    // thật của nó để gửi đúng key-mgmt.
    QString apPath = QStringLiteral("/");
    QString security = QStringLiteral("open");
    {
        QDBusMessage call = QDBusMessage::createMethodCall(
            QLatin1String(kNm), m_devicePath, QLatin1String(kWirelessIface),
            QStringLiteral("GetAllAccessPoints"));
        const QDBusMessage reply = bus().call(call, QDBus::Block, 2000);
        if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty()) {
            QList<QDBusObjectPath> accessPoints;
            const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
            argument >> accessPoints;
            uint bestStrength = 0;
            for (const QDBusObjectPath &candidate : std::as_const(accessPoints)) {
                const QString candidateSsid = QString::fromUtf8(
                    property(candidate.path(), QLatin1String(kApIface),
                             QStringLiteral("Ssid")).toByteArray());
                if (candidateSsid != ssid)
                    continue;
                const uint strength = property(candidate.path(), QLatin1String(kApIface),
                                               QStringLiteral("Strength")).toUInt();
                if (apPath == QLatin1String("/") || strength > bestStrength) {
                    apPath = candidate.path();
                    bestStrength = strength;
                    security = securityFor(
                        property(candidate.path(), QLatin1String(kApIface),
                                 QStringLiteral("Flags")).toUInt(),
                        property(candidate.path(), QLatin1String(kApIface),
                                 QStringLiteral("WpaFlags")).toUInt(),
                        property(candidate.path(), QLatin1String(kApIface),
                                 QStringLiteral("RsnFlags")).toUInt());
                }
            }
        }
    }

    if (security == QLatin1String("enterprise")) {
        m_pendingSsid.clear();
        if (m_connectTimeout)
            m_connectTimeout->stop();
        emit connectFinished(
            false,
            QStringLiteral("Windra chưa hỗ trợ mạng doanh nghiệp (802.1X)."));
        return;
    }

    // Mạng đã lưu phải kích hoạt lại đúng profile hiện có để NetworkManager
    // lấy secret từ keyfile/secret agent. Tạo profile mới với mật khẩu rỗng sẽ
    // biến một mạng WPA đã lưu thành cấu hình thiếu 802-11-wireless-security.
    const QString savedConnectionPath = m_savedConnections.value(ssid);
    if (password.isEmpty() && !savedConnectionPath.isEmpty()) {
        QDBusMessage call = QDBusMessage::createMethodCall(
            QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kNmIface),
            QStringLiteral("ActivateConnection"));
        call << QVariant::fromValue(QDBusObjectPath(savedConnectionPath))
             << QVariant::fromValue(QDBusObjectPath(m_devicePath))
             << QVariant::fromValue(QDBusObjectPath(apPath));

        auto *watcher = new QDBusPendingCallWatcher(bus().asyncCall(call), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this,
                [this](QDBusPendingCallWatcher *self) {
            QDBusPendingReply<QDBusObjectPath> reply = *self;
            self->deleteLater();

            if (reply.isError()) {
                const QString name = reply.error().name();
                QString message = QStringLiteral("Không thể kết nối. Hãy thử lại.");
                if (name.contains(QStringLiteral("NotAuthorized"))
                    || name.contains(QStringLiteral("AuthFailed"))
                    || name.contains(QStringLiteral("PermissionDenied"))) {
                    message = QStringLiteral("Không đủ quyền để kết nối mạng này.");
                }
                finishConnect(false, message);
                return;
            }

            watchActiveConnection(reply.value());
        });
        return;
    }

    if ((security == QLatin1String("psk") || security == QLatin1String("sae"))
        && password.isEmpty()) {
        finishConnect(false, QStringLiteral("Mạng này cần mật khẩu."));
        return;
    }

    NmConnectionSettings settings;

    QVariantMap connection;
    connection.insert(QStringLiteral("id"), ssid);
    connection.insert(QStringLiteral("type"), QStringLiteral("802-11-wireless"));
    settings.insert(QStringLiteral("connection"), connection);

    QVariantMap wireless;
    wireless.insert(QStringLiteral("ssid"), ssid.toUtf8());
    wireless.insert(QStringLiteral("mode"), QStringLiteral("infrastructure"));
    settings.insert(QStringLiteral("802-11-wireless"), wireless);

    // key-mgmt phải khớp với AP: WPA3 thuần dùng "sae", WPA/WPA2 (kể cả
    // transition mode) dùng "wpa-psk", Enhanced Open dùng "owe" và không mật khẩu.
    if (security == QLatin1String("owe")) {
        QVariantMap wirelessSecurity;
        wirelessSecurity.insert(QStringLiteral("key-mgmt"), QStringLiteral("owe"));
        settings.insert(QStringLiteral("802-11-wireless-security"), wirelessSecurity);
    } else if (!password.isEmpty()) {
        QVariantMap wirelessSecurity;
        wirelessSecurity.insert(QStringLiteral("key-mgmt"),
                                security == QLatin1String("sae")
                                    ? QStringLiteral("sae")
                                    : QStringLiteral("wpa-psk"));
        wirelessSecurity.insert(QStringLiteral("psk"), password);
        settings.insert(QStringLiteral("802-11-wireless-security"), wirelessSecurity);
    }

    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), QLatin1String(kNmPath), QLatin1String(kNmIface),
        QStringLiteral("AddAndActivateConnection"));
    call << QVariant::fromValue(settings)
         << QVariant::fromValue(QDBusObjectPath(m_devicePath))
         << QVariant::fromValue(QDBusObjectPath(apPath));

    auto *watcher = new QDBusPendingCallWatcher(bus().asyncCall(call), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *self) {
        QDBusPendingReply<QDBusObjectPath, QDBusObjectPath> reply = *self;
        self->deleteLater();

        if (reply.isError()) {
            const QString name = reply.error().name();
            QString message = QStringLiteral("Không thể kết nối. Hãy thử lại.");
            if (name.contains(QStringLiteral("NotAuthorized"))
                || name.contains(QStringLiteral("AuthFailed"))
                || name.contains(QStringLiteral("PermissionDenied"))) {
                message = QStringLiteral("Không đủ quyền để kết nối mạng này.");
            }
            finishConnect(false, message);
            return;
        }

        m_pendingConnectionPath = reply.argumentAt<0>().path();
        watchActiveConnection(reply.argumentAt<1>());
    });
}

void NetworkManagerBackend::watchActiveConnection(const QDBusObjectPath &path)
{
    m_activeConnectionPath = path.path();
    if (m_activeConnectionPath.isEmpty() || m_activeConnectionPath == QLatin1String("/")) {
        finishConnect(false, QStringLiteral("Không thể kết nối. Hãy thử lại."));
        return;
    }

    bus().connect(QLatin1String(kNm), m_activeConnectionPath, QLatin1String(kActiveIface),
                  QStringLiteral("StateChanged"), this,
                  SLOT(onActiveConnectionStateChanged(uint, uint)));

    // Có thể đã ACTIVATED trước khi kịp nối signal.
    const uint state = property(m_activeConnectionPath, QLatin1String(kActiveIface),
                                QStringLiteral("State")).toUInt();
    if (state == kActiveStateActivated)
        finishConnect(true, QString());
}

void NetworkManagerBackend::onActiveConnectionStateChanged(uint state, uint reason)
{
    if (state == kActiveStateActivated) {
        finishConnect(true, QString());
    } else if (state == kActiveStateDeactivated) {
        finishConnect(false, reasonToText(reason));
    }
}

void NetworkManagerBackend::finishConnect(bool ok, const QString &error)
{
    if (m_pendingSsid.isEmpty())
        return; // đã báo kết quả rồi

    if (m_connectTimeout)
        m_connectTimeout->stop();

    if (!m_activeConnectionPath.isEmpty()) {
        bus().disconnect(QLatin1String(kNm), m_activeConnectionPath, QLatin1String(kActiveIface),
                         QStringLiteral("StateChanged"), this,
                         SLOT(onActiveConnectionStateChanged(uint, uint)));
    }

    // Kết nối hỏng: xoá profile vừa tạo để mật khẩu sai không bị lưu lại.
    if (!ok && !m_pendingConnectionPath.isEmpty()) {
        QDBusMessage remove = QDBusMessage::createMethodCall(
            QLatin1String(kNm), m_pendingConnectionPath, QLatin1String(kConnectionIface),
            QStringLiteral("Delete"));
        bus().asyncCall(remove);
    }

    m_pendingSsid.clear();
    m_pendingConnectionPath.clear();
    m_activeConnectionPath.clear();

    reloadSavedConnections();
    readAccessPoints();
    emit connectFinished(ok, error);
}

QString NetworkManagerBackend::reasonToText(uint reason)
{
    // NMActiveConnectionStateReason
    switch (reason) {
    case 9:  // no-secrets
    case 10: // login-failed
        return QStringLiteral("Không thể kết nối. Hãy kiểm tra mật khẩu và thử lại.");
    case 6:  // connect-timeout
        return QStringLiteral("Mạng không phản hồi. Hãy thử lại.");
    case 3:  // device-disconnected
    case 14: // device-removed
        return QStringLiteral("Card Wi-Fi đã ngắt kết nối.");
    case 5:  // ip-config-invalid
        return QStringLiteral("Kết nối được nhưng không nhận được địa chỉ IP.");
    case 2:  // user-disconnected
        return QString();
    default:
        return QStringLiteral("Không thể kết nối. Hãy kiểm tra mật khẩu và thử lại.");
    }
}

void NetworkManagerBackend::disconnectCurrent()
{
    if (m_devicePath.isEmpty())
        return;
    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kNm), m_devicePath, QLatin1String(kDeviceIface),
        QStringLiteral("Disconnect"));
    bus().asyncCall(call);
}
