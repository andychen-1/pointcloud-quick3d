#include "PointCloudGeometry.h"

#include <QVector3D>

// 反射率调色板
#define kPaletteSize 256
typedef struct {
    float r;
    float g;
    float b;
} PRGB;
static PRGB palette[kPaletteSize] {};

static void setLidarImagePlette() {
    for(int i=0; i<kPaletteSize; i++) {
        PRGB *color = palette + i;
        int reflectivity = i;
        if (reflectivity < 30)
        {
            color->r = 0.0f;
            color->g = (int(reflectivity * 255 / 30) & 0xff) / 255.0f;
            color->b = 1.0f;
        }
        else if (reflectivity < 90)
        {
            color->r = 0.0f;
            color->g = 1.0f;
            color->b = (int((90 - reflectivity) * 255 / 60) & 0xff) / 255.0f;
        }
        else if (reflectivity < 150)
        {
            color->r = (((reflectivity - 90) * 255 / 60) & 0xff) / 255.0f;
            color->g = 1.0f;
            color->b = 0.0f;
        }
        else
        {
            color->r = 1.0f;
            color->g = (int((255 - reflectivity) * 255 / (256 - 150)) & 0xff) / 255.0f;
            color->b = 0.0f;
        }
    }
}


PointCloudGeometry::PointCloudGeometry(QObject *parent)
    : QQuick3DGeometry{}
{
    setLidarImagePlette();
}

void PointCloudGeometry::setSource(const QString &path) {
    if (m_source == path) return;
    m_source = path;
    m_points = PcdLoader::loadBinary(path);
    m_pointCount = m_points.size();
    emit sourceChanged();
    emit pointCountChanged();
    rebuild();
}

void PointCloudGeometry::setColorMode(ColorMode m) {
    if (m_colorMode == m) return;
    m_colorMode = m;
    emit colorModeChanged();
    rebuild();
}

void PointCloudGeometry::rebuild() {
    if (m_points.isEmpty()) return;

    // Vertex layout: position(3×float) + color(3×float) = 24 bytes
    constexpr int STRIDE = 6 * sizeof(float);
    QByteArray vertexData(m_points.size() * STRIDE, Qt::Uninitialized);
    float *dst = reinterpret_cast<float *>(vertexData.data());

    // 注意：坐标变换与顶点写入保持一致
    // Qt 坐标系：X = -pcd.y, Y = pcd.z, Z = -pcd.x
    QVector3D bMin( 1e9f,  1e9f,  1e9f);
    QVector3D bMax(-1e9f, -1e9f, -1e9f);

    for (auto &p : m_points) {
        float qx = -p.y;
        float qy =  p.z;
        float qz = -p.x;

        *dst++ = qx;
        *dst++ = qy;
        *dst++ = qz;

        if (m_colorMode == RGB) {
            *dst++ = ((p.rgb >> 16) & 0xFF) / 255.0f;
            *dst++ = ((p.rgb >>  8) & 0xFF) / 255.0f;
            *dst++ = ( p.rgb        & 0xFF) / 255.0f;
        } else {
            PRGB c = palette[static_cast<int>(p.intensity)];
            *dst++ = c.r;
            *dst++ = c.g;
            *dst++ = c.b;
        }

        // 在 Qt 坐标系下计算 AABB
        bMin = QVector3D(std::min(bMin.x(), qx),
                         std::min(bMin.y(), qy),
                         std::min(bMin.z(), qz));
        bMax = QVector3D(std::max(bMax.x(), qx),
                         std::max(bMax.y(), qy),
                         std::max(bMax.z(), qz));
    }

    // 更新包围盒属性并通知 QML
    if (m_boundsMin != bMin || m_boundsMax != bMax) {
        m_boundsMin = bMin;
        m_boundsMax = bMax;
        emit boundsChanged();
    }

    clear();
    setVertexData(vertexData);
    setStride(STRIDE);
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Points);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 0, QQuick3DGeometry::Attribute::F32Type);
    addAttribute(QQuick3DGeometry::Attribute::ColorSemantic, 3 * sizeof(float), QQuick3DGeometry::Attribute::F32Type);

    setBounds(bMin, bMax);
    update();
}
