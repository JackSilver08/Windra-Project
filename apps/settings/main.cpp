#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "WindraSettings.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Windra Settings"));
    QGuiApplication::setOrganizationName(QStringLiteral("Windra"));

    // Cùng file cấu hình mà Windra Shell đang theo dõi, nên Reduce Motion có
    // hiệu lực ngay trên desktop khi người dùng gạt công tắc ở đây.
    WindraSettings settings;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("windraSettings"), &settings);
    engine.loadFromModule(QStringLiteral("Windra.Settings"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}
