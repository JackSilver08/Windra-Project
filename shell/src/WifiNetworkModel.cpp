#include "WifiNetworkModel.h"

WifiNetworkModel::WifiNetworkModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int WifiNetworkModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_view.size();
}

QVariant WifiNetworkModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_view.size())
        return {};

    const WifiNetwork &network = m_view.at(index.row());
    switch (role) {
    case SsidRole: return network.ssid;
    case StrengthRole: return network.strength;
    case SecuredRole: return network.secured;
    case SecurityRole: return network.security;
    case KnownRole: return network.known;
    case ActiveRole: return network.active;
    case BarsRole: return bars(network.strength);
    case PathRole: return network.path;
    default: return {};
    }
}

QHash<int, QByteArray> WifiNetworkModel::roleNames() const
{
    return {
        {SsidRole, "ssid"},
        {StrengthRole, "strength"},
        {SecuredRole, "secured"},
        {SecurityRole, "security"},
        {KnownRole, "known"},
        {ActiveRole, "active"},
        {BarsRole, "bars"},
        {PathRole, "path"},
    };
}

int WifiNetworkModel::bars(int strength)
{
    if (strength >= 75) return 4;
    if (strength >= 50) return 3;
    if (strength >= 25) return 2;
    if (strength > 0) return 1;
    return 0;
}

void WifiNetworkModel::setFilter(const QString &value)
{
    if (m_filter == value)
        return;
    m_filter = value;
    emit filterChanged();
    rebuild();
}

void WifiNetworkModel::setNetworks(const QVector<WifiNetwork> &networks)
{
    if (networks == m_all)
        return;
    m_all = networks;
    rebuild();
}

void WifiNetworkModel::rebuild()
{
    QVector<WifiNetwork> view;
    const QString needle = m_filter.trimmed();
    view.reserve(m_all.size());
    for (const WifiNetwork &network : m_all) {
        // Mạng đang kết nối hiển thị riêng ở phần "Đã kết nối".
        if (network.active)
            continue;
        if (!needle.isEmpty() && !network.ssid.contains(needle, Qt::CaseInsensitive))
            continue;
        view.append(network);
    }

    if (view == m_view)
        return;

    beginResetModel();
    m_view = view;
    endResetModel();
    emit countChanged();
}

WifiNetwork WifiNetworkModel::activeNetwork() const
{
    for (const WifiNetwork &network : m_all) {
        if (network.active)
            return network;
    }
    return {};
}
