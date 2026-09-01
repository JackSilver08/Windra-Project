#pragma once

#include "NetworkBackend.h"

#include <QAbstractListModel>
#include <QVector>

/*!
 * Danh sách Wi-Fi cho QML.
 *
 * Giữ danh sách đầy đủ và một view đã lọc theo `filter` (ô "Tìm mạng...").
 * Lọc nằm ở model chứ không ở QML để delegate không phải dựng rồi ẩn đi.
 */
class WifiNetworkModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)

public:
    enum Role {
        SsidRole = Qt::UserRole + 1,
        StrengthRole,
        SecuredRole,
        SecurityRole,
        KnownRole,
        ActiveRole,
        BarsRole,
        PathRole,
    };

    explicit WifiNetworkModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const { return m_all.size(); }
    QString filter() const { return m_filter; }
    void setFilter(const QString &value);

    void setNetworks(const QVector<WifiNetwork> &networks);

    //! Mạng đang kết nối (rỗng nếu không có).
    WifiNetwork activeNetwork() const;

signals:
    void filterChanged();
    void countChanged();

private:
    void rebuild();
    static int bars(int strength);

    QVector<WifiNetwork> m_all;
    QVector<WifiNetwork> m_view;
    QString m_filter;
};
