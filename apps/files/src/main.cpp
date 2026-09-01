#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "DirectoryModel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Windra Files"));
    DirectoryModel model;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("directoryModel"), &model);
    engine.loadFromModule(QStringLiteral("Windra.Files"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}
