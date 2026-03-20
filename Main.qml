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
            id: view3DBox

            // ── 包围盒派生量 ───────────────────────────────────────────
            readonly property vector3d pcCenter: Qt.vector3d(
                (pcGeom.boundsMin.x + pcGeom.boundsMax.x) * 0.5,
                (pcGeom.boundsMin.y + pcGeom.boundsMax.y) * 0.5,
                (pcGeom.boundsMin.z + pcGeom.boundsMax.z) * 0.5
            )

            readonly property real vDistance: {
                var dx = pcGeom.boundsMax.x - pcGeom.boundsMin.x
                var dy = pcGeom.boundsMax.y - pcGeom.boundsMin.y
                var dz = pcGeom.boundsMax.z - pcGeom.boundsMin.z
                return Math.sqrt(dx*dx + dy*dy + dz*dz) * 0.45
            }

            // ── 视角预设（仅旋转角，距离统一用 viewDist）─────────────
            readonly property var viewPresets: ({
                "front": { rx:   0, ry:   0 },
                "back":  { rx:   0, ry: 180 },
                "left":  { rx:   0, ry: -90 },
                "right": { rx:   0, ry:  90 },
                "top":   { rx: -90, ry:   0 }
            })

            // ── 视角切换动画（只动旋转角和摄像机距离）────────────────
            ParallelAnimation {
                id: rotAnim

                NumberAnimation {
                    id: rotXAnim
                    target: orbitCameraNode; property: "eulerRotation.x"
                    duration: 400; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: rotYAnim
                    target: orbitCameraNode; property: "eulerRotation.y"
                    duration: 400; easing.type: Easing.InOutQuad
                }
            }

            function applyPreset(name) {
                var p = viewPresets[name]

                rotAnim.stop()

                rotXAnim.to = p.rx
                rotYAnim.to = p.ry

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
                    eulerRotation: Qt.vector3d(0, 0, 0)
                    position: view3DBox.pcCenter
                    PerspectiveCamera {
                        id: orbitCamera
                        clipNear: 0.01
                        clipFar:  2000.0
                        x: 0
                        y: 0
                        z: view3DBox.vDistance
                    }
                    onPositionChanged: {
                        console.log("orbitCameraNode position: ", position);
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
                            { label: "前视", preset: "front" },
                            { label: "后视", preset: "back"  },
                            { label: "左视", preset: "left"  },
                            { label: "右视", preset: "right" },
                            { label: "俯视", preset: "top"   }
                        ]
                        Button {
                            required property string label
                            required property string preset
                            text: label
                            onClicked: view3DBox.applyPreset(preset)
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

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
                }
            }
        }
    }
}
