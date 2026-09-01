#pragma once

#include <QObject>
#include <QString>

class QTimer;

/*!
 * Trạng thái pin thật của máy.
 *
 * Nguồn dữ liệu theo thứ tự ưu tiên:
 *   1. UPower qua D-Bus system bus (org.freedesktop.UPower, DisplayDevice)
 *      — có push update qua PropertiesChanged nên gần như realtime.
 *   2. /sys/class/power_supply/BAT* — fallback khi không có UPower daemon.
 *   3. Không có pin  ->  available = false (máy bàn / VM).
 *
 * Không có giá trị giả ở bất kỳ nhánh nào: nếu không đọc được thì báo
 * unavailable để UI hiển thị đúng sự thật.
 */
class BatteryService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(int percent READ percent NOTIFY changed)
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(bool charging READ charging NOTIFY changed)
    Q_PROPERTY(QString level READ level NOTIFY changed)
    Q_PROPERTY(QString stateText READ stateText NOTIFY changed)
    Q_PROPERTY(QString remainingText READ remainingText NOTIFY changed)
    Q_PROPERTY(QString tooltipText READ tooltipText NOTIFY changed)
    Q_PROPERTY(QString source READ source NOTIFY changed)

public:
    explicit BatteryService(QObject *parent = nullptr);

    bool available() const { return m_available; }
    int percent() const { return m_percent; }

    //! charging | discharging | full | empty | pending | unknown
    QString state() const { return m_state; }
    bool charging() const;

    //! critical | low | medium | high | veryhigh | full  (dùng để vẽ icon)
    QString level() const;

    QString stateText() const;
    QString remainingText() const;
    QString tooltipText() const;

    //! upower | sysfs | none — hiển thị trong docs/debug, không dùng cho UI logic.
    QString source() const { return m_source; }

    Q_INVOKABLE void refresh();

signals:
    void changed();

private:
    bool setupUPower();
    void setupSysfs();
    void readUPower();
    void readSysfs();
    void apply(bool available, int percent, const QString &state, qint64 secondsLeft);

    QString m_source = QStringLiteral("none");
    QString m_state = QStringLiteral("unknown");
    QString m_devicePath;   //!< UPower object path
    QString m_sysfsPath;    //!< /sys/class/power_supply/BATx
    bool m_available = false;
    int m_percent = -1;
    qint64 m_secondsLeft = 0;
    QTimer *m_poll = nullptr;

private slots:
    void onUPowerPropertiesChanged(const QString &interfaceName,
                                   const QVariantMap &changed,
                                   const QStringList &invalidated);
};
