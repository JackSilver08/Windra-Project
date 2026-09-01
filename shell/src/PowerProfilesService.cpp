#include "PowerProfilesService.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusVariant>
#include <QVariantMap>

namespace {
constexpr auto kPropertiesIface = "org.freedesktop.DBus.Properties";
}

PowerProfilesService::PowerProfilesService(QObject *parent)
    : QObject(parent)
{
    const bool found =
        probe(QStringLiteral("org.freedesktop.UPower.PowerProfiles"),
              QStringLiteral("/org/freedesktop/UPower/PowerProfiles"),
              QStringLiteral("org.freedesktop.UPower.PowerProfiles"))
        || probe(QStringLiteral("net.hadess.PowerProfiles"),
                 QStringLiteral("/net/hadess/PowerProfiles"),
                 QStringLiteral("net.hadess.PowerProfiles"));

    if (!found)
        return;

    QDBusConnection::systemBus().connect(
        m_service, m_path, QLatin1String(kPropertiesIface),
        QStringLiteral("PropertiesChanged"), this,
        SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));

    refresh();
}

bool PowerProfilesService::probe(const QString &service, const QString &path, const QString &iface)
{
    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.isConnected())
        return false;

    QDBusMessage call = QDBusMessage::createMethodCall(
        service, path, QLatin1String(kPropertiesIface), QStringLiteral("GetAll"));
    call << iface;

    const QDBusMessage reply = bus.call(call, QDBus::Block, 1200);
    if (reply.type() != QDBusMessage::ReplyMessage)
        return false;

    m_service = service;
    m_path = path;
    m_interface = iface;
    m_available = true;
    return true;
}

void PowerProfilesService::refresh()
{
    if (!m_available)
        return;

    QDBusConnection bus = QDBusConnection::systemBus();
    QDBusMessage call = QDBusMessage::createMethodCall(
        m_service, m_path, QLatin1String(kPropertiesIface), QStringLiteral("GetAll"));
    call << m_interface;

    const QDBusMessage reply = bus.call(call, QDBus::Block, 1500);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        m_available = false;
        emit changed();
        return;
    }

    QVariantMap props;
    const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
    argument >> props;

    const QString active = props.value(QStringLiteral("ActiveProfile")).toString();

    // Profiles là aa{sv}; mỗi phần tử có key "Profile".
    QStringList names;
    const QDBusArgument list = props.value(QStringLiteral("Profiles")).value<QDBusArgument>();
    if (list.currentType() == QDBusArgument::ArrayType) {
        list.beginArray();
        while (!list.atEnd()) {
            QVariantMap entry;
            list >> entry;
            const QString name = entry.value(QStringLiteral("Profile")).toString();
            if (!name.isEmpty())
                names << name;
        }
        list.endArray();
    }

    if (active == m_activeProfile && names == m_profiles)
        return;

    m_activeProfile = active;
    if (!names.isEmpty())
        m_profiles = names;
    emit changed();
}

void PowerProfilesService::onPropertiesChanged(const QString &interfaceName,
                                               const QVariantMap &,
                                               const QStringList &)
{
    if (interfaceName == m_interface)
        refresh();
}

bool PowerProfilesService::hasProfile(const QString &profile) const
{
    return m_profiles.contains(profile);
}

void PowerProfilesService::setProfile(const QString &profile)
{
    if (!m_available || profile.isEmpty())
        return;

    QDBusConnection bus = QDBusConnection::systemBus();
    QDBusMessage call = QDBusMessage::createMethodCall(
        m_service, m_path, QLatin1String(kPropertiesIface), QStringLiteral("Set"));
    call << m_interface << QStringLiteral("ActiveProfile")
         << QVariant::fromValue(QDBusVariant(profile));
    bus.asyncCall(call);

    // Cập nhật lạc quan; PropertiesChanged sẽ xác nhận hoặc sửa lại.
    if (m_activeProfile != profile) {
        m_activeProfile = profile;
        emit changed();
    }
}

QString PowerProfilesService::displayName(const QString &profile)
{
    if (profile == QLatin1String("power-saver")) return QStringLiteral("Tiết kiệm");
    if (profile == QLatin1String("balanced")) return QStringLiteral("Cân bằng");
    if (profile == QLatin1String("performance")) return QStringLiteral("Hiệu năng");
    return profile;
}

QString PowerProfilesService::activeProfileText() const
{
    if (!m_available)
        return QStringLiteral("Không khả dụng");
    if (m_activeProfile.isEmpty())
        return QStringLiteral("Không rõ");
    return displayName(m_activeProfile);
}
