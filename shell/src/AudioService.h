#pragma once

#include <QObject>
#include <QString>

class AudioBackend;
class QTimer;

/*!
 * Âm lượng đầu ra của hệ thống.
 *
 * QML chỉ thấy service này; việc nói chuyện với PipeWire nằm trong AudioBackend.
 * Poll nhẹ (2s) để bắt thay đổi volume từ bên ngoài (phím media, mixer khác);
 * sau khi người dùng kéo slider thì tạm ngưng poll để UI không bị giật.
 */
class AudioService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(int volume READ volume NOTIFY changed)
    Q_PROPERTY(bool muted READ muted NOTIFY changed)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY changed)
    Q_PROPERTY(QString level READ level NOTIFY changed)
    Q_PROPERTY(QString tooltipText READ tooltipText NOTIFY changed)
    Q_PROPERTY(QString backendId READ backendId NOTIFY changed)

public:
    explicit AudioService(QObject *parent = nullptr);

    bool available() const { return m_available; }
    int volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    QString deviceName() const;

    //! mute | low | medium | high — dùng để vẽ icon loa.
    QString level() const;
    QString tooltipText() const;
    QString backendId() const;

    Q_INVOKABLE void setVolume(int percent);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void refresh();

    //! Bật/tắt poll — popup mở thì poll nhanh hơn, đóng thì chậm lại.
    Q_INVOKABLE void setActive(bool active);

signals:
    void changed();

private:
    void onBackendState(bool available, int volume, bool muted, const QString &deviceName);

    AudioBackend *m_backend = nullptr;
    QTimer *m_poll = nullptr;
    QTimer *m_settleGuard = nullptr;   //!< bỏ qua poll ngay sau khi người dùng chỉnh
    QString m_deviceName;
    bool m_available = false;
    bool m_muted = false;
    int m_volume = 0;
};
