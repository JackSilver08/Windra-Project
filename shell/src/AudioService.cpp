#include "AudioService.h"

#include "AudioBackend.h"

#include <QTimer>

AudioService::AudioService(QObject *parent)
    : QObject(parent)
{
    // PipeWire/WirePlumber trước, PulseAudio-compatible sau.
    auto *wireplumber = new WirePlumberCliBackend(this);
    if (wireplumber->probe()) {
        m_backend = wireplumber;
    } else {
        delete wireplumber;
        auto *pulse = new PulseCliBackend(this);
        if (pulse->probe())
            m_backend = pulse;
        else
            delete pulse;
    }

    if (!m_backend)
        return;

    connect(m_backend, &AudioBackend::stateChanged, this, &AudioService::onBackendState);

    m_settleGuard = new QTimer(this);
    m_settleGuard->setSingleShot(true);
    m_settleGuard->setInterval(700);

    m_poll = new QTimer(this);
    m_poll->setInterval(2500);
    connect(m_poll, &QTimer::timeout, this, [this] {
        if (!m_settleGuard->isActive())
            m_backend->refresh();
    });
    m_poll->start();

    m_backend->refresh();
}

QString AudioService::backendId() const
{
    return m_backend ? m_backend->id() : QStringLiteral("none");
}

QString AudioService::deviceName() const
{
    if (!m_available)
        return QStringLiteral("Không có thiết bị âm thanh");
    return m_deviceName.isEmpty() ? QStringLiteral("Thiết bị mặc định") : m_deviceName;
}

QString AudioService::level() const
{
    if (!m_available || m_muted || m_volume <= 0)
        return QStringLiteral("mute");
    if (m_volume <= 33) return QStringLiteral("low");
    if (m_volume <= 66) return QStringLiteral("medium");
    return QStringLiteral("high");
}

QString AudioService::tooltipText() const
{
    if (!m_available)
        return QStringLiteral("Không tìm thấy dịch vụ âm thanh");
    if (m_muted)
        return QStringLiteral("Âm lượng %1% · đang tắt tiếng").arg(m_volume);
    return QStringLiteral("Âm lượng %1%").arg(m_volume);
}

void AudioService::onBackendState(bool available, int volume, bool muted, const QString &deviceName)
{
    // Trong lúc người dùng đang kéo slider, giữ nguyên giá trị local.
    const int effectiveVolume = m_settleGuard && m_settleGuard->isActive() ? m_volume : volume;

    if (available == m_available && effectiveVolume == m_volume
        && muted == m_muted && deviceName == m_deviceName) {
        return;
    }

    m_available = available;
    m_volume = effectiveVolume;
    m_muted = muted;
    m_deviceName = deviceName;
    emit changed();
}

void AudioService::setVolume(int percent)
{
    if (!m_backend || !m_available)
        return;

    const int clamped = qBound(0, percent, 100);
    if (clamped != m_volume) {
        m_volume = clamped;
        emit changed();
    }

    m_settleGuard->start();
    m_backend->setVolume(clamped);
}

void AudioService::setMuted(bool muted)
{
    if (!m_backend || !m_available)
        return;
    if (m_muted != muted) {
        m_muted = muted;
        emit changed();
    }
    m_settleGuard->start();
    m_backend->setMuted(muted);
}

void AudioService::toggleMute()
{
    if (!m_backend || !m_available)
        return;
    m_muted = !m_muted;
    emit changed();
    m_settleGuard->start();
    m_backend->toggleMuted();
}

void AudioService::refresh()
{
    if (m_backend)
        m_backend->refresh();
}

void AudioService::setActive(bool active)
{
    if (!m_poll)
        return;
    m_poll->setInterval(active ? 1000 : 2500);
    if (active)
        refresh();
}
