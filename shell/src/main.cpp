#include <QCoreApplication>
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
    // Detect this mode without touching QCoreApplication::arguments().
    // This allows the diagnostic path to run without constructing QGuiApplication,
    // which may initialize the WSL graphics stack before we can print a marker.
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

    QGuiApplication::setApplicationName(QStringLiteral("Windra Shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("Windra"));

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
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [] { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("Windra.Shell"), QStringLiteral("Main"));
    return app.exec();
}
