import QtQuick
import QtQuick3D

Item {
    id: control
    width: 80; height: 80
    required property Camera camera

    function rotByQuat(q, v) {
        const qx = q.x, qy = q.y, qz = q.z, qw = q.scalar
        const tx = 2*(qy*v.z - qz*v.y)
        const ty = 2*(qz*v.x - qx*v.z)
        const tz = 2*(qx*v.y - qy*v.x)
        return {
            x: v.x + qw*tx + (qy*tz - qz*ty),
            y: v.y + qw*ty + (qz*tx - qx*tz),
            z: v.z + qw*tz + (qx*ty - qy*tx)
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // 原点偏下居中，留出上方 Z 轴空间
            const cx = width  * 0.50
            const cy = height * 0.58
            const arm = 26    // 轴长（像素）

            // 相机旋转共轭 → 世界轴投影到相机空间
            const q  = control.camera.sceneRotation
            const qi = { x: -q.x, y: -q.y, z: -q.z, scalar: q.scalar }

            // 三轴定义：颜色与参考图一致（X红、Y绿、Z白）
            const axes = [
                { v: {x:0,y:0,z:-1}, col: "#FF3333", lbl: "X" },
                { v: {x:-1,y:0,z:0}, col: "#33CC33", lbl: "Y" },
                { v: {x:0,y:1,z:0}, col: "#3333CC", lbl: "Z" },
            ]

            // 背景圆
            ctx.beginPath()
            ctx.arc(cx, cy, 34, 0, Math.PI * 2)
            ctx.fillStyle = "rgba(13,13,15,0.72)"
            ctx.fill()
            ctx.strokeStyle = "rgba(255,255,255,0.07)"
            ctx.lineWidth = 1
            ctx.stroke()

            // 投影到屏幕坐标，按深度排序（背面先画）
            const proj = axes.map(a => {
                const c = rotByQuat(qi, a.v)
                return {
                    sx: cx + c.x * arm,
                    sy: cy - c.y * arm,   // Y 轴屏幕翻转
                    z:  c.z,
                    col: a.col,
                    lbl: a.lbl
                }
            })
            proj.sort((a, b) => a.z - b.z)

            // 画轴线 + 箭头 + 白色标签
            for (const p of proj) {
                const behind = p.z < -0.05
                // 背面轴稍微暗一点，但不做透明虚化
                ctx.globalAlpha = behind ? 0.45 : 1.0

                // 轴线
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(p.sx, p.sy)
                ctx.strokeStyle = p.col
                ctx.lineWidth   = 1.8
                ctx.stroke()

                // 端点圆头（背面轴不画）
                if (!behind) {
                    ctx.beginPath()
                    ctx.arc(p.sx, p.sy, 2.5, 0, Math.PI * 2)
                    ctx.fillStyle = p.col
                    ctx.fill()
                }

                // 标签：白色，位于轴端点外侧
                const ox = p.sx - cx, oy = p.sy - cy
                const len = Math.sqrt(ox*ox + oy*oy) || 1
                const lx  = p.sx + ox/len * 8
                const ly  = p.sy + oy/len * 8

                ctx.font         = "bold 10px sans-serif"
                ctx.textAlign    = "center"
                ctx.textBaseline = "middle"
                ctx.fillStyle    = "#FFFFFF"   // 字体颜色
                ctx.fillText(p.lbl, lx, ly)
            }

            ctx.globalAlpha = 1.0

            // 原点小圆点
            ctx.beginPath()
            ctx.arc(cx, cy, 2, 0, Math.PI * 2)
            ctx.fillStyle = "#FFFFFF"
            ctx.fill()
        }
    }

    FrameAnimation {
        running: true
        onTriggered: canvas.requestPaint()
    }
}
