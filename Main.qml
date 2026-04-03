pragma ComponentBehavior: Bound

import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick.Controls

import pointcloud3d

Window {
    id: mainWin
    title: "LiDAR Point Cloud Viewer"

    readonly property bool isLandscape: {
        return Screen.orientation === Qt.LandscapeOrientation ||
        Screen.orientation === Qt.InvertedLandscapeOrientation
    }

    Component.onCompleted: {
        AndroidUtils.setFullscreen(true)
        AppTools.setTimeout(() => {
            AndroidUtils.setOrientation(0)
            mainWin.visibility = Window.FullScreen
        }, 200)
    }

    Loader {
        anchors.fill: parent
        active: mainWin.isLandscape
        sourceComponent: view3DComponent
    }

    Component {
        id: view3DComponent

        Item {
            id: view3DRoot

            // ── 视角预设 ────────────────────
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

            // ── 视角切换动画 ─────────────────
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

            function applyPreset(name) {
                var p = viewPresets[name]
                if (!p) return
                rotAnim.stop()
                nodePosX.to = p.nodePos.x; nodePosY.to = p.nodePos.y; nodePosZ.to = p.nodePos.z
                nodeRotX.to = p.nodeRot.x; nodeRotY.to = p.nodeRot.y; nodeRotZ.to = p.nodeRot.z
                camPosX.to  = p.camPos.x;  camPosY.to  = p.camPos.y;  camPosZ.to  = p.camPos.z
                rotAnim.start()
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
                        onPositionChanged: console.log("orbitCamera position:", position)
                    }
                    onPositionChanged: console.log("orbitCameraNode position:", position)
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
                        vertexShader: "shaders/pointcloud.vert"
                        fragmentShader: "shaders/pointcloud.frag"
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
                            vertexShader: "shaders/cornerbracket.vert"
                            fragmentShader: "shaders/cornerbracket.frag"
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

            // ═══════════════════════════════════════════════════════════════
            // ── 左侧垂直浮动工具条 ────────────────────────────────────────────
            // ═══════════════════════════════════════════════════════════════
            Item {
                id: leftToolbar
                z: 20
                anchors {
                    left:           parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin:     40
                }

                // 动态宽高跟随内容
                width:  toolbarCol.width
                height: toolbarCol.height

                // ── 共享样式常量 ────────────────────────────────────────────
                readonly property int  btnSize:   44          // 按钮边长
                readonly property int  iconSize:  26          // 图标边长
                readonly property int  groupGap:  6           // 组内按钮间距
                readonly property int  colSpacing: 8          // 组间纵向间距
                readonly property real bgAlpha:  0.78         // 背景透明度
                readonly property color bgColor: "#1A1C20"
                readonly property color accentColor: "#E57B04"
                readonly property color subBgColor:  "#252830"

                // ── 展开状态 ────────────────────────────────────────────────
                property bool colorGroupOpen: false
                property bool viewGroupOpen:  false

                // ── 颜色模式状态 ────────────────────────────────────────────
                property string activeColor: "RGB"     // "RGB" | "Intensity"

                // ── 视角状态 ────────────────────────────────────────────────
                property string activeView: "back"

                function closeGroups() {
                    colorGroupOpen = false;
                    viewGroupOpen = false;
                }

                // ── 主列（纵向排列两个功能组）──────────────────────────────────
                Column {
                    id: toolbarCol
                    spacing: leftToolbar.colSpacing

                    // ──────────────────────────────────────────────────────
                    // 功能组 1：颜色模式
                    // ──────────────────────────────────────────────────────
                    Row {
                        id: colorGroupRow
                        spacing: leftToolbar.groupGap
                        layoutDirection: Qt.LeftToRight

                        // ▶ 颜色模式主按钮
                        Rectangle {
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
                                background: Item {}
                                onClicked: {
                                    leftToolbar.colorGroupOpen = true
                                    leftToolbar.viewGroupOpen = false
                                }
                            }
                        }

                        // ▶ 展开的子按钮组（RGB / Intensity）
                        Row {
                            spacing: leftToolbar.groupGap
                            visible: leftToolbar.colorGroupOpen
                            clip:    true

                            // 背景胶囊
                            Rectangle {
                                id: colorSubBg
                                width:  colorSubRow.width  + 10
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
                                            id: colorBC

                                            required property var modelData
                                            width:  leftToolbar.btnSize
                                            height: leftToolbar.btnSize
                                            radius: 8
                                            color:  leftToolbar.activeColor === modelData.key
                                                    ? Qt.rgba(0.898, 0.482, 0.016, 0.85)
                                                    : "transparent"

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            ToolButton {
                                                anchors.fill: parent
                                                icon.source:  colorBC.modelData.icon
                                                icon.width:   leftToolbar.iconSize
                                                icon.height:  leftToolbar.iconSize
                                                icon.color:   leftToolbar.activeColor === colorBC.modelData.key
                                                              ? "white" : "#8A94A8"
                                                display: AbstractButton.IconOnly
                                                background: Item {}
                                                onClicked: {
                                                    leftToolbar.activeColor = colorBC.modelData.key
                                                    pcGeom.colorMode = (modelData.key === "RGB")
                                                        ? PointCloudGeometry.RGB
                                                        : PointCloudGeometry.Intensity
                                                    leftToolbar.colorGroupOpen = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ──────────────────────────────────────────────────────
                    // 功能组 2：视角切换
                    // ──────────────────────────────────────────────────────
                    Row {
                        id: viewGroupRow
                        spacing: leftToolbar.groupGap
                        layoutDirection: Qt.LeftToRight

                        // ▶ 视角主按钮（图标随当前视角变化）
                        Rectangle {
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
                                icon.source:  parent.currentIcon
                                icon.width:   leftToolbar.iconSize
                                icon.height:  leftToolbar.iconSize
                                icon.color:   leftToolbar.viewGroupOpen ? "white" : "#B0B8C8"
                                display:      AbstractButton.IconOnly
                                background: Item {}
                                onClicked: {
                                    leftToolbar.viewGroupOpen = true
                                    leftToolbar.colorGroupOpen = false
                                }
                            }
                        }

                        // ▶ 展开的子按钮组（5 个视角）
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
                                            id: viewBC

                                            required property var modelData
                                            width:  leftToolbar.btnSize
                                            height: leftToolbar.btnSize
                                            radius: 8
                                            color:  leftToolbar.activeView === modelData.key
                                                    ? Qt.rgba(0.898, 0.482, 0.016, 0.85)
                                                    : "transparent"

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            ToolButton {
                                                anchors.fill: parent
                                                icon.source:  viewBC.modelData.icon
                                                icon.width:   leftToolbar.iconSize
                                                icon.height:  leftToolbar.iconSize
                                                icon.color:   leftToolbar.activeView === viewBC.modelData.key
                                                              ? "white" : "#8A94A8"
                                                display: AbstractButton.IconOnly
                                                background: Item {}
                                                onClicked: {
                                                    leftToolbar.activeView = viewBC.modelData.key
                                                    view3DRoot.applyPreset(modelData.key)
                                                    leftToolbar.viewGroupOpen = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // ═══════════════════════════════════════════════════════════════

            // ── 底部辅助信息条（点数 + 强度滤波滑条）───────────────────────
            Row {
                anchors {
                    bottom:             parent.bottom
                    horizontalCenter:   parent.horizontalCenter
                    bottomMargin:       16
                }
                spacing: 12
                height: 40

                Label {
                    color: "white"
                    text: "点数: " + pcGeom.pointCount.toLocaleString()
                    verticalAlignment: Text.AlignVCenter
                }

                Label {
                    color: "white"
                    text: "强度下限: " + intensityMinSlider.value.toFixed(0)
                    verticalAlignment: Text.AlignVCenter
                    width: 90
                }

                Slider {
                    id: intensityMinSlider
                    from: 0; to: 255; value: pcGeom.intensityMin; stepSize: 1
                    onPressedChanged: {
                        if (!pressed)
                            pcGeom.intensityMin = value
                    }
                }
            }
        }
    }
}
