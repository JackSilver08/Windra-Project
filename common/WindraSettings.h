#pragma once

#include <QObject>
#include <QString>

class QFileSystemWatcher;

/*!
 * Cài đặt dùng chung giữa Windra Shell và Windra Settings.
 *
 * Lưu tại ~/.config/Windra/windra.ini (INI). Shell theo dõi file bằng
 * QFileSystemWatcher nên thay đổi từ Windra Settings có hiệu lực ngay,
 * không cần khởi động lại shell và không cần thêm một daemon riêng.
 */
class WindraSettings final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool motionEnabled READ motionEnabled WRITE setMotionEnabled NOTIFY changed)
    Q_PROPERTY(bool reduceMotion READ reduceMotion WRITE setReduceMotion NOTIFY changed)
    Q_PROPERTY(bool effectiveReduceMotion READ effectiveReduceMotion NOTIFY changed)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)

public:
    explicit WindraSettings(QObject *parent = nullptr);

    bool motionEnabled() const { return m_motionEnabled; }
    bool reduceMotion() const { return m_reduceMotion; }

    //! Reduce Motion có hiệu lực khi người dùng bật nó hoặc tắt hẳn chuyển động.
    bool effectiveReduceMotion() const { return m_reduceMotion || !m_motionEnabled; }

    QString filePath() const { return m_filePath; }

    void setMotionEnabled(bool value);
    void setReduceMotion(bool value);

signals:
    void changed();

private:
    void reload();
    void write(const QString &key, bool value);
    void watchFile();

    QString m_filePath;
    QFileSystemWatcher *m_watcher = nullptr;
    bool m_motionEnabled = true;
    bool m_reduceMotion = false;
};
