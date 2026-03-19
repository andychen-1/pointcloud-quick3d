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

            readonly property var viewPresets: ({
                "front":  { ex:   0, ey:   0, ez: 0, px: 0, py: 0, pz: 10 },
                "back":   { ex:   0, ey: 180, ez: 0, px: 0, py: 0, pz: 10 },
                "left":   { ex:   0, ey: -90, ez: 0, px: 0, py: 0, pz: 10 },
                "right":  { ex:   0, ey:  90, ez: 0, px: 0, py: 0, pz: 10 },
                "top":    { ex: -90, ey:   0, ez: 0, px: 0, py: 0, pz: 10 }
            })

            ParallelAnimation {
                id: rotAnim
                NumberAnimation {
                    id: rotXTarget
                    target: orbitCameraNode
                    property: "eulerRotation.x"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: rotYTarget
                    target: orbitCameraNode
                    property: "eulerRotation.y"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: rotZTarget
                    target: orbitCameraNode
                    property: "eulerRotation.z"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: posXTarget
                    target: orbitCamera
                    property: "x"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: posYTarget
                    target: orbitCamera
                    property: "y"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: posZTarget
                    target: orbitCamera
                    property: "z"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }

            function applyPreset(name) {
                var p = viewPresets[name]
                if (p) {
                    rotAnim.stop()
                    rotXTarget.to = p.ex
                    rotYTarget.to = p.ey
                    rotZTarget.to = p.ez
                    posXTarget.to = p.px
                    posYTarget.to = p.py
                    posZTarget.to = p.pz
                    rotAnim.start()
                }
            }

            View3D {
                id: pc3d
                anchors.fill: parent

                environment: SceneEnvironment {
                    backgroundMode: SceneEnvironment.Color
                    clearColor: "#0d0d0f"
                }

                Node {
                    id: orbitCameraNode

                    eulerRotation: Qt.vector3d(view3DBox.viewPresets.front.ex,
                                               view3DBox.viewPresets.front.ey, view3DBox.viewPresets.front.ez)

                    PerspectiveCamera {
                        id: orbitCamera
                        clipNear: 0.01
                        clipFar:  2000.0
                        position: Qt.vector3d(view3DBox.viewPresets.front.px,
                                              view3DBox.viewPresets.front.py, view3DBox.viewPresets.front.pz)
                    }
                }

                // 轨迹球控制
                OrbitCameraController {
                    id: orbitController
                    origin: orbitCameraNode
                    camera: orbitCamera
                }

                // 点云模型
                Model {
                    id: pcModel

                    geometry: PointCloudGeometry {
                        id: pcGeom
                        source: "assets:/fused_full_cloud_4.pcd"
                        colorMode: PointCloudGeometry.RGB   // 或 .Intensity
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

            // 控制面板
            Column {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    anchors.bottomMargin: 16
                    spacing: 8

                    // 视角切换行
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Repeater {
                            model: [
                                { label: "前视", preset: "front"  },
                                { label: "后视", preset: "back"   },
                                { label: "左视", preset: "left"   },
                                { label: "右视", preset: "right"  },
                                { label: "俯视", preset: "top"    }
                            ]
                            Button {
                                required property string label
                                required property string preset
                                text: label
                                onClicked: view3DBox.applyPreset(preset)
                            }
                        }
                    }

                    // 颜色模式 + 点数显示行
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
