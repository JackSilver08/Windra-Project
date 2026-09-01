#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVariantList>
#include <QVector>

class QTimer;

/*!
 * Registry + model của các ứng dụng **cấp người dùng** mà Windra biết.
 *
 * Cố ý KHÔNG liệt kê process Linux. Người dùng không cần thấy systemd,
 * dbus-daemon hay pipewire. Model chỉ chứa app được Windra launch qua dock,
 * launcher, Windra Web Apps hoặc Windra native apps.
 *
 * v0.2 chưa có protocol window management (KWin/wlroots foreign-toplevel), nên
 * `windows` chỉ được điền khi thật sự xác định được; `activate()` báo rõ là
 * chưa focus được thay vì giả vờ thành công.
 */
class ApplicationModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QVariantList running READ running NOTIFY appsChanged)
    Q_PROPERTY(QVariantList background READ background NOTIFY appsChanged)
    Q_PROPERTY(int runningCount READ runningCount NOTIFY appsChanged)

public:
    enum Role {
        AppIdRole = Qt::UserRole + 1,
        NameRole,
        IconNameRole,
        PidRole,
        ExecutableRole,
        StateRole,
        BackgroundRole,
        WindowsRole,
        TrackedRole,
    };

    struct Entry {
        QString appId;
        QString name;
        QString iconName;
        QString executable;
        QString state = QStringLiteral("running"); //!< foreground | running | background
        qint64 pid = 0;
        int windows = 0;
        bool background = false;
        bool tracked = false;   //!< Windra biết PID và theo dõi được vòng đời
        bool closing = false;   //!< đã gửi SIGTERM, chờ thoát
    };

    explicit ApplicationModel(bool previewMode, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QVariantList running() const;
    QVariantList background() const;
    int runningCount() const { return m_entries.size(); }

    //! Danh mục app Windra biết (native + web). Dùng cho launcher và dock.
    Q_INVOKABLE QVariantList catalog() const;

    Q_INVOKABLE bool launch(const QString &appId);
    Q_INVOKABLE bool isRunning(const QString &appId) const;
    Q_INVOKABLE void activate(const QString &appId);
    Q_INVOKABLE void requestClose(const QString &appId);
    Q_INVOKABLE void forceClose(const QString &appId);

    //! Bỏ khỏi danh sách một entry không theo dõi được (trình duyệt ngoài).
    Q_INVOKABLE void forget(const QString &appId);

signals:
    void appsChanged();
    void notification(const QString &message);

private:
    struct CatalogItem {
        QString appId;
        QString name;
        QString iconName;
        QString binary;    //!< tên nhị phân trong build tree / PATH
        bool background = false;
    };

    static QVector<CatalogItem> catalogItems();
    const CatalogItem *catalogItem(const QString &appId) const;

    QString resolveExecutable(const CatalogItem &item) const;
    static QString resolveBrowser();

    bool launchWeb(const CatalogItem &item);
    bool launchNative(const CatalogItem &item);

    void addEntry(const Entry &entry);
    int indexOf(const QString &appId) const;
    void removeAt(int row);
    void pollProcesses();
    static bool processAlive(qint64 pid);

    QVector<Entry> m_entries;
    QTimer *m_poll = nullptr;
    bool m_previewMode = true;
};
