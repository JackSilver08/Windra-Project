#include "NmcliBackend.h"

#include "ProcessRunner.h"

#include <QHash>
#include <QTimer>

namespace {
constexpr auto kNmcli = "nmcli";

/*!
 * Ánh xạ cột SECURITY của nmcli sang cùng bộ giá trị với backend D-Bus.
 * Ví dụ giá trị thật: "", "--", "WPA2", "WPA1 WPA2", "WPA2 WPA3", "WPA3",
 * "WPA2 802.1X", "OWE".
 */
QString securityFromNmcli(const QString &raw)
{
    const QString value = raw.trimmed().toUpper();
    if (value.isEmpty() || value == QLatin1String("--"))
        return QStringLiteral("open");
    if (value.contains(QLatin1String("802.1X")))
        return QStringLiteral("enterprise");
    if (value.contains(QLatin1String("OWE")))
        return QStringLiteral("owe");
    // WPA2 WPA3 transition -> psk (tương thích rộng hơn); chỉ WPA3 thuần mới sae.
    if (value.contains(QLatin1String("WPA3")) && !value.contains(QLatin1String("WPA2")))
        return QStringLiteral("sae");
    return QStringLiteral("psk");
}
}

NmcliBackend::NmcliBackend(QObject *parent)
    : NetworkBackend(parent)
{
}

bool NmcliBackend::probe()
{
    if (!ProcessRunner::exists(QLatin1String(kNmcli)))
        return false;

    m_poll = new QTimer(this);
    m_poll->setInterval(10000);
    connect(m_poll, &QTimer::timeout, this, &NmcliBackend::readNetworks);
    m_poll->start();

    readRadio();
    readSaved();
    return true;
}

/*!
 * nmcli -t escape ':' và '\' bằng '\'. Tách theo ':' nhưng bỏ qua ký tự đã escape.
 */
QStringList NmcliBackend::splitEscaped(const QString &line)
{
    QStringList fields;
    QString current;
    for (int i = 0; i < line.size(); ++i) {
        const QChar ch = line.at(i);
        if (ch == QLatin1Char('\\') && i + 1 < line.size()) {
            current.append(line.at(++i));
        } else if (ch == QLatin1Char(':')) {
            fields << current;
            current.clear();
        } else {
            current.append(ch);
        }
    }
    fields << current;
    return fields;
}

void NmcliBackend::readRadio()
{
    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("radio"), QStringLiteral("wifi")},
                       [this](const ProcessRunner::Result &result) {
        const bool enabled = result.ok
            && result.stdOut.trimmed().compare(QStringLiteral("enabled"), Qt::CaseInsensitive) == 0;
        if (enabled != m_wirelessEnabled) {
            m_wirelessEnabled = enabled;
            emit wirelessEnabledChanged();
        }
        if (m_wirelessEnabled)
            readNetworks();
        else
            emit networksChanged({});
    });
}

void NmcliBackend::readSaved()
{
    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("-t"), QStringLiteral("-f"),
                        QStringLiteral("NAME,TYPE"), QStringLiteral("connection"),
                        QStringLiteral("show")},
                       [this](const ProcessRunner::Result &result) {
        m_savedSsids.clear();
        if (result.ok) {
            const QStringList lines = result.stdOut.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            for (const QString &line : lines) {
                const QStringList fields = splitEscaped(line);
                if (fields.size() >= 2 && fields.at(1).contains(QStringLiteral("wireless")))
                    m_savedSsids << fields.at(0);
            }
        }
        readNetworks();
    });
}

