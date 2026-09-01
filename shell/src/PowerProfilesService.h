#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

/*!
 * Chế độ nguồn qua power-profiles-daemon (D-Bus system bus).
 *
 * Hỗ trợ cả tên service mới (org.freedesktop.UPower.PowerProfiles) và tên cũ
 * (net.hadess.PowerProfiles). Nếu daemon không có, `available` = false và UI
 * hiển thị các nút ở trạng thái disabled thay vì giả vờ đổi được chế độ.
 */
class PowerProfilesService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(QString activeProfile READ activeProfile NOTIFY changed)
    Q_PROPERTY(QStringList profiles READ profiles NOTIFY changed)
    Q_PROPERTY(QString activeProfileText READ activeProfileText NOTIFY changed)

public:
    explicit PowerProfilesService(QObject *parent = nullptr);

    bool available() const { return m_available; }
    QString activeProfile() const { return m_activeProfile; }
    QStringList profiles() const { return m_profiles; }
    QString activeProfileText() const;

    Q_INVOKABLE bool hasProfile(const QString &profile) const;
    Q_INVOKABLE void setProfile(const QString &profile);
    Q_INVOKABLE void refresh();

    //! power-saver -> "Tiết kiệm", balanced -> "Cân bằng", performance -> "Hiệu năng"
    Q_INVOKABLE static QString displayName(const QString &profile);

signals:
    void changed();

private slots:
    void onPropertiesChanged(const QString &interfaceName,
                             const QVariantMap &changed,
                             const QStringList &invalidated);

private:
    bool probe(const QString &service, const QString &path, const QString &iface);

    QString m_service;
    QString m_path;
    QString m_interface;
    QString m_activeProfile;
    QStringList m_profiles;
    bool m_available = false;
};
