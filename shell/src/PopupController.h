#pragma once

#include <QObject>
#include <QString>

/*!
 * Điều phối popup của shell.
 *
 * Chỉ **một** popup system được mở tại một thời điểm. Mọi popup bind
 * `open: popupController.isOpen("<tên>")` nên không nơi nào phải tự viết lại
 * logic đóng cái khác — click Wi-Fi tự đóng Volume, click ra ngoài đóng tất cả.
 *
 * Tên đang dùng: wifi, volume, battery, calendar, apps, launcher, power.
 */
class PopupController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString active READ active NOTIFY activeChanged)
    Q_PROPERTY(bool anyOpen READ anyOpen NOTIFY activeChanged)

public:
    using QObject::QObject;

    QString active() const { return m_active; }
    bool anyOpen() const { return !m_active.isEmpty(); }

    /*
     * Cố ý KHÔNG có isOpen(name) dạng Q_INVOKABLE: binding gọi hàm sẽ không
     * đăng ký phụ thuộc vào activeChanged nên không bao giờ chạy lại.
     * QML luôn so sánh trực tiếp:  open: popupController.active === "battery"
     */
    Q_INVOKABLE void open(const QString &name);
    Q_INVOKABLE void toggle(const QString &name);
    Q_INVOKABLE void close();

signals:
    void activeChanged();
    //! Phát ra tên popup vừa mở (rỗng khi đóng hết) — dùng để bật/tắt polling.
    void opened(const QString &name);

private:
    QString m_active;
};
