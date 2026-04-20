#include "EventGrabGuard.h"
#include <QTouchEvent>
#include <QMouseEvent>
#include <QQuickWindow>

EventGrabGuard::EventGrabGuard(QObject *parent) : QObject(parent) {}

void EventGrabGuard::setGuardedItem(QQuickItem *item) {
    if (m_item == item) return;
    m_item = item;
    emit guardedItemChanged();
    reInstall();
}

void EventGrabGuard::setActive(bool v) {
    if (m_active == v) return;
    m_active = v;
    if (!v) setBlocking(false);
    emit activeChanged();
}

void EventGrabGuard::setBlocking(bool v) {
    if (m_blocking == v) return;
    m_blocking = v;
    emit blockingChanged();
}

void EventGrabGuard::reInstall() {
    if (m_window) m_window->removeEventFilter(this);
    if (!m_item)  return;

    auto attach = [this]() {
        m_window = m_item->window();
        if (m_window) m_window->installEventFilter(this);
    };

    if (m_item->window()) {
        attach();
    } else {
        connect(m_item, &QQuickItem::windowChanged,
                this, [this, attach](QQuickWindow *w) {
                    if (w) attach();
                }, Qt::SingleShotConnection);
    }
}

bool EventGrabGuard::eventFilter(QObject *, QEvent *event) {
    if (!m_active || !m_item || !m_item->isVisible())
        return false;

    switch (event->type()) {
    case QEvent::TouchBegin: {
        auto *te = static_cast<QTouchEvent *>(event);
        if (!te->points().isEmpty()) {
            QPointF local = m_item->mapFromScene(
                te->points().first().scenePosition());
            setBlocking(m_item->contains(local));
        }
        break;
    }
    case QEvent::TouchEnd:
    case QEvent::TouchCancel:
        setBlocking(false);
        break;
    default:
        break;
    }

    return false;   // 不消费事件
}
