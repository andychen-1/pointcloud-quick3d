#include "PointCloudGeometry.h"

#include <QVector3D>
#include <cmath>

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

QVector3D PointCloudGeometry::intensityToColor(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    float r = std::clamp(1.5f - std::abs(4.0f * t - 3.0f), 0.0f, 1.0f);
    float g = std::clamp(1.5f - std::abs(4.0f * t - 2.0f), 0.0f, 1.0f);
    float b = std::clamp(1.5f - std::abs(4.0f * t - 1.0f), 0.0f, 1.0f);
    return {r, g, b};
}

void PointCloudGeometry::rebuild() {
    if (m_points.isEmpty()) return;

    // Vertex layout: position(3×float) + color(3×float) = 24 bytes
    constexpr int STRIDE = 6 * sizeof(float);
    QByteArray vertexData(m_points.size() * STRIDE, Qt::Uninitialized);
    float *dst = reinterpret_cast<float *>(vertexData.data());

    for (auto &p : m_points) {
        *dst++ =  -p.y;   // Qt X
        *dst++ =  p.z;   // Qt Y
        *dst++ =  -p.x;   // Qt Z

        if (m_colorMode == RGB) {
            // packed rgb: bits [23:16]=R [15:8]=G [7:0]=B
            *dst++ = ((p.rgb >> 16) & 0xFF) / 255.0f;
            *dst++ = ((p.rgb >>  8) & 0xFF) / 255.0f;
            *dst++ = ( p.rgb        & 0xFF) / 255.0f;
        } else {

            PRGB c = palette[static_cast<int>(p.intensity)];
            *dst++ = c.r;
            *dst++ = c.g;
            *dst++ = c.b;
        }
    }

    clear();
    setVertexData(vertexData);
    setStride(STRIDE);
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Points);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 0, QQuick3DGeometry::Attribute::F32Type);
    addAttribute(QQuick3DGeometry::Attribute::ColorSemantic, 3 * sizeof(float), QQuick3DGeometry::Attribute::F32Type);

    // AABB
    QVector3D bMin(1e9,1e9,1e9), bMax(-1e9,-1e9,-1e9);
    for (auto &p : m_points) {
        bMin = QVector3D(std::min(bMin.x(),p.x), std::min(bMin.y(),p.y), std::min(bMin.z(),p.z));
        bMax = QVector3D(std::max(bMax.x(),p.x), std::max(bMax.y(),p.y), std::max(bMax.z(),p.z));
    }
    setBounds(bMin, bMax);
    update();
}
