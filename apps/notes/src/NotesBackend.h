#pragma once
#include <QObject>
#include <QUrl>
class NotesBackend final : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE QString load(const QUrl &url);
    Q_INVOKABLE bool save(const QUrl &url, const QString &text);
};
