#include "CornerBracketGeometry.h"

#include <QVector3D>

CornerBracketGeometry::CornerBracketGeometry(QObject *parent)
    : QQuick3DGeometry{}
    , m_size{1.0f}
{}

void CornerBracketGeometry::setSize(float s) {
    if (qFuzzyCompare(m_size, s))
        return;
    m_size = s;
    emit sizeChanged();
    rebuild();
}

void CornerBracketGeometry::rebuild() {
    const float h = m_size * 0.5f; // 包围盒半边长
    const float t = h * 0.30f;     // 角标臂长 = 边长 30%，可按需调整

    // 8 个角点的轴方向符号（sx/sy/sz ∈ {-1, +1}）
    struct Corner {
        float sx, sy, sz;
    };
    constexpr Corner corners[8] = {
        {-1, -1, -1}, {1, -1, -1}, {1, -1, 1}, {-1, -1, 1}, // 底面四角
        {-1, 1, -1},  {1, 1, -1},  {1, 1, 1},  {-1, 1, 1},  // 顶面四角
    };

    // 每角 3 条臂 × 2 端点，共 8 × 3 × 2 = 48 顶点
    constexpr int VERTEX_COUNT = 8 * 3 * 2;
    constexpr int STRIDE = 3 * sizeof(float);

    QByteArray vdata(VERTEX_COUNT * STRIDE, Qt::Uninitialized);
    float *dst = reinterpret_cast<float *>(vdata.data());

    auto emit3 = [&](float x, float y, float z) {
        *dst++ = x;
        *dst++ = y;
        *dst++ = z;
    };

    for (const auto &c : corners) {
        const float ox = c.sx * h;
        const float oy = c.sy * h;
        const float oz = c.sz * h;

        // 沿 X 轴臂：角点 → 向盒内缩 t
        emit3(ox, oy, oz);
        emit3(ox - c.sx * t, oy, oz);

        // 沿 Y 轴臂
        emit3(ox, oy, oz);
        emit3(ox, oy - c.sy * t, oz);

        // 沿 Z 轴臂
        emit3(ox, oy, oz);
        emit3(ox, oy, oz - c.sz * t);
    }

    clear();
    setVertexData(vdata);
    setStride(STRIDE);
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Lines);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 0, QQuick3DGeometry::Attribute::F32Type);
    setBounds(QVector3D(-h, -h, -h), QVector3D(h, h, h));
    update();
}
