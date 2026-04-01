#ifndef CORNERBRACKETGEOMETRY_H
#define CORNERBRACKETGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>
#include <QQmlEngine>

class CornerBracketGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(float size      READ size      WRITE setSize      NOTIFY sizeChanged)
    Q_PROPERTY(float lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)

public:
    explicit CornerBracketGeometry(QObject *parent = nullptr);

    float size()      const { return m_size; }
    float lineWidth() const { return m_lineWidth; }

    void setSize(float s);
    void setLineWidth(float w);

signals:
    void sizeChanged();
    void lineWidthChanged();

private:
    float m_size;
    float m_lineWidth;
    void  rebuild();
};

#endif // CORNERBRACKETGEOMETRY_H
