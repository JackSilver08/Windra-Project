#pragma once

#include <QObject>
#include <QString>

class ApplicationModel;

/*!
 * Backend chung của shell: launch app (uỷ quyền cho ApplicationModel),
 * web search và power action. Trạng thái phần cứng nằm ở các service riêng
 * (BatteryService, AudioService, NetworkService).
 */
class ShellBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool previewMode READ previewMode CONSTANT)

public:
    ShellBackend(bool previewMode, ApplicationModel *applications, QObject *parent = nullptr);

    bool previewMode() const { return m_previewMode; }

    Q_INVOKABLE bool launchApp(const QString &appId);
    Q_INVOKABLE void openWebHome();
    Q_INVOKABLE void webSearch(const QString &query);
    Q_INVOKABLE void powerAction(const QString &action);

signals:
    void notification(const QString &message);

private:
    ApplicationModel *m_applications = nullptr;
    bool m_previewMode = true;
};
