#include "WindraSettings.h"

#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QSettings>
#include <QTimer>

namespace {
constexpr auto kOrganization = "Windra";
constexpr auto kApplication = "windra";
constexpr auto kMotionEnabled = "appearance/motionEnabled";
constexpr auto kReduceMotion = "appearance/reduceMotion";
}

WindraSettings::WindraSettings(QObject *parent)
    : QObject(parent)
{
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings probe(QSettings::IniFormat, QSettings::UserScope,
                    QLatin1String(kOrganization), QLatin1String(kApplication));
    m_filePath = probe.fileName();

    reload();
    watchFile();
}

void WindraSettings::reload()
{
    QSettings settings(m_filePath, QSettings::IniFormat);
    const bool motion = settings.value(QLatin1String(kMotionEnabled), true).toBool();
    const bool reduce = settings.value(QLatin1String(kReduceMotion), false).toBool();

    if (motion == m_motionEnabled && reduce == m_reduceMotion)
        return;

    m_motionEnabled = motion;
    m_reduceMotion = reduce;
    emit changed();
}

void WindraSettings::write(const QString &key, bool value)
{
    QDir().mkpath(QFileInfo(m_filePath).absolutePath());
    QSettings settings(m_filePath, QSettings::IniFormat);
    settings.setValue(key, value);
    settings.sync();
    // Ghi lại file có thể làm watcher rụng path trên một số filesystem.
    watchFile();
}

void WindraSettings::watchFile()
{
    if (!m_watcher) {
        m_watcher = new QFileSystemWatcher(this);
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
            // Nhiều editor/QSettings ghi bằng rename; đợi một nhịp rồi đọc lại.
            QTimer::singleShot(60, this, [this] {
                watchFile();
                reload();
            });
        });
        connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] {
            watchFile();
            reload();
        });
    }

    const QString dir = QFileInfo(m_filePath).absolutePath();
    if (QFileInfo::exists(dir) && !m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);
    if (QFileInfo::exists(m_filePath) && !m_watcher->files().contains(m_filePath))
        m_watcher->addPath(m_filePath);
}

void WindraSettings::setMotionEnabled(bool value)
{
    if (m_motionEnabled == value)
        return;
    m_motionEnabled = value;
    write(QLatin1String(kMotionEnabled), value);
    emit changed();
}

void WindraSettings::setReduceMotion(bool value)
{
    if (m_reduceMotion == value)
        return;
    m_reduceMotion = value;
    write(QLatin1String(kReduceMotion), value);
    emit changed();
}
