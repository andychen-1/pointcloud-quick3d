#ifndef CORNERBRACKETGEOMETRY_H
#define CORNERBRACKETGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>
#include <QQmlEngine>

class CornerBracketGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(float size READ size WRITE setSize NOTIFY sizeChanged)

public:
    explicit CornerBracketGeometry(QObject *parent = nullptr);

    float size() const { return m_size; }
    void  setSize(float s);

signals:
    void sizeChanged();

private:
    float m_size;
    void  rebuild();
};

#endif // CORNERBRACKETGEOMETRY_H
