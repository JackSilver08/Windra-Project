#include "DirectoryModel.h"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUrl>

DirectoryModel::DirectoryModel(QObject *parent) : QAbstractListModel(parent)
{
    load(QDir::homePath());
}

int DirectoryModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant DirectoryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};
    const QFileInfo &info = m_entries.at(index.row());
    switch (role) {
    case NameRole: return info.fileName();
    case PathRole: return info.absoluteFilePath();
    case IsDirRole: return info.isDir();
    case SizeRole: return info.isDir() ? QStringLiteral("Thư mục") : QString::number(info.size() / 1024.0 / 1024.0, 'f', 1) + QStringLiteral(" MB");
    default: return {};
    }
}

QHash<int, QByteArray> DirectoryModel::roleNames() const
{
    return {{NameRole,"name"},{PathRole,"path"},{IsDirRole,"isDir"},{SizeRole,"sizeText"}};
}

QString DirectoryModel::currentPath() const { return m_currentPath; }
QString DirectoryModel::homePath() const { return QDir::homePath(); }

void DirectoryModel::load(const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) return;
    beginResetModel();
    m_currentPath = dir.absolutePath();
    m_entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot,
                                  QDir::DirsFirst | QDir::IgnoreCase | QDir::Name);
    endResetModel();
    emit currentPathChanged();
}

void DirectoryModel::goTo(const QString &path) { load(path); }
void DirectoryModel::goHome() { load(QDir::homePath()); }
void DirectoryModel::goUp() { QDir dir(m_currentPath); if (dir.cdUp()) load(dir.absolutePath()); }
void DirectoryModel::refresh() { load(m_currentPath); }

void DirectoryModel::openIndex(int row)
{
    if (row < 0 || row >= m_entries.size()) return;
    const QFileInfo info = m_entries.at(row);
    if (info.isDir()) load(info.absoluteFilePath());
    else QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
}
