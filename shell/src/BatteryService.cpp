#include "BatteryService.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QTimer>

namespace {

constexpr auto kUPowerService = "org.freedesktop.UPower";
constexpr auto kUPowerDisplayDevice = "/org/freedesktop/UPower/devices/DisplayDevice";
constexpr auto kUPowerDeviceIface = "org.freedesktop.UPower.Device";
constexpr auto kPropertiesIface = "org.freedesktop.DBus.Properties";

// org.freedesktop.UPower.Device.State
QString upowerState(uint value)
{
    switch (value) {
    case 1: return QStringLiteral("charging");
    case 2: return QStringLiteral("discharging");
    case 3: return QStringLiteral("empty");
    case 4: return QStringLiteral("full");
    case 5: return QStringLiteral("pending");   // pending-charge
    case 6: return QStringLiteral("pending");   // pending-discharge
    default: return QStringLiteral("unknown");
    }
}

QString sysfsState(const QString &raw)
{
    const QString value = raw.trimmed().toLower();
    if (value == QLatin1String("charging")) return QStringLiteral("charging");
    if (value == QLatin1String("discharging")) return QStringLiteral("discharging");
    if (value == QLatin1String("full")) return QStringLiteral("full");
    if (value == QLatin1String("not charging")) return QStringLiteral("pending");
    return QStringLiteral("unknown");
}

QString readFileTrimmed(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll()).trimmed();
}

qint64 readNumber(const QString &path, bool *ok = nullptr)
{
    const QString raw = readFileTrimmed(path);
    if (raw.isEmpty()) {
        if (ok) *ok = false;
        return 0;
    }
    return raw.toLongLong(ok);
}

QString formatDuration(qint64 seconds)
{
    if (seconds <= 0)
        return {};
    const qint64 hours = seconds / 3600;
    const qint64 minutes = (seconds % 3600) / 60;
    if (hours > 0 && minutes > 0)
        return QStringLiteral("%1 giờ %2 phút").arg(hours).arg(minutes);
    if (hours > 0)
        return QStringLiteral("%1 giờ").arg(hours);
    if (minutes > 0)
        return QStringLiteral("%1 phút").arg(minutes);
    return QStringLiteral("dưới 1 phút");
}

} // namespace

BatteryService::BatteryService(QObject *parent)
    : QObject(parent)
{
    if (!setupUPower())
        setupSysfs();

    refresh();
}

bool BatteryService::charging() const
{
    return m_state == QLatin1String("charging") || m_state == QLatin1String("pending");
}

QString BatteryService::level() const
{
    if (!m_available || m_percent < 0)
        return QStringLiteral("unknown");
    if (m_percent >= 100) return QStringLiteral("full");
    if (m_percent >= 76) return QStringLiteral("veryhigh");
    if (m_percent >= 51) return QStringLiteral("high");
    if (m_percent >= 26) return QStringLiteral("medium");
    if (m_percent >= 11) return QStringLiteral("low");
    return QStringLiteral("critical");
}

QString BatteryService::stateText() const
{
    if (!m_available)
        return QStringLiteral("Không có pin");
    if (m_state == QLatin1String("charging")) return QStringLiteral("Đang sạc");
    if (m_state == QLatin1String("discharging")) return QStringLiteral("Đang sử dụng");
    if (m_state == QLatin1String("full")) return QStringLiteral("Đã sạc đầy");
    if (m_state == QLatin1String("empty")) return QStringLiteral("Sắp hết pin");
    if (m_state == QLatin1String("pending")) return QStringLiteral("Đã cắm sạc");
    return QStringLiteral("Không rõ trạng thái");
}

QString BatteryService::remainingText() const
{
    if (!m_available)
        return {};
    if (m_state == QLatin1String("full"))
        return QStringLiteral("Đã sạc đầy");
    const QString duration = formatDuration(m_secondsLeft);
    if (duration.isEmpty())
        return QStringLiteral("Đang tính toán...");
    return m_state == QLatin1String("charging")
        ? QStringLiteral("Đầy sau khoảng %1").arg(duration)
        : QStringLiteral("Còn khoảng %1").arg(duration);
}

QString BatteryService::tooltipText() const
{
    if (!m_available)
        return QStringLiteral("Máy này không có pin");
    return QStringLiteral("Pin %1% · %2").arg(m_percent).arg(stateText().toLower());
}

// ---------------------------------------------------------------- UPower ----

bool BatteryService::setupUPower()
{
    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.isConnected())
        return false;

    QDBusMessage probe = QDBusMessage::createMethodCall(
        QLatin1String(kUPowerService),
        QLatin1String(kUPowerDisplayDevice),
        QLatin1String(kPropertiesIface),
        QStringLiteral("GetAll"));
    probe << QLatin1String(kUPowerDeviceIface);

    const QDBusMessage reply = bus.call(probe, QDBus::Block, 1200);
    if (reply.type() != QDBusMessage::ReplyMessage)
        return false;

    m_devicePath = QLatin1String(kUPowerDisplayDevice);
    m_source = QStringLiteral("upower");

    bus.connect(QLatin1String(kUPowerService),
                m_devicePath,
                QLatin1String(kPropertiesIface),
                QStringLiteral("PropertiesChanged"),
                this,
                SLOT(onUPowerPropertiesChanged(QString, QVariantMap, QStringList)));

    // Lưới an toàn: một số bản UPower không phát PropertiesChanged cho DisplayDevice.
    m_poll = new QTimer(this);
    m_poll->setInterval(30000);
    connect(m_poll, &QTimer::timeout, this, &BatteryService::refresh);
    m_poll->start();
    return true;
}

