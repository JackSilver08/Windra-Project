#include <QGuiApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStringList>

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
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Windra Shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("Windra"));

    const QStringList args = QCoreApplication::arguments();
    const bool windowed = args.contains(QStringLiteral("--windowed"));

    WindraSettings settings;
    ApplicationModel applications(windowed);
    ShellBackend backend(windowed, &applications);
    BatteryService battery;
    PowerProfilesService powerProfiles;
    AudioService audio;
    NetworkService network;
    PopupController popups;

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
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [] { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("Windra.Shell"), QStringLiteral("Main"));
    return app.exec();
}
