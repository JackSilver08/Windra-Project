#include <QCoreApplication>
#include <QGuiApplication>
#include <QImage>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStringList>
#include <QQuickWindow>
#include <QTimer>

#include <cstdio>

#include "ApplicationModel.h"
#include "AudioService.h"
#include "BatteryService.h"
#include "NetworkService.h"
#include "PopupController.h"
#include "PowerProfilesService.h"
#include "ShellBackend.h"
#include "WindraSettings.h"

namespace {

bool hasArgument(int argc, char *argv[], const char *wanted)
{
    for (int i = 1; i < argc; ++i) {
        if (QString::fromLocal8Bit(argv[i]) == QLatin1String(wanted))
            return true;
    }
    return false;
}

void printMark(const char *message)
{
    std::fprintf(stderr, "[WINDRA-STARTUP] %s\n", message);
    std::fflush(stderr);
}

} // namespace

int main(int argc, char *argv[])
{
    const bool diagnostic = hasArgument(argc, argv, "--startup-diagnostic");

    if (diagnostic) {
        printMark("enter diagnostic mode");
        QCoreApplication app(argc, argv);
        printMark("QCoreApplication constructed");

        const bool windowed = hasArgument(argc, argv, "--windowed");

        printMark("creating WindraSettings");
        WindraSettings settings;
        printMark("WindraSettings OK");

        printMark("creating ApplicationModel");
        ApplicationModel applications(windowed);
        printMark("ApplicationModel OK");

        printMark("creating ShellBackend");
        ShellBackend backend(windowed, &applications);
        printMark("ShellBackend OK");

        printMark("creating BatteryService");
        BatteryService battery;
        printMark("BatteryService OK");

        printMark("creating PowerProfilesService");
        PowerProfilesService powerProfiles;
        printMark("PowerProfilesService OK");

        printMark("creating AudioService");
        AudioService audio;
        printMark("AudioService OK");

        printMark("creating NetworkService");
        NetworkService network;
        printMark("NetworkService OK");

        printMark("creating PopupController");
        PopupController popups;
        printMark("PopupController OK");

        printMark("all startup services OK");
        return 0;
    }

    QGuiApplication app(argc, argv);
    const QStringList args = QCoreApplication::arguments();
    const bool windowed = args.contains(QStringLiteral("--windowed"));
    const bool guiDiagnostic = args.contains(QStringLiteral("--gui-diagnostic"));
    const bool qmlDiagnostic = args.contains(QStringLiteral("--qml-diagnostic"));

    QGuiApplication::setApplicationName(QStringLiteral("Windra Shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("Windra"));

    if (guiDiagnostic) {
        std::fprintf(stderr, "[WINDRA-GUI] QGuiApplication constructed\n");
        std::fflush(stderr);

        QQuickWindow window;
        window.setTitle(QStringLiteral("Windra GUI Diagnostic"));
        window.resize(640, 360);

        QObject::connect(&window, &QQuickWindow::sceneGraphInitialized, &app, [&window] {
            const auto api = window.rendererInterface()->graphicsApi();
            std::fprintf(stderr, "[WINDRA-GUI] Scene graph initialized, API=%d\n",
                         static_cast<int>(api));
            std::fflush(stderr);
        });

        QObject::connect(&window, &QQuickWindow::sceneGraphError, &app,
                         [](QQuickWindow::SceneGraphError error, const QString &message) {
                             std::fprintf(stderr, "[WINDRA-GUI] Scene graph ERROR=%d: %s\n",
                                          static_cast<int>(error),
                                          message.toLocal8Bit().constData());
                             std::fflush(stderr);
                         });

        window.show();
        QTimer::singleShot(1500, &app, [&app] {
            std::fprintf(stderr, "[WINDRA-GUI] timer fired, GUI initialization survived\n");
            std::fflush(stderr);
            app.quit();
        });

        return app.exec();
    }

    WindraSettings settings;
    ApplicationModel applications(windowed);
    ShellBackend backend(windowed, &applications);
    BatteryService battery;
    PowerProfilesService powerProfiles;
    AudioService audio;
    NetworkService network;
    PopupController popups;

    QObject::connect(&popups, &PopupController::opened, &app,
                     [&](const QString &name) {
                         audio.setActive(name == QLatin1String("volume"));
                         network.setActive(name == QLatin1String("wifi"));
                         if (name == QLatin1String("battery")) {
                             battery.refresh();
                             powerProfiles.refresh();
                         }
                     });

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();
    context->setContextProperty(QStringLiteral("windraDevWindowed"), windowed);
    context->setContextProperty(QStringLiteral("windraSettings"), &settings);
    context->setContextProperty(QStringLiteral("shellBackend"), &backend);
    context->setContextProperty(QStringLiteral("appModel"), &applications);
    context->setContextProperty(QStringLiteral("batteryService"), &battery);
    context->setContextProperty(QStringLiteral("powerProfiles"), &powerProfiles);
    context->setContextProperty(QStringLiteral("audioService"), &audio);
    context->setContextProperty(QStringLiteral("networkService"), &network);
    context->setContextProperty(QStringLiteral("popupController"), &popups);
    context->setContextProperty(QStringLiteral("windraLocaleName"), QLocale::system().name());

    QObject::connect(&engine,
                     &QQmlApplicationEngine::warnings,
                     &app,
                     [](const QList<QQmlError> &warnings) {
                         for (const QQmlError &error : warnings) {
                             std::fprintf(stderr, "[WINDRA-QML] %s\n",
                                          error.toString().toLocal8Bit().constData());
                         }
                         std::fflush(stderr);
                     });

    QObject::connect(&engine,
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [] { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    if (qmlDiagnostic) {
        std::fprintf(stderr, "[WINDRA-QML] QGuiApplication and services initialized\n");
        std::fflush(stderr);
        std::fprintf(stderr, "[WINDRA-QML] loading Windra.Shell/Main\n");
        std::fflush(stderr);
        engine.loadFromModule(QStringLiteral("Windra.Shell"), QStringLiteral("Main"));

        const auto roots = engine.rootObjects();
        std::fprintf(stderr, "[WINDRA-QML] loadFromModule returned, rootObjects=%lld\n",
                     static_cast<long long>(roots.size()));
        std::fflush(stderr);

        QQuickWindow *mainWindow = nullptr;
        for (QObject *object : roots) {
            if (auto *candidate = qobject_cast<QQuickWindow *>(object)) {
                mainWindow = candidate;
                break;
            }
        }

        if (!mainWindow) {
            std::fprintf(stderr, "[WINDRA-QML] no QQuickWindow root object found\n");
            std::fflush(stderr);
            QCoreApplication::exit(2);
            return app.exec();
        }

        std::fprintf(stderr,
                     "[WINDRA-QML] window initial: visible=%d active=%d minimized=%d exposed=%d size=%dx%d\n",
                     mainWindow->isVisible() ? 1 : 0,
                     mainWindow->isActive() ? 1 : 0,
                     mainWindow->visibility() == QWindow::Minimized ? 1 : 0,
                     mainWindow->isExposed() ? 1 : 0,
                     mainWindow->width(),
                     mainWindow->height());
        std::fflush(stderr);

        QTimer::singleShot(1500, &app, [mainWindow] {
            std::fprintf(stderr,
                         "[WINDRA-QML] after 1.5s: visible=%d active=%d minimized=%d exposed=%d size=%dx%d\n",
                         mainWindow->isVisible() ? 1 : 0,
                         mainWindow->isActive() ? 1 : 0,
                         mainWindow->visibility() == QWindow::Minimized ? 1 : 0,
                         mainWindow->isExposed() ? 1 : 0,
                         mainWindow->width(),
                         mainWindow->height());
            std::fflush(stderr);

            const QImage image = mainWindow->grabWindow();
            if (image.isNull()) {
                std::fprintf(stderr, "[WINDRA-QML] grabWindow FAILED (null image)\n");
                std::fflush(stderr);
                QCoreApplication::exit(3);
                return;
            }

            const QString output = QStringLiteral("/tmp/windra-main-diagnostic.png");
            if (!image.save(output)) {
                std::fprintf(stderr, "[WINDRA-QML] grabWindow OK but save FAILED: %s\n",
                             output.toLocal8Bit().constData());
                std::fflush(stderr);
                QCoreApplication::exit(4);
                return;
            }

            std::fprintf(stderr, "[WINDRA-QML] grabWindow OK: %dx%d\n",
                         image.width(), image.height());
            std::fprintf(stderr, "[WINDRA-QML] screenshot: %s\n",
                         output.toLocal8Bit().constData());
            std::fflush(stderr);
            app.quit();
        });

        return app.exec();
    }

    engine.loadFromModule(QStringLiteral("Windra.Shell"), QStringLiteral("Main"));
    return app.exec();
}
