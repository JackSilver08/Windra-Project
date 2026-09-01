#include "ApplicationModel.h"

#include "ProcessRunner.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

#ifdef Q_OS_UNIX
#include <cerrno>
#include <csignal>
#endif

namespace {
constexpr auto kWebHome = "https://www.google.com";
}

ApplicationModel::ApplicationModel(bool previewMode, QObject *parent)
    : QAbstractListModel(parent), m_previewMode(previewMode)
{
    m_poll = new QTimer(this);
    m_poll->setInterval(2000);
    connect(m_poll, &QTimer::timeout, this, &ApplicationModel::pollProcesses);
    m_poll->start();
}

// ------------------------------------------------------------- catalog ------

QVector<ApplicationModel::CatalogItem> ApplicationModel::catalogItems()
{
    return {
        {QStringLiteral("web"),      QStringLiteral("Windra Web"),      QStringLiteral("web"),      QStringLiteral("web"),             true},
        {QStringLiteral("files"),    QStringLiteral("Windra Files"),    QStringLiteral("folder"),   QStringLiteral("windra-files"),    false},
        {QStringLiteral("notes"),    QStringLiteral("Windra Notes"),    QStringLiteral("notes"),    QStringLiteral("windra-notes"),    false},
        {QStringLiteral("calc"),     QStringLiteral("Windra Calc"),     QStringLiteral("calc"),     QStringLiteral("windra-calc"),     false},
        {QStringLiteral("settings"), QStringLiteral("Windra Settings"), QStringLiteral("settings"), QStringLiteral("windra-settings"), false},
        {QStringLiteral("terminal"), QStringLiteral("Terminal"),        QStringLiteral("terminal"), QStringLiteral("foot"),            false},
    };
}

const ApplicationModel::CatalogItem *ApplicationModel::catalogItem(const QString &appId) const
{
    static const QVector<CatalogItem> items = catalogItems();
    for (const CatalogItem &item : items) {
        if (item.appId == appId)
            return &item;
    }
    return nullptr;
}

QVariantList ApplicationModel::catalog() const
{
    QVariantList list;
    const QVector<CatalogItem> items = catalogItems();
    for (const CatalogItem &item : items) {
        QVariantMap map;
        map.insert(QStringLiteral("appId"), item.appId);
        map.insert(QStringLiteral("name"), item.name);
        map.insert(QStringLiteral("iconName"), item.iconName);
        list.append(map);
    }
    return list;
}

/*!
 * Tìm nhị phân của app: build tree trước (dev), rồi PATH / prefix cài đặt.
 */
QString ApplicationModel::resolveExecutable(const CatalogItem &item) const
{
    static const QHash<QString, QString> buildPaths {
        {QStringLiteral("files"), QStringLiteral("apps/files/windra-files")},
        {QStringLiteral("settings"), QStringLiteral("apps/settings/windra-settings")},
        {QStringLiteral("calc"), QStringLiteral("apps/calc/windra-calc")},
        {QStringLiteral("notes"), QStringLiteral("apps/notes/windra-notes")},
    };

    const QString relative = buildPaths.value(item.appId);
    if (!relative.isEmpty()) {
        QDir buildRoot(QCoreApplication::applicationDirPath());
        buildRoot.cdUp(); // build/shell -> build
        const QString candidate = buildRoot.filePath(relative);
        if (QFileInfo::exists(candidate))
            return candidate;
    }

    // Bản đã cài đặt.
    const QString inPath = ProcessRunner::which(item.binary);
    if (!inPath.isEmpty())
        return inPath;

    const QString sibling = QDir(QCoreApplication::applicationDirPath()).filePath(item.binary);
    if (QFileInfo::exists(sibling))
        return sibling;

    return {};
}

QString ApplicationModel::resolveBrowser()
{
    // x-www-browser là alternative của Debian và trỏ thẳng vào nhị phân thật,
    // nên spawn nó vẫn cho ra PID theo dõi được (khác với xdg-open).
    static const QStringList candidates {
        QStringLiteral("x-www-browser"),
        QStringLiteral("chromium"),
        QStringLiteral("chromium-browser"),
        QStringLiteral("google-chrome"),
        QStringLiteral("firefox"),
    };
    for (const QString &candidate : candidates) {
        const QString path = ProcessRunner::which(candidate);
        if (!path.isEmpty())
            return path;
    }
    return {};
}

// -------------------------------------------------------------- launch ------

bool ApplicationModel::launch(const QString &appId)
{
    const CatalogItem *item = catalogItem(appId);
    if (!item) {
        emit notification(QStringLiteral("Không biết ứng dụng: %1").arg(appId));
        return false;
    }

    const int existing = indexOf(appId);
    if (existing >= 0 && m_entries.at(existing).tracked) {
        activate(appId);
        return true;
    }

    return item->appId == QLatin1String("web") ? launchWeb(*item) : launchNative(*item);
}

