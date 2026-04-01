#include "CornerBracketGeometry.h"

#include <QVector3D>


// 发射一个三角形（3 顶点）
static void emitTri(float *&dst,
                    const QVector3D &a,
                    const QVector3D &b,
                    const QVector3D &c)
{
    auto e = [&](const QVector3D &v){
        *dst++ = v.x(); *dst++ = v.y(); *dst++ = v.z();
    };
    e(a); e(b); e(c);
}

// 发射一个四边形面（2 个三角形，保证法线朝外）
static void emitFace(float *&dst,
                     const QVector3D &a,  // 逆时针顺序（从外侧看）
                     const QVector3D &b,
                     const QVector3D &c,
                     const QVector3D &d)
{
    emitTri(dst, a, b, c);
    emitTri(dst, a, c, d);
}

// 将一段臂扩展为矩形截面管（6 面 × 2 三角形 = 12 三角形 = 36 顶点）
// axis  : 臂的方向单位向量
// up/right : 截面的两个垂直轴（已单位化，与 axis 两两正交）
static void emitTube(float *&dst,
                     const QVector3D &p0,
                     const QVector3D &p1,
                     const QVector3D &up,
                     const QVector3D &right,
                     float half)
{
    const QVector3D u = up    * half;
    const QVector3D r = right * half;

    // 截面四角（从 p0 端看，逆时针）
    //   b--c
    //   |  |
    //   a--d
    const QVector3D a0 = p0 - u - r,  b0 = p0 + u - r;
    const QVector3D c0 = p0 + u + r,  d0 = p0 - u + r;

    const QVector3D a1 = p1 - u - r,  b1 = p1 + u - r;
    const QVector3D c1 = p1 + u + r,  d1 = p1 - u + r;

    // 六个面（法线均朝外）
    emitFace(dst, a0, d0, c0, b0);   // p0 端面
    emitFace(dst, a1, b1, c1, d1);   // p1 端面
    emitFace(dst, a0, b0, b1, a1);   // -right 侧面
    emitFace(dst, d0, d1, c1, c0);   // +right 侧面
    emitFace(dst, b0, c0, c1, b1);   // +up    侧面
    emitFace(dst, a0, a1, d1, d0);   // -up    侧面
}

CornerBracketGeometry::CornerBracketGeometry(QObject *parent)
    : QQuick3DGeometry{}
    , m_size{1.0f}
    , m_lineWidth{0.05f}
{
    rebuild();
}

void CornerBracketGeometry::setSize(float s) {
    if (qFuzzyCompare(m_size, s))
        return;
    m_size = s;
    emit sizeChanged();
    rebuild();
}

void CornerBracketGeometry::setLineWidth(float w)
{
    if (qFuzzyCompare(m_lineWidth, w)) return;
    m_lineWidth = w;
    emit lineWidthChanged();
    rebuild();
}

void CornerBracketGeometry::rebuild()
{
    const float h    = m_size      * 0.5f;
    const float t    = h           * 0.75f;
    const float half = m_lineWidth * 0.5f;

    struct Corner { float sx, sy, sz; };
    constexpr Corner corners[8] = {
                                   {-1,-1,-1}, { 1,-1,-1}, { 1,-1, 1}, {-1,-1, 1},
                                   {-1, 1,-1}, { 1, 1,-1}, { 1, 1, 1}, {-1, 1, 1},
                                   };

    // 8 角 × 3 臂 × 6 面 × 2 三角 × 3 顶点
    constexpr int VERTEX_COUNT = 8 * 3 * 6 * 2 * 3;
    constexpr int STRIDE       = 3 * sizeof(float);

    QByteArray vdata(VERTEX_COUNT * STRIDE, Qt::Uninitialized);
    float *dst = reinterpret_cast<float *>(vdata.data());

    for (const auto &c : corners) {
        const QVector3D o(c.sx * h, c.sy * h, c.sz * h);

        // X 臂：终点沿 -sx 方向缩 t，截面在 YZ 平面
        emitTube(dst,
                 o,
                 QVector3D(o.x() - c.sx * t, o.y(), o.z()),
                 QVector3D(0, 1, 0),   // up    = Y
                 QVector3D(0, 0, 1),   // right = Z
                 half);

        // Y 臂：终点沿 -sy 方向缩 t，截面在 XZ 平面
        emitTube(dst,
                 o,
                 QVector3D(o.x(), o.y() - c.sy * t, o.z()),
                 QVector3D(0, 0, 1),   // up    = Z
                 QVector3D(1, 0, 0),   // right = X
                 half);

        // Z 臂：终点沿 -sz 方向缩 t，截面在 XY 平面
        emitTube(dst,
                 o,
                 QVector3D(o.x(), o.y(), o.z() - c.sz * t),
                 QVector3D(0, 1, 0),   // up    = Y
                 QVector3D(1, 0, 0),   // right = X
                 half);
    }

    clear();
    setVertexData(vdata);
    setStride(STRIDE);
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Triangles);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic,
                 0, QQuick3DGeometry::Attribute::F32Type);
    setBounds(QVector3D(-h, -h, -h), QVector3D(h, h, h));
    update();
}
