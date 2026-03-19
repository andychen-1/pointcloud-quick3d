#ifndef POINTCLOUDGEOMETRY_H
#define POINTCLOUDGEOMETRY_H

#include "PcdLoader.h"

#include <QObject>
#include <QQmlEngine>
#include <QtQuick3D/QQuick3DGeometry>

class PointCloudGeometry : public QQuick3DGeometry {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(ColorMode colorMode READ colorMode WRITE setColorMode NOTIFY colorModeChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointCountChanged)

public:
    enum ColorMode { RGB, Intensity };
    Q_ENUM(ColorMode)

    explicit PointCloudGeometry(QObject *parent = nullptr);

    QString source() const { return m_source; }
    void setSource(const QString &path);

    ColorMode colorMode() const { return m_colorMode; }
    void setColorMode(ColorMode m);

    int pointCount() const { return m_pointCount; }

signals:
    void sourceChanged();
    void colorModeChanged();
    void pointCountChanged();

private:
    void rebuild();
    static QVector3D intensityToColor(float v); // 伪彩色 jet colormap

    int m_pointCount = 0;
    QString m_source;
    ColorMode m_colorMode = RGB;
    QVector<PointXYZRGBI> m_points;
};

#endif // POINTCLOUDGEOMETRY_H