bool ApplicationModel::launchNative(const CatalogItem &item)
{
    const QString executable = resolveExecutable(item);
    if (executable.isEmpty()) {
        emit notification(QStringLiteral("Ứng dụng chưa được cài đặt: %1").arg(item.appId));
        return false;
    }

    qint64 pid = 0;
    const bool ok = QProcess::startDetached(executable, {}, QString(), &pid);
    if (!ok) {
        emit notification(QStringLiteral("Không thể mở %1").arg(item.name));
        return false;
    }

    Entry entry;
    entry.appId = item.appId;
    entry.name = item.name;
    entry.iconName = item.iconName;
    entry.executable = executable;
    entry.pid = pid;
    entry.tracked = pid > 0;
    entry.background = false;
    entry.state = QStringLiteral("running");
    addEntry(entry);

    emit notification(QStringLiteral("Đã mở %1").arg(item.name));
    return true;
}

bool ApplicationModel::launchWeb(const CatalogItem &item)
{
    const QString browser = resolveBrowser();

    Entry entry;
    entry.appId = item.appId;
    entry.name = item.name;
    entry.iconName = item.iconName;
    entry.background = true;
    entry.state = QStringLiteral("background");

    if (!browser.isEmpty()) {
        qint64 pid = 0;
        if (QProcess::startDetached(browser, {QString::fromLatin1(kWebHome)}, QString(), &pid)) {
            entry.executable = browser;
            entry.pid = pid;
            entry.tracked = pid > 0;
            addEntry(entry);
            emit notification(QStringLiteral("Đã mở trình duyệt"));
            return true;
        }
    }

    // Không tìm được trình duyệt để spawn -> nhờ hệ thống mở, không theo dõi được.
    if (!QDesktopServices::openUrl(QUrl(QString::fromLatin1(kWebHome)))) {
        emit notification(QStringLiteral("Không tìm thấy trình duyệt"));
        return false;
    }

    entry.tracked = false;
    addEntry(entry);
    emit notification(QStringLiteral("Đã mở trình duyệt"));
    return true;
}

// ------------------------------------------------------------ lifecycle -----

void ApplicationModel::addEntry(const Entry &entry)
{
    const int existing = indexOf(entry.appId);
    if (existing >= 0) {
        m_entries[existing] = entry;
        const QModelIndex changed = index(existing);
        emit dataChanged(changed, changed);
        emit appsChanged();
        return;
    }

    beginInsertRows({}, m_entries.size(), m_entries.size());
    m_entries.append(entry);
    endInsertRows();
    emit appsChanged();
}

int ApplicationModel::indexOf(const QString &appId) const
{
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).appId == appId)
            return i;
    }
    return -1;
}

void ApplicationModel::removeAt(int row)
{
    if (row < 0 || row >= m_entries.size())
        return;
    beginRemoveRows({}, row, row);
    m_entries.remove(row);
    endRemoveRows();
    emit appsChanged();
}

bool ApplicationModel::processAlive(qint64 pid)
{
    if (pid <= 0)
        return false;
#ifdef Q_OS_LINUX
    return QFileInfo::exists(QStringLiteral("/proc/%1").arg(pid));
#elif defined(Q_OS_UNIX)
    return ::kill(static_cast<pid_t>(pid), 0) == 0 || errno == EPERM;
#else
    return true;
#endif
}

void ApplicationModel::pollProcesses()
{
    if (m_entries.isEmpty())
        return;

    bool dirty = false;
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        const Entry &entry = m_entries.at(i);
        if (!entry.tracked)
            continue;
        if (!processAlive(entry.pid)) {
            removeAt(i);
            dirty = true;
        }
    }

    if (dirty)
        emit appsChanged();
}

bool ApplicationModel::isRunning(const QString &appId) const
{
    return indexOf(appId) >= 0;
}

void ApplicationModel::activate(const QString &appId)
{
    const int row = indexOf(appId);
    if (row < 0)
        return;

    const Entry &entry = m_entries.at(row);
    // Windra 0.2 chưa nói chuyện được với compositor để raise cửa sổ.
    // Nói thật thay vì im lặng không làm gì.
    emit notification(
        QStringLiteral("%1 đang chạy. Chuyển cửa sổ sẽ có khi Windra nối window management.")
            .arg(entry.name));
}