void NmcliBackend::readNetworks()
{
    if (!m_wirelessEnabled) {
        emit networksChanged({});
        return;
    }

    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("-t"), QStringLiteral("-f"),
                        QStringLiteral("ACTIVE,SSID,SIGNAL,SECURITY,BSSID"),
                        QStringLiteral("device"), QStringLiteral("wifi"),
                        QStringLiteral("list")},
                       [this](const ProcessRunner::Result &result) {
        if (m_scanning) {
            m_scanning = false;
            emit scanningChanged(false);
        }
        if (!result.ok) {
            emit networksChanged({});
            return;
        }

        QHash<QString, WifiNetwork> best;
        const QStringList lines = result.stdOut.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = splitEscaped(line);
            if (fields.size() < 4)
                continue;

            WifiNetwork network;
            network.active = fields.at(0) == QLatin1String("yes");
            network.ssid = fields.at(1);
            if (network.ssid.isEmpty())
                continue;
            network.strength = fields.at(2).toInt();
            network.security = securityFromNmcli(fields.at(3));
            network.secured = network.security == QLatin1String("psk")
                || network.security == QLatin1String("sae");
            network.known = m_savedSsids.contains(network.ssid);
            network.path = fields.size() > 4 ? fields.at(4) : QString();

            const auto existing = best.constFind(network.ssid);
            if (existing == best.constEnd()
                || network.active
                || (!existing->active && network.strength > existing->strength)) {
                best.insert(network.ssid, network);
            }
        }

        QVector<WifiNetwork> networks;
        networks.reserve(best.size());
        for (auto it = best.cbegin(); it != best.cend(); ++it)
            networks.append(it.value());

        std::sort(networks.begin(), networks.end(),
                  [](const WifiNetwork &a, const WifiNetwork &b) {
            if (a.active != b.active) return a.active;
            if (a.strength != b.strength) return a.strength > b.strength;
            return a.ssid.localeAwareCompare(b.ssid) < 0;
        });

        emit networksChanged(networks);
    });
}

void NmcliBackend::setWirelessEnabled(bool enabled)
{
    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("radio"), QStringLiteral("wifi"),
                        enabled ? QStringLiteral("on") : QStringLiteral("off")},
                       [this](const ProcessRunner::Result &) { readRadio(); });
}

void NmcliBackend::requestScan()
{
    if (!m_wirelessEnabled)
        return;
    if (!m_scanning) {
        m_scanning = true;
        emit scanningChanged(true);
    }
    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("device"), QStringLiteral("wifi"),
                        QStringLiteral("rescan")},
                       [this](const ProcessRunner::Result &) {
        QTimer::singleShot(2500, this, [this] { readNetworks(); });
    }, 15000);
}

void NmcliBackend::refresh()
{
    readRadio();
    readSaved();
}

void NmcliBackend::connectToNetwork(const QString &ssid, const QString &password)
{
    QStringList arguments{QStringLiteral("device"), QStringLiteral("wifi"),
                          QStringLiteral("connect"), ssid};
    if (!password.isEmpty())
        arguments << QStringLiteral("password") << password;

    ProcessRunner::run(this, QLatin1String(kNmcli), arguments,
                       [this](const ProcessRunner::Result &result) {
        if (result.ok) {
            readSaved();
            emit connectFinished(true, QString());
            return;
        }

        const QString raw = (result.stdErr + result.stdOut).toLower();
        QString message = QStringLiteral("Không thể kết nối. Hãy thử lại.");
        if (raw.contains(QStringLiteral("secrets")) || raw.contains(QStringLiteral("password"))
            || raw.contains(QStringLiteral("802-11-wireless-security"))) {
            message = QStringLiteral("Không thể kết nối. Hãy kiểm tra mật khẩu và thử lại.");
        } else if (raw.contains(QStringLiteral("timeout"))) {
            message = QStringLiteral("Mạng không phản hồi. Hãy thử lại.");
        } else if (raw.contains(QStringLiteral("not authorized"))
                   || raw.contains(QStringLiteral("permission"))) {
            message = QStringLiteral("Không đủ quyền để kết nối mạng này.");
        }
        readNetworks();
        emit connectFinished(false, message);
    }, 45000);
}

void NmcliBackend::disconnectCurrent()
{
    // nmcli cần tên interface, nên hỏi device status trước.
    ProcessRunner::run(this, QLatin1String(kNmcli),
                       {QStringLiteral("-t"), QStringLiteral("-f"),
                        QStringLiteral("DEVICE,TYPE"), QStringLiteral("device"),
                        QStringLiteral("status")},
                       [this](const ProcessRunner::Result &result) {
        if (!result.ok)
            return;
        const QStringList lines = result.stdOut.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = splitEscaped(line);
            if (fields.size() < 2 || fields.at(1) != QLatin1String("wifi"))
                continue;
            ProcessRunner::run(this, QLatin1String(kNmcli),
                               {QStringLiteral("device"), QStringLiteral("disconnect"),
                                fields.at(0)},
                               [this](const ProcessRunner::Result &) { readNetworks(); },
                               15000);
            return;
        }
    });
}
