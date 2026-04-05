pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import QtQuick3D
import QtQuick3D.Helpers

import pointcloud3d

Item {
    id: view3DRoot

    // ── 视角预设 ─────────────────────────────────────────────────────
    readonly property var viewPresets: {
        var kVFov   = orbitCamera.fieldOfView
        var kMargin = 1.0
        var midY = (pcGeom.boundsMin.y + pcGeom.boundsMax.y) * 0.5
        var midZ = (pcGeom.boundsMin.z + pcGeom.boundsMax.z) * 0.5
        return {
            "back":  { nodePos: Qt.vector3d(0, 0, midZ),    nodeRot: Qt.vector3d(0,    0, 0), camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Back,  kVFov, kMargin)) },
            "front": { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,  180, 0), camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Front, kVFov, kMargin)) },
            "left":  { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,  -90, 0), camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Left,  kVFov, kMargin)) },
            "right": { nodePos: Qt.vector3d(0, midY, midZ), nodeRot: Qt.vector3d(0,   90, 0), camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Right, kVFov, kMargin)) },
            "top":   { nodePos: Qt.vector3d(0, 0, midZ),    nodeRot: Qt.vector3d(-90,  0, 0), camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Top,   kVFov, kMargin)) }
        }
    }

    function applyPreset(name) {
        var p = viewPresets[name]
        if (!p) return
        rotAnim.stop()
        nodePosX.to = p.nodePos.x; nodePosY.to = p.nodePos.y; nodePosZ.to = p.nodePos.z
        nodeRotX.to = p.nodeRot.x; nodeRotY.to = p.nodeRot.y; nodeRotZ.to = p.nodeRot.z
        camPosX.to  = p.camPos.x;  camPosY.to  = p.camPos.y;  camPosZ.to  = p.camPos.z
        rotAnim.start()
    }

    // ── 视角切换动画 ─────────────────────────────────────────────────
    ParallelAnimation {
        id: rotAnim
        NumberAnimation { id: nodeRotX; target: orbitCameraNode; property: "eulerRotation.x"; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotY; target: orbitCameraNode; property: "eulerRotation.y"; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodeRotZ; target: orbitCameraNode; property: "eulerRotation.z"; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodePosX; target: orbitCameraNode; property: "position.x";      duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodePosY; target: orbitCameraNode; property: "position.y";      duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: nodePosZ; target: orbitCameraNode; property: "position.z";      duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: camPosX;  target: orbitCamera;     property: "x";               duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: camPosY;  target: orbitCamera;     property: "y";               duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { id: camPosZ;  target: orbitCamera;     property: "z";               duration: 400; easing.type: Easing.InOutQuad }
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
            eulerRotation: view3DRoot.viewPresets.back.nodeRot
            position:      view3DRoot.viewPresets.back.nodePos
            PerspectiveCamera {
                id: orbitCamera
                fieldOfView: 77.2
                clipNear: 0.01
                clipFar:  1000.0
                position: view3DRoot.viewPresets.back?.camPos
            }
        }

        OrbitCameraController {
            id: orbitController
            origin: orbitCameraNode
            camera: orbitCamera
        }

        // ── 点云渲染 ─────────────────────────────────────────────────
        Model {
            id: pcModel
            geometry: PointCloudGeometry {
                id: pcGeom
                source: "assets:/fused_full_cloud_4-1.pcd"
                colorMode: PointCloudGeometry.RGB
            }
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                vertexShader: "qrc:/shaders/pointcloud.vert"
                fragmentShader: "qrc:/shaders/pointcloud.frag"
                sourceBlend: CustomMaterial.SrcAlpha
                destinationBlend: CustomMaterial.OneMinusSrcAlpha
            }
        }

        // ── 拾取标记 ─────────────────────────────────────────────────
        Node {
            id: pickMarker
            visible: false
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

        // ── 触摸拾取 ─────────────────────────────────────────────────
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
                if (idx >= 0) {
                    const scenePt = pcGeom.scenePointAt(idx)
                    const rawPt   = pcGeom.rawPointAt(idx)
                    pickMarker.position = scenePt
                    pickMarker.visible  = true
                    pickInfoPanel.update(rawPt, scenePt)
                } else {
                    pickMarker.visible = false
                    pickInfoPanel.visible = false
                }
            }
        }

        // ── 坐标 HUD ─────────────────────────────────────────────────
        Rectangle {
            id: pickInfoPanel
            visible: false
            anchors { top: parent.top; right: parent.right; margins: 12 }
            width: 220; height: 80
            color: "#CC000000"; radius: 8

            function update(raw, scene) {
                rawLabel.text   = `X: ${raw.x.toFixed(3)}  Y: ${raw.y.toFixed(3)}  Z: ${raw.z.toFixed(3)}`
                sceneLabel.text = `sx: ${scene.x.toFixed(2)}  sy: ${scene.y.toFixed(2)}  sz: ${scene.z.toFixed(2)}`
                visible = true
            }
            Column {
                anchors { fill: parent; margins: 10 }
                spacing: 4
                Label { text: "选中点 (LiDAR 坐标)"; color: "#FFD700"; font.pixelSize: 11 }
                Label { id: rawLabel;   color: "white";   font.pixelSize: 11; font.family: "monospace" }
                Label { id: sceneLabel; color: "#AAAAAA"; font.pixelSize: 10; font.family: "monospace" }
            }
        }
    }

    // ── 荧光光晕叠加层 ───────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: pickMarker.visible
        enabled: false
        FrameAnimation {
            running: pickMarker.visible
            onTriggered: glowCanvas.requestPaint()
        }
        Canvas {
            id: glowCanvas
            anchors.fill: parent
            readonly property real glowRadius: 60
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var pt = pc3d.mapFrom3DScene(pickMarker.position)
                var cx = pt.x, cy = pt.y
                if (cx < 0 || cx > width || cy < 0 || cy > height) return
                var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, glowRadius)
                grad.addColorStop(0.0,  "rgba(255,215,  0,0.35)")
                grad.addColorStop(0.15, "rgba(255,180,  0,0.20)")
                grad.addColorStop(0.3,  "rgba(255,140,  0,0.10)")
                grad.addColorStop(0.5,  "rgba(255,100,  0,0.00)")
                ctx.beginPath()
                ctx.arc(cx, cy, glowRadius, 0, Math.PI * 2)
                ctx.fillStyle = grad
                ctx.fill()
            }
        }
    }

    // ── 全屏关闭遮罩 ──────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: 15
        visible: leftToolbar.anyGroupOpen
        onClicked: leftToolbar.closeGroups()
    }

    // ═══════════════════════════════════════════════════════════════
    // ── 左侧垂直浮动工具条 ───────────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: leftToolbar
        z: 20
        anchors {
            left:           parent.left
            verticalCenter: parent.verticalCenter
            leftMargin:     60
        }
        width:  toolbarCol.width
        height: toolbarCol.height

        // ── 共享样式常量 ────────────────────────────────────────────
        readonly property int   btnSize:    44
        readonly property int   iconSize:   26
        readonly property int   groupGap:   6
        readonly property int   colSpacing: 8
        readonly property real  bgAlpha:    0.78
        readonly property color accentColor: "#E57B04"

        // ── 展开状态（单选手风琴）──────────────────────────────────
        property bool colorGroupOpen:  false
        property bool viewGroupOpen:   false
        property bool filterGroupOpen: false

        readonly property bool anyGroupOpen: colorGroupOpen || viewGroupOpen || filterGroupOpen

        function closeGroups() {
            colorGroupOpen  = false
            viewGroupOpen   = false
            filterGroupOpen = false
        }

        function openGroup(name) {
            colorGroupOpen  = (name === "color")
            viewGroupOpen   = (name === "view")
            filterGroupOpen = (name === "filter")
        }

        // ── 各组激活状态记忆 ────────────────────────────────────────
        property string activeColor: "RGB"
        property string activeView:  "back"

        // ── 主列 ───────────────────────────────────────────────────
        Column {
            id: toolbarCol
            spacing: leftToolbar.colSpacing

            // ══════════════════════════════════════════════════════
            // 组 1：颜色模式
            // ══════════════════════════════════════════════════════
            Row {
                spacing: leftToolbar.groupGap

                Rectangle {
                    id: colorMainBtn
                    width:  leftToolbar.btnSize
                    height: leftToolbar.btnSize
                    radius: 10
                    color:  leftToolbar.colorGroupOpen
                            ? Qt.rgba(0.898, 0.482, 0.016, 0.92)
                            : Qt.rgba(0.102, 0.11, 0.125, leftToolbar.bgAlpha)
                    Behavior on color { ColorAnimation { duration: 180 } }


                    property string currentIcon: {
                        switch (leftToolbar.activeColor) {
                            case "RGB": return "qrc:/icons/rgb.svg"
                            case "Intensity": return "qrc:/icons/intensity.svg"
                        }
                    }

                    ToolButton {
                        anchors.fill: parent
                        icon.source:  parent.currentIcon
                        icon.width:   leftToolbar.iconSize
                        icon.height:  leftToolbar.iconSize
                        icon.color:   leftToolbar.colorGroupOpen ? "white" : "#B0B8C8"
                        display:      AbstractButton.IconOnly
                        background:   Item {}
                        onClicked:    leftToolbar.colorGroupOpen
                                      ? leftToolbar.closeGroups()
                                      : leftToolbar.openGroup("color")
                    }
                }

                Row {
                    spacing: leftToolbar.groupGap
                    visible: leftToolbar.colorGroupOpen
                    Rectangle {
                        width:  colorSubRow.width + 10
                        height: leftToolbar.btnSize
                        radius: 10
                        color:  Qt.rgba(0.145, 0.157, 0.188, leftToolbar.bgAlpha)
                        Row {
                            id: colorSubRow
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: [
                                    { key: "RGB",       icon: "qrc:/icons/rgb.svg"       },
                                    { key: "Intensity", icon: "qrc:/icons/intensity.svg" }
                                ]
                                delegate: Rectangle {
                                    id: colorItem
                                    required property var modelData
                                    width:  leftToolbar.btnSize
                                    height: leftToolbar.btnSize
                                    radius: 8
                                    color:  leftToolbar.activeColor === colorItem.modelData.key
                                            ? Qt.rgba(0.898, 0.482, 0.016, 0.85) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    ToolButton {
                                        anchors.fill: parent
                                        icon.source:  colorItem.modelData.icon
                                        icon.width:   leftToolbar.iconSize
                                        icon.height:  leftToolbar.iconSize
                                        icon.color:   leftToolbar.activeColor === colorItem.modelData.key
                                                      ? "white" : "#8A94A8"
                                        display: AbstractButton.IconOnly
                                        background: Item {}
                                        onClicked: {
                                            leftToolbar.activeColor = colorItem.modelData.key
                                            pcGeom.colorMode = (colorItem.modelData.key === "RGB")
                                                ? PointCloudGeometry.RGB
                                                : PointCloudGeometry.Intensity
                                            leftToolbar.closeGroups()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════
            // 组 2：视角切换
            // ══════════════════════════════════════════════════════
            Row {
                spacing: leftToolbar.groupGap

                Rectangle {
                    id: viewMainBtn
                    width:  leftToolbar.btnSize
                    height: leftToolbar.btnSize
                    radius: 10
                    color:  leftToolbar.viewGroupOpen
                            ? Qt.rgba(0.898, 0.482, 0.016, 0.92)
                            : Qt.rgba(0.102, 0.11, 0.125, leftToolbar.bgAlpha)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    property string currentIcon: {
                        switch (leftToolbar.activeView) {
                            case "front": return "qrc:/icons/front_view.svg"
                            case "left":  return "qrc:/icons/left_view.svg"
                            case "right": return "qrc:/icons/right_view.svg"
                            case "top":   return "qrc:/icons/top_view.svg"
                            default:      return "qrc:/icons/back_view.svg"
                        }
                    }
                    ToolButton {
                        anchors.fill: parent
                        icon.source:  viewMainBtn.currentIcon
                        icon.width:   leftToolbar.iconSize
                        icon.height:  leftToolbar.iconSize
                        icon.color:   leftToolbar.viewGroupOpen ? "white" : "#B0B8C8"
                        display:      AbstractButton.IconOnly
                        background:   Item {}
                        onClicked:    leftToolbar.viewGroupOpen
                                      ? leftToolbar.closeGroups()
                                      : leftToolbar.openGroup("view")
                    }
                }

                Row {
                    spacing: leftToolbar.groupGap
                    visible: leftToolbar.viewGroupOpen
                    Rectangle {
                        width:  viewSubRow.width + 10
                        height: leftToolbar.btnSize
                        radius: 10
                        color:  Qt.rgba(0.145, 0.157, 0.188, leftToolbar.bgAlpha)
                        Row {
                            id: viewSubRow
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: [
                                    { key: "back",  icon: "qrc:/icons/back_view.svg"  },
                                    { key: "front", icon: "qrc:/icons/front_view.svg" },
                                    { key: "left",  icon: "qrc:/icons/left_view.svg"  },
                                    { key: "right", icon: "qrc:/icons/right_view.svg" },
                                    { key: "top",   icon: "qrc:/icons/top_view.svg"   }
                                ]
                                delegate: Rectangle {
                                    id: viewItem
                                    required property var modelData
                                    width:  leftToolbar.btnSize
                                    height: leftToolbar.btnSize
                                    radius: 8
                                    color:  leftToolbar.activeView === viewItem.modelData.key
                                            ? Qt.rgba(0.898, 0.482, 0.016, 0.85) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    ToolButton {
                                        anchors.fill: parent
                                        icon.source:  viewItem.modelData.icon
                                        icon.width:   leftToolbar.iconSize
                                        icon.height:  leftToolbar.iconSize
                                        icon.color:   leftToolbar.activeView === viewItem.modelData.key
                                                      ? "white" : "#8A94A8"
                                        display: AbstractButton.IconOnly
                                        background: Item {}
                                        onClicked: {
                                            leftToolbar.activeView = viewItem.modelData.key
                                            view3DRoot.applyPreset(viewItem.modelData.key)
                                            leftToolbar.closeGroups()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════
            // 组 3：点云滤波面板
            // ══════════════════════════════════════════════════════
            Row {
                spacing: leftToolbar.groupGap

                // 主按钮
                Rectangle {
                    width:  leftToolbar.btnSize
                    height: leftToolbar.btnSize
                    radius: 10
                    color:  leftToolbar.filterGroupOpen
                            ? Qt.rgba(0.898, 0.482, 0.016, 0.92)
                            : Qt.rgba(0.102, 0.11, 0.125, leftToolbar.bgAlpha)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    ToolButton {
                        anchors.fill: parent
                        icon.source:  "qrc:/icons/pointcloud_filter.svg"
                        icon.width:   leftToolbar.iconSize
                        icon.height:  leftToolbar.iconSize
                        icon.color:   leftToolbar.filterGroupOpen ? "white" : "#B0B8C8"
                        display:      AbstractButton.IconOnly
                        background:   Item {}
                        onClicked:    leftToolbar.filterGroupOpen
                                      ? leftToolbar.closeGroups()
                                      : leftToolbar.openGroup("filter")
                    }
                }

                // 展开的滤波面板（纵向排列，顶部对齐主按钮）
                Item {
                    visible: leftToolbar.filterGroupOpen
                    width:   filterPanel.width
                    height:  filterPanel.height

                    Rectangle {
                        id: filterPanel
                        anchors.top: parent.top
                        width:  filterContent.width + 24
                        height: filterContent.height + 24
                        radius: 10
                        color:  Qt.rgba(0.145, 0.157, 0.188, leftToolbar.bgAlpha)

                        Column {
                            id: filterContent
                            anchors.centerIn: parent
                            spacing: 14
                            width: 220

                            // ── 点云数量 ──────────────────────────────────────────
                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: "#4CAF50"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Label {
                                    text: "点数: " + pcGeom.pointCount.toLocaleString()
                                    color: "#CCCCCC"
                                    font.pixelSize: 12
                                }
                            }

                            // 分割线
                            Rectangle {
                                width: parent.width; height: 1
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }

                            // ── 反射率区间（RangeSlider）─────────────────────────
                            Column {
                                width: parent.width
                                spacing: 6

                                // 标题行
                                Row {
                                    width: parent.width
                                    Label {
                                        text: "反射率"
                                        color: "#AAAAAA"
                                        font.pixelSize: 11
                                    }
                                    Item {
                                        width: parent.width
                                                 - rangeValLabel.implicitWidth - 55
                                        height: 1
                                    }
                                    // 实时显示当前区间值
                                    Label {
                                        id: rangeValLabel
                                        text: intensityRangeSlider.first.value.toFixed(0)
                                              + " – "
                                              + intensityRangeSlider.second.value.toFixed(0)
                                        color: leftToolbar.accentColor
                                        font.pixelSize: 11
                                    }
                                }

                                RangeSlider {
                                    id: intensityRangeSlider
                                    width:    parent.width
                                    from:     0
                                    to:       255
                                    stepSize: 1

                                    first.value:  pcGeom.intensityMin
                                    second.value: pcGeom.intensityMax

                                    // 松手后一次性提交，避免拖动中频繁重建点云
                                    first.onPressedChanged: {
                                        if (!first.pressed)
                                            pcGeom.intensityMin = first.value
                                    }
                                    second.onPressedChanged: {
                                        if (!second.pressed)
                                            pcGeom.intensityMax = second.value
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // ══════════════════════════════════════════════════════
        }
    }
    // ═══════════════════════════════════════════════════════════════
}

