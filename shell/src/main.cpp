#include <QGuiApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStringList>

#include <cstdio>

#include "ApplicationModel.h"
#include "AudioService.h"
#include "BatteryService.h"
#include "NetworkService.h"
#include "PopupController.h"
#include "PowerProfilesService.h"
#include "ShellBackend.h"
#include "WindraSettings.h"

int main(int argc, char *argv[])
{
    const QStringList args = QCoreApplication::arguments();
    const bool diagnostic = args.contains(QStringLiteral("--startup-diagnostic"));
    const bool windowed = args.contains(QStringLiteral("--windowed"));

    auto mark = [diagnostic](const char *message) {
        if (!diagnostic)
            return;
        std::fprintf(stderr, "[WINDRA-STARTUP] %s\n", message);
        std::fflush(stderr);
    };

    mark("enter main");
    QGuiApplication app(argc, argv);
    mark("QGuiApplication constructed");

    QGuiApplication::setApplicationName(QStringLiteral("Windra Shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("Windra"));

    mark("creating WindraSettings");
    WindraSettings settings;
    mark("WindraSettings OK");

    mark("creating ApplicationModel");
    ApplicationModel applications(windowed);
    mark("ApplicationModel OK");

    mark("creating ShellBackend");
    ShellBackend backend(windowed, &applications);
    mark("ShellBackend OK");

    mark("creating BatteryService");
    BatteryService battery;
    mark("BatteryService OK");

    mark("creating PowerProfilesService");
    PowerProfilesService powerProfiles;
    mark("PowerProfilesService OK");

    mark("creating AudioService");
    AudioService audio;
    mark("AudioService OK");

    mark("creating NetworkService");
    NetworkService network;
    mark("NetworkService OK");

    mark("creating PopupController");
    PopupController popups;
    mark("PopupController OK");

    // In diagnostic mode we intentionally stop before loading QML.
    // This isolates blocking constructor/service initialization from the QML layer.
    if (diagnostic) {
        mark("all startup services OK");
        return 0;
    }

    // Popup mở => service tương ứng cập nhật nhanh hơn; đóng => nghỉ.
    QObject::connect(&popups, &PopupController::opened, &app,
                     [&](const QString &name) {
                         audio.setActive(name == QLatin1String("volume"));
                         network.setActive(name == QLatin1String("wifi"));
                         if (name == QLatin1String("battery")) {
                             battery.refresh();
                             powerProfiles.refresh();
                         }
                     });

    mark("creating QQmlApplicationEngine");
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
    mark("QQmlApplicationEngine OK");

    QObject::connect(&engine,
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [] { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    mark("loading Windra.Shell/Main");
    engine.loadFromModule(QStringLiteral("Windra.Shell"), QStringLiteral("Main"));
    mark("loadFromModule returned");
    return app.exec();
}
