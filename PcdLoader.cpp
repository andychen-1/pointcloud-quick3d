#include "PcdLoader.h"

#include <QFile>
#include <QTextStream>

QVector<PointXYZRGBI> PcdLoader::loadBinary(const QString &filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return {};

    // --- 解析 ASCII 头部 ---
    qint64 dataOffset = 0;
    int pointCount = 0;
    {
        QByteArray line;
        while (!(line = file.readLine()).isEmpty()) {
            QString s = QString::fromLatin1(line).trimmed();
            if (s.startsWith("POINTS"))
                pointCount = s.split(' ').last().toInt();
            if (s == "DATA binary") {
                dataOffset = file.pos();
                break;
            }
        }
    }

    // --- 读取二进制体 ---
    // 每点布局: x(F4) y(F4) z(F4) rgb(U4) intensity(F4) = 20 bytes
    constexpr int POINT_STRIDE = 20;
    QVector<PointXYZRGBI> points(pointCount);

    QByteArray raw = file.read((qint64)pointCount * POINT_STRIDE);
    const char *ptr = raw.constData();

    for (int i = 0; i < pointCount; ++i, ptr += POINT_STRIDE) {
        PointXYZRGBI &p = points[i];
        memcpy(&p.x,   ptr,      4);
        memcpy(&p.y,   ptr + 4,  4);
        memcpy(&p.z,   ptr + 8,  4);
        memcpy(&p.rgb, ptr + 12, 4);
        memcpy(&p.intensity, ptr + 16, 4);
    }
    return points;
}
