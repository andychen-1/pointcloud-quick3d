pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import QtQuick3D
import QtQuick3D.Helpers

import pointcloud3d

Item {
    id: view3DRoot

    property string defaultViewName: "back"

    QtObject {
        id: props

         property string viewName: view3DRoot.defaultViewName

        // ── 视角预设 ────────────────────────────────────────────────────
        readonly property var viewPresets: {
            const kVFov   = orbitCamera.fieldOfView

            const midY = (pcGeom.boundsMin.y + pcGeom.boundsMax.y) * 0.5
            const midZ = (pcGeom.boundsMin.z + pcGeom.boundsMax.z) * 0.5

            const halfT = Math.tan(kVFov * Math.PI / 180.0 * 0.5);
            const halfD = (pcGeom.boundsMax.z - pcGeom.boundsMin.z) * 0.5;
            const halfH  = (pcGeom.boundsMax.y - pcGeom.boundsMin.y) * 0.5;

            const distH = halfH / halfT
            const distD = halfD / halfT

            const edgeXN =  Math.abs(pcGeom.boundsMin.x);
            const edgeXP =  pcGeom.boundsMax.x;
            const edgeYP = pcGeom.boundsMax.y;

            return {
                "back":  { nodePos: Qt.vector3d(0, 0, midZ),    nodeRot: Qt.vector3d(0, 0, 0), camPos: Qt.vector3d(0, 0, -midZ) },
                "front": { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,  180, 0), camPos: Qt.vector3d(0, 0, distH + halfD) },
                "left":  { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,  -90, 0), camPos: Qt.vector3d(0, 0, distH + edgeXN) },
                "right": { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,   90, 0), camPos: Qt.vector3d(0, 0, distH + edgeXP) },
                "top":   { nodePos: Qt.vector3d(0, 0, midZ - midY), nodeRot: Qt.vector3d(-90,  0, 0), camPos: Qt.vector3d(0, 0, distD + edgeYP - midY) }
            }
        }
    }

    function applyPreset(name) {
        props.viewName = (name || props.viewName) || defaultViewName
        const p = props.viewPresets[props.viewName]
        // console.log("viewName=", viewName, ", p.nodeRot=", p.nodeRot, ", p.nodePos=", p.nodePos, ", p.camPos=", p.camPos)
        rotAnim.stop()
        orbitCameraNode.position = p.nodePos
        orbitCamera.position = p.camPos
        nodeRotX.to = p.nodeRot.x
        nodeRotY.to = p.nodeRot.y
        nodeRotZ.to = p.nodeRot.z
        rotAnim.start()
    }

    // 判断某 rawIdx 是否已在选点集中，返回 selectionModel 下标，未选则 -1
    function selectionIndexOf(rawIdx) {
        for (let i = 0; i < selectionModel.count; i++) {
            if (selectionModel.get(i).rawIdx === rawIdx)
                return i
        }
        return -1
    }

    // ── 选点集合（多选状态） ──────────────────────────────────────────
    // 每条记录：{ rawIdx, rawX, rawY, rawZ, sceneX, sceneY, sceneZ }
    ListModel {
        id: selectionModel
    }

    // ── 视角切换动画 ─────────────────────────────────────────────────
    ParallelAnimation {
        id: rotAnim
        NumberAnimation { id: nodeRotX; target: orbitCameraNode; property: "eulerRotation.x"; duration: 200; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotY; target: orbitCameraNode; property: "eulerRotation.y"; duration: 200; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotZ; target: orbitCameraNode; property: "eulerRotation.z"; duration: 200; easing.type: Easing.InOutQuad }
    }

    // ── 3D 场景 ─────────────────────────────────────────────────────
    View3D {
        id: pc3d
        anchors.fill: parent

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#0d0d0f"
        }

        camera: orbitCamera

        Node {
            id: orbitCameraNode
            PerspectiveCamera {
                id: orbitCamera
                fieldOfView: 77.2
                clipNear: 0.01
                clipFar:  1000.0
            }
        }

        EventGrabGuard {
            id: blocker
            guardedItem: pickInfoPanel
            active: pickInfoPanel.visible
        }

        OrbitCameraController {
            id: orbitController
            origin: orbitCameraNode
            camera: orbitCamera
            enabled: !blocker.blocking
        }

        // ── 点云渲染 ────────────────────────────────────────────────
        Model {
            id: pcModel
            geometry: PointCloudGeometry {
                id: pcGeom
                source: "assets:/fused_full_cloud_4-1.pcd"
                colorMode: PointCloudGeometry.RGB
                onPointCountChanged: {
                    if (pointCount > 0) {
                        view3DRoot.applyPreset()
                    }
                }
                Component.onCompleted: {
                    if (pointCount > 0) {
                        view3DRoot.applyPreset()
                    }
                }
            }
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                vertexShader: "qrc:/shaders/pointcloud.vert"
                fragmentShader: "qrc:/shaders/pointcloud.frag"
                sourceBlend: CustomMaterial.SrcAlpha
                destinationBlend: CustomMaterial.OneMinusSrcAlpha
            }
        }

        // ── 多选标记（Repeater3D） ───────────────────────────────────
        // 每个选点对应一个 CornerBracket + Sphere 标记
        Repeater3D {
            id: pickMarkers
            model: selectionModel

            delegate: Node {
                id: markerDelegate
                required property real sceneX
                required property real sceneY
                required property real sceneZ
                required property int  rawIdx   // 保留供后续使用

                position: Qt.vector3d(sceneX, sceneY, sceneZ)

                // 根据与相机的距离自适应缩放，保持屏幕像素大小恒定
                readonly property real targetScreenPx: 60
                scale: {
                    const dx = position.x - orbitCamera.scenePosition.x
                    const dy = position.y - orbitCamera.scenePosition.y
                    const dz = position.z - orbitCamera.scenePosition.z
                    const depth = Math.sqrt(dx*dx + dy*dy + dz*dz)
                    if (depth < 0.001) return Qt.vector3d(0.01, 0.01, 0.01)
                    const fovRad = orbitCamera.fieldOfView * Math.PI / 180.0
                    const s = targetScreenPx * depth * Math.tan(fovRad * 0.5) / (pc3d.height * 0.5) / 100
                    return Qt.vector3d(s, s, s)
                }

                Model {
                    scale: Qt.vector3d(50, 50, 50)
                    geometry: CornerBracketGeometry {}
                    materials: CustomMaterial {
                        shadingMode: CustomMaterial.Unshaded
                        vertexShader: "qrc:/shaders/cornerbracket.vert"
                        fragmentShader: "qrc:/shaders/cornerbracket.frag"
                        property vector4d lineColor: Qt.vector4d(0.933333333, 0.376470588, 0.007843137, 1.0)
                    }
                }

                Model {
                    source: "#Sphere"
                    scale: Qt.vector3d(0.12, 0.12, 0.12)
                    materials: PrincipledMaterial {
                        baseColor: "#E54304"
                        emissiveFactor: Qt.vector3d(0.898039216, 0.262745098, 0.015686275)
                    }
                }
            }
        }

        // ── 触摸拾取（多选 toggle 逻辑） ───────────────────────────────
        TapHandler {
            id: pickTap
            parent: pc3d
            onTapped: (eventPoint) => {
                const pos = eventPoint.position
                const idx = pcGeom.pickPoint(
                    Qt.vector2d(pos.x, pos.y),
                    orbitCamera.scenePosition,
                    orbitCamera.sceneRotation,
                    orbitCamera.fieldOfView,
                    pc3d.width / pc3d.height,
                    orbitCamera.clipNear,
                    orbitCamera.clipFar,
                    pc3d.width,
                    pc3d.height,
                    48
                )

                if (idx < 0) return

                // toggle：已选则取消，未选则添加
                const selIdx = view3DRoot.selectionIndexOf(idx)
                if (selIdx >= 0) {
                    selectionModel.remove(selIdx)
                } else {
                    const scenePt = pcGeom.scenePointAt(idx)
                    const rawPt   = pcGeom.rawPointAt(idx)
                    selectionModel.append({
                        rawIdx: idx,
                        rawX:   rawPt.x,   rawY: rawPt.y,   rawZ: rawPt.z,
                        sceneX: scenePt.x, sceneY: scenePt.y, sceneZ: scenePt.z
                    })
                }
            }
        }
    }

    // ── 选点信息面板 ─────────────────────────────────────────────────
    Rectangle {
        id: pickInfoPanel
        visible: selectionModel.count > 0
        anchors { top: parent.top; right: parent.right; topMargin: 20; rightMargin: 20; }
        width:  280
        height: headerRow.height + divider.height + selListView.height + 24
        color: "#10FFFFFF"
        radius: 8

        // ── 标题行 ──────────────────────────────────────────────
        Row {
            id: headerRow
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
            height: 28

            Label {
                text: "选中点  (" + selectionModel.count + ")"
                color: "#FFD700"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: parent.width - clearAllBtn.implicitWidth - 90; height: 1 }
            ToolButton {
                id: clearAllBtn
                text: "清除全部"
                font.pixelSize: 10
                anchors.verticalCenter: parent.verticalCenter
                onClicked: selectionModel.clear()
                contentItem: Label {
                    text: clearAllBtn.text
                    color: "#FF6060"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color: clearAllBtn.pressed ? "#44FF0000" : "transparent"
                    radius: 4
                }
            }
        }

        // 分割线
        Rectangle {
            id: divider
            anchors { top: headerRow.bottom; left: parent.left; right: parent.right; margins: 0 }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // ── 选点列表（可滚动） ────────────────────────────────────
        ListView {
            id: selListView
            anchors {
                top:    divider.bottom
                left:   parent.left
                right:  parent.right
                leftMargin: 8; rightMargin: 8
                topMargin:  4
            }
            // 最多显示 4 行，超出可滚动
            height: 4 * 54
            clip: true

            model: selectionModel
            delegate: Rectangle {
                id: selItem
                required property int  index
                required property int  rawIdx
                required property real rawX
                required property real rawY
                required property real rawZ

                width:  ListView.view.width
                height: 54
                color:  index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.04) : "transparent"

                // 序号
                Label {
                    id: idxLabel
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "#" + (selItem.index + 1)
                    color: "#E57B04"
                    font.pixelSize: 11
                    font.bold: true
                    width: 22
                }

                // 坐标
                Column {
                    anchors {
                        left:           idxLabel.right
                        leftMargin:     4
                        right:          removeBtn.left
                        rightMargin:    4
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 3
                    Label {
                        text: "X: " + selItem.rawX.toFixed(3) + "   Y: " + selItem.rawY.toFixed(3)
                        color: "white"
                        font.pixelSize: 10
                        font.family: "monospace"
                    }
                    Label {
                        text: "Z: " + selItem.rawZ.toFixed(3)
                        color: "#AAAAAA"
                        font.pixelSize: 10
                        font.family: "monospace"
                    }
                }

                // 删除按钮
                RoundButton {
                    id: removeBtn
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 28; height: 28
                    onClicked: selectionModel.remove(selItem.index)
                    display: AbstractButton.IconOnly
                    icon.width: parent.width
                    icon.height: parent.height
                    icon.source: "qrc:/icons/close_small.svg"
                    icon.color: pressed ? "#FF6060" : "#666"
                    padding: 4

                    background: Rectangle {
                        anchors.fill: parent
                        color: removeBtn.pressed ? "#22FF0000" : "transparent"
                        radius: 14
                    }
                }
            }
        }
    }

    // ── 荧光光晕叠加层（遍历所有选点） ──────────────────────────────────
    Item {
        anchors.fill: parent
        enabled: false
        visible: selectionModel.count > 0

        FrameAnimation {
            running: selectionModel.count > 0
            onTriggered: glowCanvas.requestPaint()
        }

        Canvas {
            id: glowCanvas
            anchors.fill: parent
            readonly property real glowRadius: 60

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                for (let i = 0; i < selectionModel.count; i++) {
                    const entry = selectionModel.get(i)
                    const pt    = pc3d.mapFrom3DScene(
                                      Qt.vector3d(entry.sceneX, entry.sceneY, entry.sceneZ))
                    const cx = pt.x, cy = pt.y
                    if (cx < 0 || cx > width || cy < 0 || cy > height) continue

                    const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, glowRadius)
                    grad.addColorStop(0.00, "rgba(255,215,  0,0.35)")
                    grad.addColorStop(0.15, "rgba(255,180,  0,0.20)")
                    grad.addColorStop(0.30, "rgba(255,140,  0,0.10)")
                    grad.addColorStop(0.50, "rgba(255,100,  0,0.00)")
                    ctx.beginPath()
                    ctx.arc(cx, cy, glowRadius, 0, Math.PI * 2)
                    ctx.fillStyle = grad
                    ctx.fill()
                }
            }
        }
    }

    // ── 工具条遮罩（任意触碰触发工具条按钮组关闭） ────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: leftToolbar.anyGroupOpen
        onPressed: leftToolbar.closeGroups()
    }

    // ═══════════════════════════════════════════════════════════════
    // ── 左侧垂直浮动工具条 ───────────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════
    PC3DToolbar {
        id: leftToolbar
        pcGeomAttrs.pointCount: pcGeom.pointCount
        pcGeomAttrs.firstIntensity: pcGeom.intensityMin
        pcGeomAttrs.secondIntensity: pcGeom.intensityMax

        onOperation: function(group, key, args) {
            switch(group) {
            case "color":
                pcGeom.colorMode = (key === "RGB") ? PointCloudGeometry.RGB : PointCloudGeometry.Intensity
                break
            case "view":
                view3DRoot.applyPreset(key)
                break
            case "filter":
                const value = (args && args[0]) || 0
                if ("firstIntensity" === key) {
                    pcGeom.intensityMin = value
                } else if ("secondIntensity" === key) {
                    pcGeom.intensityMax = value
                }
            }
        }
    }
    // ═══════════════════════════════════════════════════════════════
}
