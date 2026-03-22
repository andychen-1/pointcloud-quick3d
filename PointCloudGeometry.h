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
    Q_PROPERTY(QVector3D boundsMin READ boundsMin NOTIFY boundsChanged)
    Q_PROPERTY(QVector3D boundsMax READ boundsMax NOTIFY boundsChanged)
    Q_PROPERTY(float intensityMin READ intensityMin WRITE setIntensityMin NOTIFY intensityMinChanged)
    Q_PROPERTY(float intensityMax READ intensityMax WRITE setIntensityMax NOTIFY intensityMaxChanged)

public:
    enum ColorMode { RGB, Intensity };
    Q_ENUM(ColorMode)

    explicit PointCloudGeometry(QObject *parent = nullptr);

    QString source() const { return m_source; }
    void setSource(const QString &path);

    ColorMode colorMode() const { return m_colorMode; }
    void setColorMode(ColorMode m);

    int pointCount() const { return m_pointCount; }

    QVector3D boundsMin() const { return m_boundsMin; }
    QVector3D boundsMax() const { return m_boundsMax; }

    float intensityMin() const { return m_intensityMin; }
    float intensityMax() const { return m_intensityMax; }

    void setIntensityMin(float v);
    void setIntensityMax(float v);

signals:
    void sourceChanged();
    void colorModeChanged();
    void pointCountChanged();
    void boundsChanged();
    void intensityMinChanged();
    void intensityMaxChanged();

private:
    void rebuild();

    int m_pointCount = 0;
    QString m_source;
    ColorMode m_colorMode;
    QVector<PointXYZRGBI> m_points;
    QVector3D m_boundsMin;
    QVector3D m_boundsMax;

    float m_intensityMin;
    float m_intensityMax;
};

#endif // POINTCLOUDGEOMETRY_H
