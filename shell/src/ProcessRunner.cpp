#include "ProcessRunner.h"

#include <QPointer>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>

QString ProcessRunner::which(const QString &program)
{
    return QStandardPaths::findExecutable(program);
}

void ProcessRunner::run(QObject *context,
                        const QString &program,
                        const QStringList &arguments,
                        Callback callback,
                        int timeoutMs)
{
    if (!context) {
        return;
    }

    const QString absolute = which(program);
    if (absolute.isEmpty()) {
        Result result;
        result.stdErr = QStringLiteral("not-found");
        if (callback)
            QTimer::singleShot(0, context, [callback, result] { callback(result); });
        return;
    }

    auto *process = new QProcess(context);
    process->setProgram(absolute);
    process->setArguments(arguments);
    process->setProcessChannelMode(QProcess::SeparateChannels);

    auto *guard = new QTimer(process);
    guard->setSingleShot(true);
    guard->setInterval(timeoutMs);

    QPointer<QObject> contextGuard(context);
    auto finish = [process, callback, contextGuard](bool timedOut) {
        Result result;
        result.stdOut = QString::fromUtf8(process->readAllStandardOutput());
        result.stdErr = QString::fromUtf8(process->readAllStandardError());
        result.exitCode = timedOut ? -1 : process->exitCode();
        result.ok = !timedOut
            && process->exitStatus() == QProcess::NormalExit
            && process->exitCode() == 0;
        if (timedOut)
            result.stdErr = QStringLiteral("timeout");

        process->deleteLater();
        if (callback && contextGuard)
            callback(result);
    };

    QObject::connect(guard, &QTimer::timeout, process, [process, finish] {
        process->kill();
        process->waitForFinished(200);
        finish(true);
    });

    QObject::connect(process,
                     QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                     process,
                     [guard, finish](int, QProcess::ExitStatus) {
                         if (!guard->isActive())
                             return; // đã timeout, finish() chạy rồi
                         guard->stop();
                         finish(false);
                     });

    QObject::connect(process, &QProcess::errorOccurred, process,
                     [guard, finish](QProcess::ProcessError error) {
                         if (error != QProcess::FailedToStart)
                             return;
                         if (!guard->isActive())
                             return;
                         guard->stop();
                         finish(false);
                     });

    /*
     * Shell thoát trong lúc còn lệnh đang chạy (rất dễ xảy ra vì AudioService
     * poll mỗi 1-2.5s). QProcess là con của `context`, nên nó sẽ bị huỷ khi
     * context bị huỷ — và ~QProcess in cảnh báo rồi chặn shutdown để chờ
     * process chết. Dọn trước ở destroyed(), lúc này con vẫn còn sống.
     */
    QObject::connect(context, &QObject::destroyed, process, [process] {
        if (process->state() == QProcess::NotRunning)
            return;
        process->kill();
        process->waitForFinished(100);
    });

    guard->start();
    process->start();
}

void ProcessRunner::runDetachedResult(QObject *context,
                                      const QString &program,
                                      const QStringList &arguments,
                                      int timeoutMs)
{
    run(context, program, arguments, nullptr, timeoutMs);
}
