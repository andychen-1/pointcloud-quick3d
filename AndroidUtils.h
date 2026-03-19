#ifndef ANDROIDUTILS_H
#define ANDROIDUTILS_H

#include <QObject>
#include <QQmlEngine>

class AndroidUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit AndroidUtils(QObject *parent = nullptr);

    Q_INVOKABLE void setFullscreen(bool enabled);
    Q_INVOKABLE void setOrientation(int orientation);
};

#endif // ANDROIDUTILS_H
