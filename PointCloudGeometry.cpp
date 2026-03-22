#include "PointCloudGeometry.h"

#include <QVector3D>

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
    if (m_source == path)
        return;
    m_source = path;
    m_points = PcdLoader::loadBinary(path);
    m_pointCount = m_points.size();
    emit sourceChanged();
    emit pointCountChanged();
    rebuild();
}

void PointCloudGeometry::setColorMode(ColorMode m) {
    if (m_colorMode == m)
        return;
    m_colorMode = m;
    emit colorModeChanged();
    rebuild();
}

void PointCloudGeometry::setIntensityMin(float v) {
    if (qFuzzyCompare(m_intensityMin, v))
        return;
    m_intensityMin = v;
    emit intensityMinChanged();
    rebuild();
}

void PointCloudGeometry::setIntensityMax(float v) {
    if (qFuzzyCompare(m_intensityMax, v))
        return;
    m_intensityMax = v;
    emit intensityMaxChanged();
    rebuild();
}

void PointCloudGeometry::rebuild() {
    if (m_points.isEmpty())
        return;

    constexpr int STRIDE = 6 * sizeof(float);

    // 先统计过滤后点数，预分配精确大小
    int filteredCount = 0;
    for (auto &p : m_points) {
        if (p.intensity >= m_intensityMin && p.intensity <= m_intensityMax)
            ++filteredCount;
    }

    QByteArray vertexData(filteredCount * STRIDE, Qt::Uninitialized);
    float *dst = reinterpret_cast<float *>(vertexData.data());

    QVector3D bMin(1e9f, 1e9f, 1e9f);
    QVector3D bMax(-1e9f, -1e9f, -1e9f);

    for (auto &p : m_points) {
        // ★ 过滤：强度在 [min, max] 范围外跳过
        if (p.intensity < m_intensityMin || p.intensity > m_intensityMax)
            continue;

        float qx = -p.y, qy = p.z, qz = -p.x;
        *dst++ = qx;
        *dst++ = qy;
        *dst++ = qz;

        if (m_colorMode == RGB) {
            *dst++ = ((p.rgb >> 16) & 0xFF) / 255.0f;
            *dst++ = ((p.rgb >> 8) & 0xFF) / 255.0f;
            *dst++ = (p.rgb & 0xFF) / 255.0f;
        } else {
            PRGB c = palette[static_cast<int>(p.intensity)];
            *dst++ = c.r;
            *dst++ = c.g;
            *dst++ = c.b;
        }

        bMin = QVector3D(std::min(bMin.x(), qx), std::min(bMin.y(), qy),
                         std::min(bMin.z(), qz));
        bMax = QVector3D(std::max(bMax.x(), qx), std::max(bMax.y(), qy),
                         std::max(bMax.z(), qz));
    }

    // 更新实际渲染点数（供 QML Label 显示）
    if (m_pointCount != filteredCount) {
        m_pointCount = filteredCount;
        emit pointCountChanged();
    }

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
