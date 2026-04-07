#ifndef POINTCLOUDGEOMETRY_H
#define POINTCLOUDGEOMETRY_H

#include "PcdLoader.h"

#include <QObject>
#include <QQmlEngine>
#include <QQuaternion>
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

    enum FOVOrientation { Vertical, Horizontal };
    Q_ENUM(FOVOrientation)

    enum ViewDirection { Front, Back, Left, Right, Top, Bottom };
    Q_ENUM(ViewDirection)

    enum ExtremumIndex {
        BoundMinX, BoundMinY, BoundMinZ, BoundMaxX, BoundMaxY, BoundMaxZ
    };
    Q_ENUM(ExtremumIndex)

    enum AxisIndex { XAxis, YAxis, ZAxis };
    Q_ENUM(AxisIndex)

    explicit PointCloudGeometry(QObject *parent = nullptr);

    QString source() const { return m_source; }
    void setSource(const QString &path);

    ColorMode colorMode() const { return m_colorMode; }
    void setColorMode(ColorMode m);

    int  pointCount() const { return m_pointCount; }
    void setPointCount(int pointCount);

    QVector3D boundsMin() const { return m_boundsMin; }
    QVector3D boundsMax() const { return m_boundsMax; }

    float intensityMin() const { return m_intensityMin; }
    float intensityMax() const { return m_intensityMax; }

    void setIntensityMin(float v);
    void setIntensityMax(float v);

    // 返回场景坐标（变换后）
    Q_INVOKABLE QVector3D scenePointAt(int index) const;
    // 返回原始 LiDAR 坐标
    Q_INVOKABLE QVector3D rawPointAt(int index) const;
    // 新增公开方法
    Q_INVOKABLE int pickPoint(QVector2D touchPos,
                              QVector3D camWorldPos,
                              QQuaternion camWorldRot,
                              float fovY,
                              float aspect,
                              float nearPlane,
                              float farPlane,
                              float vpWidth,
                              float vpHeight,
                              float tolerancePx = 40.0f);

signals:
    void sourceChanged();
    void colorModeChanged();
    void pointCountChanged();
    void boundsChanged();
    void intensityMinChanged();
    void intensityMaxChanged();

private:
    int   m_pointCount;
    float m_intensityMin;
    float m_intensityMax;

    QString m_source;
    ColorMode m_colorMode;
    QVector<PointXYZRGBI> m_points;
    QVector3D m_boundsMin;
    QVector3D m_boundsMax;
    QByteArray m_vertexData;
    QVector<int>  m_visibleIndices;

    void rebuild();
};

#endif // POINTCLOUDGEOMETRY_H
