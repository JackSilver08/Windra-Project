#include "AudioBackend.h"

#include "ProcessRunner.h"

#include <QRegularExpression>

namespace {

constexpr auto kWpctl = "wpctl";
constexpr auto kPactl = "pactl";
constexpr auto kDefaultSink = "@DEFAULT_AUDIO_SINK@";
constexpr auto kPulseSink = "@DEFAULT_SINK@";

} // namespace

// -------------------------------------------------------- WirePlumber CLI ----

bool WirePlumberCliBackend::probe()
{
    return ProcessRunner::exists(QLatin1String(kWpctl));
}

void WirePlumberCliBackend::refresh()
{
    ProcessRunner::run(this, QLatin1String(kWpctl),
                       {QStringLiteral("get-volume"), QLatin1String(kDefaultSink)},
                       [this](const ProcessRunner::Result &result) {
        if (!result.ok) {
            emit stateChanged(false, 0, false, QString());
            return;
        }

        // "Volume: 0.72" hoặc "Volume: 0.72 [MUTED]"
        static const QRegularExpression re(QStringLiteral("Volume:\\s*([0-9]*\\.?[0-9]+)"));
        const auto match = re.match(result.stdOut);
        if (!match.hasMatch()) {
            emit stateChanged(false, 0, false, QString());
            return;
        }

        const int volume = qBound(0, qRound(match.captured(1).toDouble() * 100.0), 100);
        const bool muted = result.stdOut.contains(QStringLiteral("[MUTED]"));
        emit stateChanged(true, volume, muted, m_deviceName);

        if (m_deviceName.isEmpty())
            readDeviceName();
    });
}

void WirePlumberCliBackend::readDeviceName()
{
    ProcessRunner::run(this, QLatin1String(kWpctl),
                       {QStringLiteral("inspect"), QLatin1String(kDefaultSink)},
                       [this](const ProcessRunner::Result &result) {
        if (!result.ok)
            return;
        static const QRegularExpression re(
            QStringLiteral("node\\.description\\s*=\\s*\"([^\"]+)\""));
        const auto match = re.match(result.stdOut);
        if (!match.hasMatch())
            return;
        m_deviceName = match.captured(1);
        refresh();
    });
}

void WirePlumberCliBackend::setVolume(int percent)
{
    ProcessRunner::runDetachedResult(
        this, QLatin1String(kWpctl),
        {QStringLiteral("set-volume"), QLatin1String(kDefaultSink),
         QStringLiteral("%1%").arg(qBound(0, percent, 100))});
}

void WirePlumberCliBackend::setMuted(bool muted)
{
    ProcessRunner::run(this, QLatin1String(kWpctl),
                       {QStringLiteral("set-mute"), QLatin1String(kDefaultSink),
                        muted ? QStringLiteral("1") : QStringLiteral("0")},
                       [this](const ProcessRunner::Result &) { refresh(); });
}

void WirePlumberCliBackend::toggleMuted()
{
    ProcessRunner::run(this, QLatin1String(kWpctl),
                       {QStringLiteral("set-mute"), QLatin1String(kDefaultSink),
                        QStringLiteral("toggle")},
                       [this](const ProcessRunner::Result &) { refresh(); });
}

// -------------------------------------------------------------- Pulse CLI ----

bool PulseCliBackend::probe()
{
    return ProcessRunner::exists(QLatin1String(kPactl));
}

void PulseCliBackend::refresh()
{
    ProcessRunner::run(this, QLatin1String(kPactl),
                       {QStringLiteral("get-sink-volume"), QLatin1String(kPulseSink)},
                       [this](const ProcessRunner::Result &result) {
        if (!result.ok) {
            emit stateChanged(false, 0, false, QString());
            return;
        }
        // "Volume: front-left: 47184 /  72% / -8.68 dB, ..."
        static const QRegularExpression re(QStringLiteral("([0-9]+)%"));
        const auto match = re.match(result.stdOut);
        if (!match.hasMatch()) {
            emit stateChanged(false, 0, false, QString());
            return;
        }
        readMute(qBound(0, match.captured(1).toInt(), 100));
    });
}

void PulseCliBackend::readMute(int volume)
{
    ProcessRunner::run(this, QLatin1String(kPactl),
                       {QStringLiteral("get-sink-mute"), QLatin1String(kPulseSink)},
                       [this, volume](const ProcessRunner::Result &result) {
        const bool muted = result.ok && result.stdOut.contains(QStringLiteral("yes"));
        emit stateChanged(true, volume, muted, m_deviceName);
        if (m_deviceName.isEmpty())
            readDeviceName();
    });
}

void PulseCliBackend::readDeviceName()
{
    // Hỏi default sink trước rồi mới tra tên, thay vì lấy bừa Description đầu
    // tiên trong `pactl list sinks` — máy nhiều sink sẽ hiện sai thiết bị.
    ProcessRunner::run(this, QLatin1String(kPactl), {QStringLiteral("get-default-sink")},
                       [this](const ProcessRunner::Result &defaultSink) {
        const QString sinkName = defaultSink.ok ? defaultSink.stdOut.trimmed() : QString();

        ProcessRunner::run(this, QLatin1String(kPactl),
                           {QStringLiteral("list"), QStringLiteral("sinks")},
                           [this, sinkName](const ProcessRunner::Result &result) {
            if (!result.ok)
                return;

            // Mỗi sink là một khối "Sink #N" ... "Name: x" ... "Description: y".
            const QStringList blocks = result.stdOut.split(QStringLiteral("Sink #"),
                                                           Qt::SkipEmptyParts);
            static const QRegularExpression nameRe(QStringLiteral("\\bName:\\s*(\\S+)"));
            static const QRegularExpression descriptionRe(
                QStringLiteral("\\bDescription:\\s*(.+)"));

            QString fallback;
            for (const QString &block : blocks) {
                const auto description = descriptionRe.match(block);
                if (!description.hasMatch())
                    continue;
                const QString label = description.captured(1).trimmed();
                if (fallback.isEmpty())
                    fallback = label;

                const auto name = nameRe.match(block);
                if (!sinkName.isEmpty() && name.hasMatch()
                    && name.captured(1) == sinkName) {
                    fallback = label;
                    break;
                }
            }

            if (fallback.isEmpty() || fallback == m_deviceName)
                return;
            m_deviceName = fallback;
            refresh();
        });
    });
}

void PulseCliBackend::setVolume(int percent)
{
    ProcessRunner::runDetachedResult(
        this, QLatin1String(kPactl),
        {QStringLiteral("set-sink-volume"), QLatin1String(kPulseSink),
         QStringLiteral("%1%").arg(qBound(0, percent, 100))});
}

void PulseCliBackend::setMuted(bool muted)
{
    ProcessRunner::run(this, QLatin1String(kPactl),
                       {QStringLiteral("set-sink-mute"), QLatin1String(kPulseSink),
                        muted ? QStringLiteral("1") : QStringLiteral("0")},
                       [this](const ProcessRunner::Result &) { refresh(); });
}

void PulseCliBackend::toggleMuted()
{
    ProcessRunner::run(this, QLatin1String(kPactl),
                       {QStringLiteral("set-sink-mute"), QLatin1String(kPulseSink),
                        QStringLiteral("toggle")},
                       [this](const ProcessRunner::Result &) { refresh(); });
}
