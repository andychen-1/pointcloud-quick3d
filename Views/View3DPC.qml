pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import QtQuick3D
import QtQuick3D.Helpers

import pointcloud3d

Page {
    id: view3DRoot

    property string defaultViewName: "back"

    // ── 激活点 / 编辑状态 ─────────────────────────────────────────
    readonly property int activePtId: pickInfoPanel.activePtId
    property int _nextPtId: 0

    // ── 辅助函数 ─────────────────────────────────────────────────
    function modelIndexOfPtId(ptId) {
        for (let i = 0; i < selectionModel.count; i++)
            if (selectionModel.get(i).ptId === ptId) return i
        return -1
    }

    function selectionIndexOf(rawIdx) {
        for (let i = 0; i < selectionModel.count; i++)
            if (selectionModel.get(i).rawIdx === rawIdx) return i
        return -1
    }

    // D-pad 触发：偏移 editCursor 后重新 pick
    function nudgeActivePoint(dx, dy) {
        if (activePtId < 0) return
        const mi = modelIndexOfPtId(activePtId)
        if (mi < 0) return
        const e  = selectionModel.get(mi)
        const sp = pc3d.mapFrom3DScene(Qt.vector3d(e.sceneX, e.sceneY, e.sceneZ))
        const nx = Math.max(0, Math.min(pc3d.width,  sp.x + dx))
        const ny = Math.max(0, Math.min(pc3d.height, sp.y + dy))

        const idx = pcGeom.pickPoint(
            Qt.vector2d(nx, ny),
            orbitCamera.scenePosition, orbitCamera.sceneRotation,
            orbitCamera.fieldOfView, pc3d.width / pc3d.height,
            orbitCamera.clipNear, orbitCamera.clipFar,
            pc3d.width, pc3d.height, 48
        )

        if (idx < 0) return
        const scenePt = pcGeom.scenePointAt(idx)
        const rawPt   = pcGeom.rawPointAt(idx)
        selectionModel.set(mi, {
            ptId: activePtId, rawIdx: idx,
            rawX: rawPt.x, rawY: rawPt.y, rawZ: rawPt.z,
            sceneX: scenePt.x, sceneY: scenePt.y, sceneZ: scenePt.z
        })
    }

    // ── 选点集合 ─────────────────────────────────────────────────
    ListModel { id: selectionModel }

    // ── 视角切换动画 ──────────────────────────────────────────────
    QtObject {
        id: _view
        property string name: view3DRoot.defaultViewName
        readonly property var presets: {
            const kVFov  = orbitCamera.fieldOfView
            const halfT  = Math.tan(kVFov * Math.PI / 180.0 * 0.5)
            const halfD  = (pcGeom.boundsMax.z - pcGeom.boundsMin.z) * 0.5
            const halfH  = (pcGeom.boundsMax.y - pcGeom.boundsMin.y) * 0.5
            const midY   = (pcGeom.boundsMin.y + pcGeom.boundsMax.y) * 0.5
            const midZ   = (pcGeom.boundsMin.z + pcGeom.boundsMax.z) * 0.5
            const edgeXN = Math.abs(pcGeom.boundsMin.x)
            const edgeXP = pcGeom.boundsMax.x
            const edgeYN = Math.abs(pcGeom.boundsMin.y)
            const edgeYP = pcGeom.boundsMax.y
            const distZ  = halfH / halfT
            const distY  = halfD / halfT

            return {
                "back":   { nodePos: Qt.vector3d(0, 0, midZ),      nodeRot: Qt.vector3d(0,   0, 0), camPos: Qt.vector3d(0, 0, -midZ) },
                "front":  { nodePos: Qt.vector3d(0, midY, midZ),   nodeRot: Qt.vector3d(0, 180, 0), camPos: Qt.vector3d(0, 0, distZ + halfD) },
                "left":   { nodePos: Qt.vector3d(0, midY, midZ),   nodeRot: Qt.vector3d(0, -90, 0), camPos: Qt.vector3d(0, 0, distZ + edgeXN) },
                "right":  { nodePos: Qt.vector3d(0, midY, midZ),   nodeRot: Qt.vector3d(0,  90, 0), camPos: Qt.vector3d(0, 0, distZ + edgeXP) },
                "top":    { nodePos: Qt.vector3d(0, -midY, midZ),  nodeRot: Qt.vector3d(-90, 0, 0), camPos: Qt.vector3d(0, midY, distY + edgeYP) },
                "bottom": { nodePos: Qt.vector3d(0, 0, midZ),      nodeRot: Qt.vector3d(90, 0, 0),  camPos: Qt.vector3d(0, 0, distY + edgeYN) }
            }
        }
    }

    function applyPreset(name) {
        _view.name = name || _view.name
        const p = _view.presets[_view.name]
        rotAnim.stop()
        orbitCameraNode.position = p.nodePos
        orbitCamera.position     = p.camPos
        nodeRotX.to = p.nodeRot.x; nodeRotY.to = p.nodeRot.y; nodeRotZ.to = p.nodeRot.z
        rotAnim.start()
    }

    ParallelAnimation {
        id: rotAnim
        NumberAnimation { id: nodeRotX; target: orbitCameraNode; property: "eulerRotation.x"; duration: 200; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotY; target: orbitCameraNode; property: "eulerRotation.y"; duration: 200; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotZ; target: orbitCameraNode; property: "eulerRotation.z"; duration: 200; easing.type: Easing.InOutQuad }
    }

    // 保护选点信息面板
    EventGrabGuard {
        id: piGrabGuard
        guardedItem: pickInfoPanel
        active: pickInfoPanel.visible
    }

    // ── 3D 场景 ─────────────────────────────────────────────────
    View3D {
        id: pc3d
        anchors.fill: parent
        enabled: !piGrabGuard.blocking

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

        OrbitCameraController {
            id: orbitController
            origin: orbitCameraNode
            camera: orbitCamera
        }

        // ── 点云渲染 ──────────────────────────────────────────────
        Model {
            geometry: PointCloudGeometry {
                id: pcGeom
                source: "assets:/fused_full_cloud_4-1.pcd"
                colorMode: PointCloudGeometry.RGB
                onPointCountChanged: { if (pointCount > 0) view3DRoot.applyPreset() }
                Component.onCompleted: { if (pointCount > 0) view3DRoot.applyPreset() }
            }
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                vertexShader: "qrc:/qt/qml/pointcloud3d/shaders/pointcloud.vert"
                fragmentShader: "qrc:/qt/qml/pointcloud3d/shaders/pointcloud.frag"
                sourceBlend: CustomMaterial.SrcAlpha
                destinationBlend: CustomMaterial.OneMinusSrcAlpha
            }
        }

        // ── 选点标记 ──────────────────────────────────────────────
        Repeater3D {
            model: selectionModel
            delegate: Node {
                id: markerDelegate
                required property real sceneX
                required property real sceneY
                required property real sceneZ
                required property int  rawIdx
                required property int  ptId

                position: Qt.vector3d(sceneX, sceneY, sceneZ)
                readonly property bool isActive: markerDelegate.ptId === view3DRoot.activePtId
                readonly property real targetScreenPx: 60
                scale: {
                    const dx = position.x - orbitCamera.scenePosition.x
                    const dy = position.y - orbitCamera.scenePosition.y
                    const dz = position.z - orbitCamera.scenePosition.z
                    const depth = Math.sqrt(dx*dx + dy*dy + dz*dz)
                    if (depth < 0.001) return Qt.vector3d(0.01, 0.01, 0.01)
                    const s = targetScreenPx * depth
                        * Math.tan(orbitCamera.fieldOfView * Math.PI / 180.0 * 0.5)
                        / (pc3d.height * 0.5) / 100
                    return Qt.vector3d(s, s, s)
                }

                Model {
                    visible: markerDelegate.isActive
                    scale: Qt.vector3d(50, 50, 50)
                    geometry: CornerBracketGeometry {}
                    materials: CustomMaterial {
                        shadingMode: CustomMaterial.Unshaded
                        vertexShader: "qrc:/qt/qml/pointcloud3d/shaders/cornerbracket.vert"
                        fragmentShader: "qrc:/qt/qml/pointcloud3d/shaders/cornerbracket.frag"
                        property vector4d lineColor: Qt.vector4d(0.933, 0.376, 0.008, 1.0)
                    }
                }
                Model {
                    source: "#Sphere"
                    scale: Qt.vector3d(0.12, 0.12, 0.12)
                    materials: PrincipledMaterial {
                        baseColor:      markerDelegate.isActive ? "#FF6B1A" : "#E54304"
                        // 自发光因子
                        emissiveFactor: markerDelegate.isActive
                            ? Qt.vector3d(1.0, 0.42, 0.1)
                            : Qt.vector3d(0.898, 0.263, 0.016)
                    }
                }
            }
        }

        // ── 拾取 ─────────────────────────────────────────────────
        TapHandler {
            id: pickTap
            parent: pc3d
            enabled: leftToolbar.enableSelectPoint
            onTapped: (eventPoint) => {
                const pos = eventPoint.position
                const idx = pcGeom.pickPoint(
                    Qt.vector2d(pos.x, pos.y),
                    orbitCamera.scenePosition, orbitCamera.sceneRotation,
                    orbitCamera.fieldOfView, pc3d.width / pc3d.height,
                    orbitCamera.clipNear, orbitCamera.clipFar,
                    pc3d.width, pc3d.height, 48
                )
                if (idx < 0) { pickInfoPanel.activePtId = -1; return }

                const selIdx = view3DRoot.selectionIndexOf(idx)
                if (selIdx >= 0) {
                    const entry = selectionModel.get(selIdx)
                    pickInfoPanel.activePtId =
                        (view3DRoot.activePtId === entry.ptId) ? -1 : entry.ptId
                } else {
                    const scenePt = pcGeom.scenePointAt(idx)
                    const rawPt   = pcGeom.rawPointAt(idx)
                    const newId   = view3DRoot._nextPtId++
                    selectionModel.append({
                        ptId: newId, rawIdx: idx,
                        rawX: rawPt.x, rawY: rawPt.y, rawZ: rawPt.z,
                        sceneX: scenePt.x, sceneY: scenePt.y, sceneZ: scenePt.z
                    })
                    pickInfoPanel.activePtId = newId
                }
            }
        }
    }

    // ── 荧光光晕 ─────────────────────────────────────────────────
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
                    const e  = selectionModel.get(i)
                    const pt = pc3d.mapFrom3DScene(Qt.vector3d(e.sceneX, e.sceneY, e.sceneZ))
                    if (pt.x < 0 || pt.x > width || pt.y < 0 || pt.y > height) continue
                    const isAct = e.ptId === view3DRoot.activePtId
                    const grad  = ctx.createRadialGradient(pt.x, pt.y, 0, pt.x, pt.y, glowRadius)
                    if (isAct) {
                        grad.addColorStop(0.00, "rgba(255,140,0,0.55)")
                        grad.addColorStop(0.20, "rgba(255,100,0,0.30)")
                        grad.addColorStop(0.50, "rgba(255, 60,0,0.00)")
                    } else {
                        grad.addColorStop(0.00, "rgba(255,215,0,0.35)")
                        grad.addColorStop(0.15, "rgba(255,180,0,0.20)")
                        grad.addColorStop(0.30, "rgba(255,140,0,0.10)")
                        grad.addColorStop(0.50, "rgba(255,100,0,0.00)")
                    }
                    ctx.beginPath()
                    ctx.arc(pt.x, pt.y, glowRadius, 0, Math.PI * 2)
                    ctx.fillStyle = grad
                    ctx.fill()
                }
            }
        }
    }

    // ── 选点信息面板 ──────────────────────────────────────────────
    PickInfoPanel {
        id: pickInfoPanel
        model: selectionModel

        // ── 编辑面板（激活点时显示） ────────────────────────────────
        dpadItem: DPadPC {
            id: dpad

            ptId: {
                const selectedIndex = view3DRoot.modelIndexOfPtId(view3DRoot.activePtId)
                return  "#" + (selectedIndex+1)
            }

            onMoveUp: function(value) {
                view3DRoot.nudgeActivePoint(0, -value)
            }

            onMoveLeft: function(value) {
                view3DRoot.nudgeActivePoint(-value, 0)
            }

            onMoveRight: function(value) {
                view3DRoot.nudgeActivePoint(value, 0)
            }

            onMoveDown: function(value) {
                view3DRoot.nudgeActivePoint(0, value)
            }
        }
    }

    // ── 工具条遮罩 ────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: leftToolbar.anyGroupOpen
        onPressed: leftToolbar.closeGroups()
    }

    // ── 左侧工具条 ────────────────────────────────────────────────
    ToolbarPC {
        id: leftToolbar
        pcGeomAttrs.pointCount:      pcGeom.pointCount
        pcGeomAttrs.firstIntensity:  pcGeom.intensityMin
        pcGeomAttrs.secondIntensity: pcGeom.intensityMax

        onOperation: function(group, key, args) {
            switch (group) {
            case "color":
                pcGeom.colorMode = (key === "RGB") ? PointCloudGeometry.RGB : PointCloudGeometry.Intensity
                break
            case "view":
                view3DRoot.applyPreset(key)
                break
            case "filter":
                const value = args && args[0]
                if (key === "firstIntensity")       pcGeom.intensityMin = value || 0
                else if (key === "secondIntensity") pcGeom.intensityMax = value || 255
            }
        }
    }
}
