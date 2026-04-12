#ifndef EVENTSTEALINGPREVENTOR_H
#define EVENTSTEALINGPREVENTOR_H

// EventBlocker.h
#pragma once
#include <QObject>
#include <QQuickItem>
#include <QPointer>

class EventStealingPreventor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem* guardedItem READ guardedItem
                   WRITE setGuardedItem NOTIFY guardedItemChanged)
    Q_PROPERTY(bool active READ active
                   WRITE setActive   NOTIFY activeChanged)
    Q_PROPERTY(bool blocking READ blocking NOTIFY blockingChanged)

public:
    explicit EventStealingPreventor(QObject *parent = nullptr);

    QQuickItem *guardedItem() const { return m_item; }
    void setGuardedItem(QQuickItem *item);

    bool active()   const { return m_active;   }
    bool blocking() const { return m_blocking; }

    void setActive(bool v);

signals:
    void guardedItemChanged();
    void activeChanged();
    void blockingChanged();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;

private:
    void setBlocking(bool v);
    void reInstall();

    QPointer<QQuickItem>   m_item;
    QPointer<QQuickWindow> m_window;
    bool m_active   = true;
    bool m_blocking = false;
};

#endif // EVENTSTEALINGPREVENTOR_H
