#include "EventStealingPreventor.h"
#include <QTouchEvent>
#include <QMouseEvent>
#include <QQuickWindow>

EventStealingPreventor::EventStealingPreventor(QObject *parent) : QObject(parent) {}

void EventStealingPreventor::setGuardedItem(QQuickItem *item) {
    if (m_item == item) return;
    m_item = item;
    emit guardedItemChanged();
    reInstall();
}

void EventStealingPreventor::setActive(bool v) {
    if (m_active == v) return;
    m_active = v;
    if (!v) setBlocking(false);
    emit activeChanged();
}

void EventStealingPreventor::setBlocking(bool v) {
    if (m_blocking == v) return;
    m_blocking = v;
    emit blockingChanged();
}

void EventStealingPreventor::reInstall() {
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

bool EventStealingPreventor::eventFilter(QObject *, QEvent *event) {
    if (!m_active || !m_item || !m_item->isVisible())
        return false;   // ← 始终不消费，事件正常流通

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
    case QEvent::MouseButtonPress: {
        auto *me = static_cast<QMouseEvent *>(event);
        QPointF local = m_item->mapFromScene(me->scenePosition());
        setBlocking(m_item->contains(local));
        break;
    }
    case QEvent::TouchEnd:
    case QEvent::TouchCancel:
    case QEvent::MouseButtonRelease:
        setBlocking(false);
        break;
    default:
        break;
    }

    return false;   // ← 关键：永远不吃掉事件
}
