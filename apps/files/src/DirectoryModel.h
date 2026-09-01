#pragma once

#include <QAbstractListModel>
#include <QFileInfoList>

class DirectoryModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentPathChanged)
    Q_PROPERTY(QString homePath READ homePath CONSTANT)

public:
    enum Roles { NameRole = Qt::UserRole + 1, PathRole, IsDirRole, SizeRole };
    explicit DirectoryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString currentPath() const;
    QString homePath() const;

    Q_INVOKABLE void goTo(const QString &path);
    Q_INVOKABLE void goHome();
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void openIndex(int row);

signals:
    void currentPathChanged();

private:
    void load(const QString &path);
    QFileInfoList m_entries;
    QString m_currentPath;
};