void ApplicationModel::requestClose(const QString &appId)
{
    const int row = indexOf(appId);
    if (row < 0)
        return;

    Entry entry = m_entries.at(row);

    if (!entry.tracked || entry.pid <= 0) {
        removeAt(row);
        emit notification(
            QStringLiteral("Đã bỏ %1 khỏi danh sách. Windra không điều khiển được cửa sổ này.")
                .arg(entry.name));
        return;
    }

#ifdef Q_OS_UNIX
    // Đóng nhẹ nhàng: SIGTERM để app tự lưu và thoát. Không bao giờ SIGKILL mặc định.
    ::kill(static_cast<pid_t>(entry.pid), SIGTERM);
    entry.closing = true;
    m_entries[row] = entry;
    const QModelIndex changed = index(row);
    emit dataChanged(changed, changed);
    emit notification(QStringLiteral("Đang đóng %1...").arg(entry.name));

    const QString targetId = entry.appId;
    const qint64 targetPid = entry.pid;
    QTimer::singleShot(5000, this, [this, targetId, targetPid] {
        const int current = indexOf(targetId);
        if (current < 0 || m_entries.at(current).pid != targetPid)
            return;
        if (!processAlive(targetPid)) {
            removeAt(current);
            return;
        }
        emit notification(
            QStringLiteral("%1 chưa đóng. Chọn lại để buộc dừng.").arg(m_entries.at(current).name));
    });
#else
    Q_UNUSED(entry)
    emit notification(QStringLiteral("Đóng ứng dụng chỉ hỗ trợ trên Linux."));
#endif
}

void ApplicationModel::forceClose(const QString &appId)
{
    const int row = indexOf(appId);
    if (row < 0)
        return;

    const Entry entry = m_entries.at(row);
    if (!entry.tracked || entry.pid <= 0) {
        removeAt(row);
        return;
    }

#ifdef Q_OS_UNIX
    if (!entry.closing) {
        // Chưa thử đóng nhẹ nhàng thì làm bước đó trước.
        requestClose(appId);
        return;
    }
    if (m_previewMode) {
        // Dev preview không buộc dừng process nào cả.
        emit notification(
            QStringLiteral("Preview an toàn: không buộc dừng %1").arg(entry.name));
        return;
    }
    ::kill(static_cast<pid_t>(entry.pid), SIGKILL);
    emit notification(QStringLiteral("Đã buộc dừng %1").arg(entry.name));
#else
    emit notification(QStringLiteral("Buộc dừng chỉ hỗ trợ trên Linux."));
#endif
}

void ApplicationModel::forget(const QString &appId)
{
    removeAt(indexOf(appId));
}

// ---------------------------------------------------------------- model -----

int ApplicationModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant ApplicationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const Entry &entry = m_entries.at(index.row());
    switch (role) {
    case AppIdRole: return entry.appId;
    case NameRole: return entry.name;
    case IconNameRole: return entry.iconName;
    case PidRole: return entry.pid;
    case ExecutableRole: return entry.executable;
    case StateRole: return entry.closing ? QStringLiteral("closing") : entry.state;
    case BackgroundRole: return entry.background;
    case WindowsRole: return entry.windows;
    case TrackedRole: return entry.tracked;
    default: return {};
    }
}

QHash<int, QByteArray> ApplicationModel::roleNames() const
{
    return {
        {AppIdRole, "appId"},
        {NameRole, "name"},
        {IconNameRole, "iconName"},
        {PidRole, "pid"},
        {ExecutableRole, "executable"},
        {StateRole, "state"},
        {BackgroundRole, "background"},
        {WindowsRole, "windows"},
        {TrackedRole, "tracked"},
    };
}

static QVariantMap entryToMap(const ApplicationModel::Entry &entry)
{
    QVariantMap map;
    map.insert(QStringLiteral("appId"), entry.appId);
    map.insert(QStringLiteral("name"), entry.name);
    map.insert(QStringLiteral("iconName"), entry.iconName);
    map.insert(QStringLiteral("pid"), entry.pid);
    map.insert(QStringLiteral("executable"), entry.executable);
    map.insert(QStringLiteral("state"), entry.closing ? QStringLiteral("closing") : entry.state);
    map.insert(QStringLiteral("background"), entry.background);
    map.insert(QStringLiteral("windows"), entry.windows);
    map.insert(QStringLiteral("tracked"), entry.tracked);
    return map;
}

QVariantList ApplicationModel::running() const
{
    QVariantList list;
    for (const Entry &entry : m_entries) {
        if (!entry.background)
            list.append(entryToMap(entry));
    }
    return list;
}

QVariantList ApplicationModel::background() const
{
    QVariantList list;
    for (const Entry &entry : m_entries) {
        if (entry.background)
            list.append(entryToMap(entry));
    }
    return list;
}
