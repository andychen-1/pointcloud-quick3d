#include "PointCloudGeometry.h"

#include <QVector3D>

constexpr const int STRIDE = 6 * sizeof(float);

// 反射率调色板
#define kPaletteSize 256
typedef struct {
    float r;
    float g;
    float b;
} PRGB;
static PRGB palette[kPaletteSize]{};

static void setLidarImagePlette() {
    static std::once_flag once;
    call_once(once, [] {
        for (int i = 0; i < kPaletteSize; i++) {
            PRGB *color = palette + i;
            int reflectivity = i;
            if (reflectivity < 30) {
                color->r = 0.0f;
                color->g = (int(reflectivity * 255 / 30) & 0xff) / 255.0f;
                color->b = 1.0f;
            } else if (reflectivity < 90) {
                color->r = 0.0f;
                color->g = 1.0f;
                color->b = (int((90 - reflectivity) * 255 / 60) & 0xff) / 255.0f;
            } else if (reflectivity < 150) {
                color->r = (((reflectivity - 90) * 255 / 60) & 0xff) / 255.0f;
                color->g = 1.0f;
                color->b = 0.0f;
            } else {
                color->r = 1.0f;
                color->g = (int((255 - reflectivity) * 255 / (256 - 150)) & 0xff) / 255.0f;
                color->b = 0.0f;
            }
        }
    });
}

PointCloudGeometry::PointCloudGeometry(QObject *parent)
    : QQuick3DGeometry{}
    , m_pointCount{0}
    , m_colorMode{RGB}
    , m_intensityMin{0.0f}
    , m_intensityMax{255.0f}
{
    setLidarImagePlette();
}

void PointCloudGeometry::setSource(const QString &path) {
    if (m_source != path) {
        m_source = path;
        emit sourceChanged();
        m_points = PcdLoader::loadBinary(path);
        setPointCount(m_points.size());
        rebuild();
    }
}

void PointCloudGeometry::setColorMode(ColorMode m) {
    if (m_colorMode == m)
        return;
    m_colorMode = m;
    emit colorModeChanged();
    rebuild();
}

void PointCloudGeometry::setPointCount(int pointCount)
{
    if (pointCount != m_pointCount) {
        m_pointCount = pointCount;
        m_vertexData.resize(m_pointCount * STRIDE);
        emit pointCountChanged();
    }
}

void PointCloudGeometry::setIntensityMin(float v) {
    if (qFuzzyCompare(m_intensityMin, v))
        return;
    m_intensityMin = v;
    rebuild();
    emit intensityMinChanged();
}

void PointCloudGeometry::setIntensityMax(float v) {
    if (qFuzzyCompare(m_intensityMax, v))
        return;
    m_intensityMax = v;
    rebuild();
    emit intensityMaxChanged();
}

float PointCloudGeometry::distanceOfCamera(ViewDirection kDirect, float kVFov, float kMargin)
{
    const float tanHalf = std::tan(kVFov * M_PI / 180.0f * 0.5f);

    // 渲染坐标系下的包围盒派生量
    const float halfH  = (m_boundsMax.y() - m_boundsMin.y()) * 0.5f;  // 高度半径 (Y轴)
    const float halfW  = (m_boundsMax.x() - m_boundsMin.x()) * 0.5f;  // 宽度半径 (X轴)
    const float halfD  = (m_boundsMax.z() - m_boundsMin.z()) * 0.5f;  // 深度半径 (Z轴)
    const float midZ   = (m_boundsMin.z() + m_boundsMax.z()) * 0.5f;  // Z轴中心 (Back偏移用)
    const float topY   =  m_boundsMax.y();                             // Y轴最高点 (Top用)
    const float edgeXN =  std::abs(m_boundsMin.x());                   // X负边界距离 (Left用)
    const float edgeXP =  m_boundsMax.x();                             // X正边界距离 (Right用)

    float dist = 0.0f;
    switch (kDirect) {
    case Back:
        dist = std::abs(midZ);
        break;
    case Front:
        dist = halfH / tanHalf + halfD;
        break;
    case Left:
        dist = halfH / tanHalf + edgeXN;
        break;
    case Right:
        dist = halfH / tanHalf + edgeXP;
        break;
    case Top:
        dist = halfD / tanHalf + topY;
        break;
    case Bottom:
        break;
    }

    return dist * kMargin;
}

void PointCloudGeometry::rebuild() {
    if (m_points.isEmpty()) return;

    int filteredCount = m_points.size();
    m_vertexData.resize(filteredCount * STRIDE);
    float *dst = reinterpret_cast<float *>(m_vertexData.data());

    QVector3D bMin( 1e9f,  1e9f,  1e9f);
    QVector3D bMax(-1e9f, -1e9f, -1e9f);

    for (auto &p : m_points) {
        if (p.intensity < m_intensityMin || p.intensity > m_intensityMax) {
            filteredCount--;
            continue;
        }

        float qx = -p.y, qy = p.z, qz = -p.x;
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

        bMin = QVector3D(std::min(bMin.x(), qx), std::min(bMin.y(), qy), std::min(bMin.z(), qz));
        bMax = QVector3D(std::max(bMax.x(), qx), std::max(bMax.y(), qy), std::max(bMax.z(), qz));
    }

    setPointCount(filteredCount);

    // 保存极值坐标
    if (m_boundsMin != bMin || m_boundsMax != bMax) {
        m_boundsMin  = bMin;
        m_boundsMax  = bMax;
        emit boundsChanged();
    }

    clear();
    setVertexData(m_vertexData);
    setStride(STRIDE);
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Points);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 0, QQuick3DGeometry::Attribute::F32Type);
    addAttribute(QQuick3DGeometry::Attribute::ColorSemantic, 3 * sizeof(float), QQuick3DGeometry::Attribute::F32Type);
    setBounds(bMin, bMax);
    update();
}