void BatteryService::onUPowerPropertiesChanged(const QString &interfaceName,
                                               const QVariantMap &,
                                               const QStringList &)
{
    if (interfaceName == QLatin1String(kUPowerDeviceIface))
        readUPower();
}

void BatteryService::readUPower()
{
    QDBusConnection bus = QDBusConnection::systemBus();
    QDBusMessage call = QDBusMessage::createMethodCall(
        QLatin1String(kUPowerService),
        m_devicePath,
        QLatin1String(kPropertiesIface),
        QStringLiteral("GetAll"));
    call << QLatin1String(kUPowerDeviceIface);

    const QDBusMessage reply = bus.call(call, QDBus::Block, 1500);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        apply(false, -1, QStringLiteral("unknown"), 0);
        return;
    }

    QVariantMap props;
    const QDBusArgument argument = reply.arguments().constFirst().value<QDBusArgument>();
    argument >> props;

    // Type 2 == battery. DisplayDevice trả về 0 (unknown) khi máy không có pin.
    const uint type = props.value(QStringLiteral("Type")).toUInt();
    const bool present = props.value(QStringLiteral("IsPresent"), true).toBool();
    if (type != 2u || !present) {
        apply(false, -1, QStringLiteral("unknown"), 0);
        return;
    }

    const int percent = qRound(props.value(QStringLiteral("Percentage")).toDouble());
    const QString state = upowerState(props.value(QStringLiteral("State")).toUInt());
    const qint64 seconds = state == QLatin1String("charging")
        ? props.value(QStringLiteral("TimeToFull")).toLongLong()
        : props.value(QStringLiteral("TimeToEmpty")).toLongLong();

    apply(true, qBound(0, percent, 100), state, seconds);
}

// ----------------------------------------------------------------- sysfs ----

void BatteryService::setupSysfs()
{
    const QDir root(QStringLiteral("/sys/class/power_supply"));
    const QStringList entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::System);
    for (const QString &entry : entries) {
        const QString path = root.filePath(entry);
        if (readFileTrimmed(path + QStringLiteral("/type")) == QLatin1String("Battery")) {
            m_sysfsPath = path;
            m_source = QStringLiteral("sysfs");
            break;
        }
    }

    if (m_sysfsPath.isEmpty())
        return;

    m_poll = new QTimer(this);
    m_poll->setInterval(8000);
    connect(m_poll, &QTimer::timeout, this, &BatteryService::refresh);
    m_poll->start();
}

void BatteryService::readSysfs()
{
    if (readFileTrimmed(m_sysfsPath + QStringLiteral("/present")) == QLatin1String("0")) {
        apply(false, -1, QStringLiteral("unknown"), 0);
        return;
    }

    bool ok = false;
    const qint64 capacity = readNumber(m_sysfsPath + QStringLiteral("/capacity"), &ok);
    if (!ok) {
        apply(false, -1, QStringLiteral("unknown"), 0);
        return;
    }

    const QString state = sysfsState(readFileTrimmed(m_sysfsPath + QStringLiteral("/status")));

    // Ước tính thời gian: energy (µWh/µW) hoặc charge (µAh/µA) tuỳ driver.
    qint64 seconds = 0;
    bool haveNow = false, haveRate = false, haveFull = false;
    const qint64 now = readNumber(m_sysfsPath + QStringLiteral("/energy_now"), &haveNow);
    const qint64 rate = readNumber(m_sysfsPath + QStringLiteral("/power_now"), &haveRate);
    const qint64 full = readNumber(m_sysfsPath + QStringLiteral("/energy_full"), &haveFull);

    qint64 nowValue = now, rateValue = rate, fullValue = full;
    if (!haveNow || !haveRate) {
        nowValue = readNumber(m_sysfsPath + QStringLiteral("/charge_now"), &haveNow);
        rateValue = readNumber(m_sysfsPath + QStringLiteral("/current_now"), &haveRate);
        fullValue = readNumber(m_sysfsPath + QStringLiteral("/charge_full"), &haveFull);
    }

    if (haveNow && haveRate && rateValue > 0) {
        const qint64 delta = state == QLatin1String("charging")
            ? (haveFull ? fullValue - nowValue : 0)
            : nowValue;
        if (delta > 0)
            seconds = (delta * 3600) / rateValue;
    }

    apply(true, static_cast<int>(qBound(qint64(0), capacity, qint64(100))), state, seconds);
}

// ------------------------------------------------------------------ misc ----

void BatteryService::refresh()
{
    if (m_source == QLatin1String("upower"))
        readUPower();
    else if (m_source == QLatin1String("sysfs"))
        readSysfs();
    else
        apply(false, -1, QStringLiteral("unknown"), 0);
}

void BatteryService::apply(bool available, int percent, const QString &state, qint64 secondsLeft)
{
    if (available == m_available && percent == m_percent
        && state == m_state && secondsLeft == m_secondsLeft) {
        return;
    }

    m_available = available;
    m_percent = percent;
    m_state = state;
    m_secondsLeft = secondsLeft;
    emit changed();
}
