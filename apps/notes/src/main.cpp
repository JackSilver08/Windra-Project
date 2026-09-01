#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "NotesBackend.h"
int main(int argc, char *argv[]) { QGuiApplication app(argc, argv); NotesBackend backend; QQmlApplicationEngine engine; engine.rootContext()->setContextProperty(QStringLiteral("notesBackend"), &backend); engine.loadFromModule(QStringLiteral("Windra.Notes"), QStringLiteral("Main")); if (engine.rootObjects().isEmpty()) return -1; return app.exec(); }
