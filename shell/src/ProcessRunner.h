#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

#include <functional>

/*!
 * Helper chạy command Linux **bất đồng bộ**.
 *
 * Shell không được block UI thread để đọc volume hay danh sách Wi-Fi, nên mọi
 * backend prototype dựa trên CLI (wpctl, pactl, nmcli) đều đi qua đây.
 * Khi các backend đó được thay bằng D-Bus/native API thì file này biến mất
 * cùng với chúng — không có logic sản phẩm nào phụ thuộc vào nó.
 */
class ProcessRunner
{
public:
    struct Result {
        bool ok = false;      //!< process chạy xong và exitCode == 0
        int exitCode = -1;
        QString stdOut;
        QString stdErr;
    };

    using Callback = std::function<void(const Result &)>;

    //! Trả về đường dẫn tuyệt đối của `program`, rỗng nếu không có trong PATH.
    static QString which(const QString &program);
    static bool exists(const QString &program) { return !which(program).isEmpty(); }

    /*!
     * Chạy lệnh và gọi `callback` trên event loop của `context`.
     * `context` bị huỷ => callback không bao giờ được gọi (an toàn khi shell thoát).
     */
    static void run(QObject *context,
                    const QString &program,
                    const QStringList &arguments,
                    Callback callback,
                    int timeoutMs = 5000);

    //! Chạy và bỏ qua kết quả (set-volume, set-mute...).
    static void runDetachedResult(QObject *context,
                                  const QString &program,
                                  const QStringList &arguments,
                                  int timeoutMs = 5000);
};
