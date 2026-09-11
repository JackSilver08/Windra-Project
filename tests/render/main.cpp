#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QImage>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QTimer>
#include <QDebug>

namespace {
QString graphicsApiName(QSGRendererInterface::GraphicsApi api)
{
    switch (api) {
    case QSGRendererInterface::Unknown: return QStringLiteral("Unknown");
    case QSGRendererInterface::Software: return QStringLiteral("Software");
    case QSGRendererInterface::OpenVG: return QStringLiteral("OpenVG");
    case QSGRendererInterface::OpenGL: return QStringLiteral("OpenGL");
    case QSGRendererInterface::Direct3D11: return QStringLiteral("Direct3D 11");
    case QSGRendererInterface::Direct3D12: return QStringLiteral("Direct3D 12");
    case QSGRendererInterface::Vulkan: return QStringLiteral("Vulkan");
    case QSGRendererInterface::Metal: return QStringLiteral("Metal");
    default: return QStringLiteral("Other");
    }
}
}

int main(int argc, char *argv[])
{
    const QStringList args = QCoreApplication::arguments();
    const bool software = args.contains(QStringLiteral("--software"));

    if (software) {
        qputenv("QT_QUICK_BACKEND", QByteArrayLiteral("software"));
    }

    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Windra Render Test"));

    qInfo().noquote() << "=== Windra Render Test ===";
    qInfo().noquote() << "Mode:" << (software ? "software" : "default");
    qInfo().noquote() << "QT_QPA_PLATFORM:" << qEnvironmentVariable("QT_QPA_PLATFORM");
    qInfo().noquote() << "QT_QUICK_BACKEND:" << qEnvironmentVariable("QT_QUICK_BACKEND");
    qInfo().noquote() << "DISPLAY:" << qEnvironmentVariable("DISPLAY");
    qInfo().noquote() << "WAYLAND_DISPLAY:" << qEnvironmentVariable("WAYLAND_DISPLAY");
    qInfo().noquote() << "XDG_RUNTIME_DIR:" << qEnvironmentVariable("XDG_RUNTIME_DIR");
    qInfo().noquote() << "/dev/dxg exists:" << QDir(QStringLiteral("/dev/dxg")).exists();

    QQuickWindow window;
    window.setTitle(QStringLiteral("Windra Render Test"));
    window.resize(640, 360);

    QQuickItem *probe = new QQuickItem(window.contentItem());
    probe->setWidth(640);
    probe->setHeight(360);

    QObject::connect(&window, &QQuickWindow::sceneGraphInitialized, &app, [&window] {
        const auto api = window.rendererInterface()->graphicsApi();
        qInfo().noquote() << "Scene graph initialized.";
        qInfo().noquote() << "Graphics API:" << graphicsApiName(api);
        qInfo().noquote() << "Renderer interface:" << window.rendererInterface();
    });

    QObject::connect(&window, &QQuickWindow::sceneGraphError, &app,
                     [](QQuickWindow::SceneGraphError error, const QString &message) {
                         qCritical().noquote() << "Scene graph ERROR:" << error << message;
                     });

    window.show();

    QTimer::singleShot(1200, &app, [&window, &app] {
        const QImage image = window.grabWindow();
        if (image.isNull()) {
            qCritical() << "RENDER FAIL: grabWindow() returned a null image.";
            QCoreApplication::exit(2);
            return;
        }

        const QString output = QDir::temp().filePath(QStringLiteral("windra-render-test.png"));
        if (!image.save(output)) {
            qCritical().noquote() << "RENDER FAIL: could not save" << output;
            QCoreApplication::exit(3);
            return;
        }

        qInfo().noquote() << "RENDER OK:" << image.width() << "x" << image.height();
        qInfo().noquote() << "Screenshot:" << output;
        QCoreApplication::exit(0);
    });

    return app.exec();
}
