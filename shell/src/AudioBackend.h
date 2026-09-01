#pragma once

#include <QObject>
#include <QString>

/*!
 * Giao diện backend âm thanh.
 *
 * AudioService chỉ nói chuyện với interface này, nên khi Windra chuyển sang
 * client PipeWire native (libpipewire / WirePlumber API) thì chỉ cần thêm một
 * lớp con mới — không phải sửa AudioService hay QML.
 */
class AudioBackend : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;

    //! wirePlumber-cli | pulse-cli | ... (dùng trong báo cáo/debug)
    virtual QString id() const = 0;

    //! Kiểm tra nhanh xem backend có dùng được trên máy này không.
    virtual bool probe() = 0;

    //! Đọc lại trạng thái; phát stateChanged() khi có kết quả.
    virtual void refresh() = 0;

    virtual void setVolume(int percent) = 0;
    virtual void setMuted(bool muted) = 0;
    virtual void toggleMuted() = 0;

signals:
    void stateChanged(bool available, int volume, bool muted, const QString &deviceName);
};

//! PipeWire / WirePlumber qua `wpctl` — implementation prototype của v0.2.
class WirePlumberCliBackend final : public AudioBackend
{
    Q_OBJECT
public:
    using AudioBackend::AudioBackend;

    QString id() const override { return QStringLiteral("wireplumber-cli"); }
    bool probe() override;
    void refresh() override;
    void setVolume(int percent) override;
    void setMuted(bool muted) override;
    void toggleMuted() override;

private:
    void readDeviceName();
    QString m_deviceName;
};

//! PulseAudio-compatible (`pactl`) — chạy được trên cả PipeWire lẫn PulseAudio.
class PulseCliBackend final : public AudioBackend
{
    Q_OBJECT
public:
    using AudioBackend::AudioBackend;

    QString id() const override { return QStringLiteral("pulse-cli"); }
    bool probe() override;
    void refresh() override;
    void setVolume(int percent) override;
    void setMuted(bool muted) override;
    void toggleMuted() override;

private:
    void readMute(int volume);
    void readDeviceName();
    QString m_deviceName;
};
