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

            // ── 视角预设 ─────────────
            readonly property var viewPresets: {
                // 相机FOV与缩放系数
                var kVFov = orbitCamera.fieldOfView
                var kMargin = 1.0

                // 包围盒派生量
                var midX = (pcGeom.boundsMin.x + pcGeom.boundsMax.x) * 0.5
                var midY = (pcGeom.boundsMin.y + pcGeom.boundsMax.y) * 0.5
                var midZ = (pcGeom.boundsMin.z + pcGeom.boundsMax.z) * 0.5
                var midZ1 = midZ - pcGeom.boundsMax.z

                return {
                    "back": {
                        nodePos: Qt.vector3d(0, 0, midZ),
                        nodeRot: Qt.vector3d(0, 0, 0),
                        camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Back, kVFov, kMargin))
                    },
                    "front": {
                        nodePos: Qt.vector3d(0, midY, midZ),
                        nodeRot: Qt.vector3d(0, 180, 0),
                        camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Front, kVFov, kMargin))
                    },
                    "left": {
                        nodePos: Qt.vector3d(0, midY, midZ),
                        nodeRot: Qt.vector3d(0, -90, 0),
                        camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Left, kVFov, kMargin))
                    },
                    "right": {
                        nodePos: Qt.vector3d(0, midY, midZ),
                        nodeRot: Qt.vector3d(0, 90, 0),
                        camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Right, kVFov, kMargin))
                    },
                    "top": {
                        nodePos: Qt.vector3d(0, 0, midZ),
                        nodeRot: Qt.vector3d(-90, 0, 0),
                        camPos: Qt.vector3d(0, 0, pcGeom.distanceOfCamera(PointCloudGeometry.Top, kVFov, kMargin))
                    }
                };
            }

            // ── 视角切换动画 ────────────────
            ParallelAnimation {
                id: rotAnim
                NumberAnimation { id: nodeRotX;  target: orbitCameraNode; property: "eulerRotation.x"; duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: nodeRotY;  target: orbitCameraNode; property: "eulerRotation.y"; duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: nodeRotZ;  target: orbitCameraNode; property: "eulerRotation.z"; duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: nodePosX;  target: orbitCameraNode; property: "position.x";      duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: nodePosY;  target: orbitCameraNode; property: "position.y";      duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: nodePosZ;  target: orbitCameraNode; property: "position.z";      duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: camPosX;   target: orbitCamera;     property: "x";               duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: camPosY;   target: orbitCamera;     property: "y";               duration: 400; easing.type: Easing.InOutQuad }
                NumberAnimation { id: camPosZ;   target: orbitCamera;     property: "z";               duration: 400; easing.type: Easing.InOutQuad }
            }

            function applyPreset(name) {
                var p = viewPresets[name]
                if (!p) return
                rotAnim.stop()
                nodePosX.to = p.nodePos.x
                nodePosY.to = p.nodePos.y
                nodePosZ.to = p.nodePos.z
                nodeRotX.to = p.nodeRot.x
                nodeRotY.to = p.nodeRot.y
                nodeRotZ.to = p.nodeRot.z
                camPosX.to  = p.camPos.x
                camPosY.to  = p.camPos.y
                camPosZ.to  = p.camPos.z
                rotAnim.start()
            }

            // ── 3D 场景 ────────────────────────────────────────────────
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
                    position: view3DRoot.viewPresets.back.nodePos
                    PerspectiveCamera {
                        id: orbitCamera
                        fieldOfView: 77.2
                        clipNear: 0.01
                        clipFar:  1000.0
                        position: view3DRoot.viewPresets.back?.camPos
                        onPositionChanged: {
                            console.log("orbitCamera position: ", position)
                        }
                    }
                    onPositionChanged: {
                        console.log("orbitCameraNode position: ", position)
                    }
                }

                OrbitCameraController {
                    id: orbitController
                    origin: orbitCameraNode
                    camera: orbitCamera
                }

                Model {
                    id: pcModel

                    geometry: PointCloudGeometry {
                        id: pcGeom
                        source: "assets:/fused_full_cloud_4-1.pcd"
                        colorMode: PointCloudGeometry.RGB
                        // intensityMin: 18
                    }

                    materials: CustomMaterial {
                        shadingMode: CustomMaterial.Unshaded
                        vertexShader: "shaders/pointcloud.vert"
                        fragmentShader: "shaders/pointcloud.frag"
                        sourceBlend: CustomMaterial.SrcAlpha
                        destinationBlend: CustomMaterial.OneMinusSrcAlpha
                    }
                }
            }

            DebugView {
                source: pc3d
            }

            // ── 控制面板 ───────────────────────────────────────────────
            Column {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                anchors.bottomMargin: 16
                spacing: 8

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "后视", preset: "back"  },
                            { label: "前视", preset: "front" },
                            { label: "左视", preset: "left"  },
                            { label: "右视", preset: "right" },
                            { label: "俯视", preset: "top"   }
                        ]
                        Button {
                            required property string label
                            required property string preset
                            text: label
                            onClicked: view3DRoot.applyPreset(preset)
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    height: 40

                    Button {
                        text: "RGB"
                        onClicked: pcGeom.colorMode = PointCloudGeometry.RGB
                    }
                    Button {
                        text: "Intensity"
                        onClicked: pcGeom.colorMode = PointCloudGeometry.Intensity
                    }

                    Label {
                        color: "white"
                        text: "点数: " + pcGeom.pointCount.toLocaleString()
                        verticalAlignment: Text.AlignVCenter
                    }

                    Label {
                        color: "white"
                        text: "强度 下限: " + intensityMinSlider.value.toFixed(0)
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
}
