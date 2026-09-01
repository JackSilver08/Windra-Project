#include "ShellBackend.h"

#include "ApplicationModel.h"

#include <QDesktopServices>
#include <QHash>
#include <QProcess>
#include <QUrl>

ShellBackend::ShellBackend(bool previewMode, ApplicationModel *applications, QObject *parent)
    : QObject(parent), m_applications(applications), m_previewMode(previewMode)
{
    if (m_applications) {
        connect(m_applications, &ApplicationModel::notification,
                this, &ShellBackend::notification);
    }
}

bool ShellBackend::launchApp(const QString &appId)
{
    if (!m_applications)
        return false;
    return m_applications->launch(appId);
}

void ShellBackend::openWebHome()
{
    launchApp(QStringLiteral("web"));
}

void ShellBackend::webSearch(const QString &query)
{
    const QByteArray encoded = QUrl::toPercentEncoding(query);
    QDesktopServices::openUrl(
        QUrl(QStringLiteral("https://www.google.com/search?q=") + QString::fromUtf8(encoded)));
    emit notification(QStringLiteral("Đang tìm trên web: %1").arg(query));
}

void ShellBackend::powerAction(const QString &action)
{
    const QHash<QString, QString> labels {
        {QStringLiteral("suspend"), QStringLiteral("Ngủ")},
        {QStringLiteral("reboot"), QStringLiteral("Khởi động lại")},
        {QStringLiteral("poweroff"), QStringLiteral("Tắt máy")},
        {QStringLiteral("logout"), QStringLiteral("Đăng xuất")},
    };

    if (m_previewMode) {
        emit notification(QStringLiteral("Preview an toàn: %1").arg(labels.value(action, action)));
        return;
    }

    if (action == QStringLiteral("logout")) {
        emit notification(
            QStringLiteral("Đăng xuất sẽ được nối với systemd-logind ở mốc System Alpha."));
        return;
    }

    if (action == QStringLiteral("suspend") || action == QStringLiteral("reboot")
        || action == QStringLiteral("poweroff")) {
        QProcess::startDetached(QStringLiteral("systemctl"), {action});
        return;
    }

    emit notification(QStringLiteral("Hành động nguồn không hợp lệ"));
}
