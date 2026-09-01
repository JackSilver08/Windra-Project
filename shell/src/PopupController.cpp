#include "PopupController.h"

void PopupController::open(const QString &name)
{
    if (m_active == name)
        return;
    m_active = name;
    emit activeChanged();
    emit opened(m_active);
}

void PopupController::toggle(const QString &name)
{
    open(m_active == name ? QString() : name);
}

void PopupController::close()
{
    open(QString());
}
