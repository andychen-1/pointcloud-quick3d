#ifndef PCDLOADER_H
#define PCDLOADER_H

#include <QVector>
#include <QVector3D>
#include <QString>

struct PointXYZRGBI {
    float x, y, z;
    uint32_t rgb;   // packed: 0x00RRGGBB
    float intensity;
};

class PcdLoader {

public:
    static QVector<PointXYZRGBI> loadBinary(const QString &filePath);
};

#endif // PCDLOADER_H
