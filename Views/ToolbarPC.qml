pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: control
    z: 20
    anchors {
        left:           parent.left
        verticalCenter: parent.verticalCenter
        leftMargin:     60
    }
    width:  toolbarCol.width
    height: toolbarCol.height

    readonly property int   btnSize:    44
    readonly property int   iconSize:   26
    readonly property int   groupGap:   6
    readonly property int   colSpacing: 8
    readonly property real  bgAlpha:    0.78
    readonly property color accentColor: "#E57B04"

    property bool colorGroupOpen:    false
    property bool viewGroupOpen:     false
    property bool filterGroupOpen:   false
    property bool enableSelectPoint: false

    readonly property bool anyGroupOpen: colorGroupOpen || viewGroupOpen || filterGroupOpen

    component PCGeometryAttrs : QtObject{
        property int pointCount: 0
        property real minIntensity: 0
        property real maxIntensity: 255
        property real firstIntensity: minIntensity
        property real secondIntensity: maxIntensity
    }

    readonly property PCGeometryAttrs pcGeomAttrs: PCGeometryAttrs {}

    signal operation(group: string, key: string, args: var)

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

    property string activeColor: "RGB"
    property string activeView:  "back"

    Column {
        id: toolbarCol
        spacing: control.colSpacing

        // ══════════════════════════════════════════════════════
        // 选点切换按钮
        // ══════════════════════════════════════════════════════
        Rectangle {
            id: selPointBtn
            width:  control.btnSize
            height: control.btnSize
            radius: 10
            color:  control.enableSelectPoint
                    ? "#E78518"
                    : Qt.rgba(0.102, 0.11, 0.125, control.bgAlpha)
            Behavior on color { ColorAnimation { duration: 180 } }

            ToolButton {
                anchors.fill: parent
                icon.source:  "qrc:/qt/qml/pointcloud3d/icons/point_select.svg"
                icon.width:   control.iconSize
                icon.height:  control.iconSize
                icon.color:   control.enableSelectPoint ? "white" : "#B0B8C8"
                display:      AbstractButton.IconOnly
                background:   Item {}
                onClicked:    control.enableSelectPoint = !control.enableSelectPoint
            }
        }

        Item {
            width: control.btnSize
            height: control.btnSize / 2

            Rectangle {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                height: 1; color: Qt.rgba(1, 1, 1, 0.1)
            }
        }

        // ══════════════════════════════════════════════════════
        // 组 1：颜色模式
        // ══════════════════════════════════════════════════════
        Row {
            spacing: control.groupGap

            Rectangle {
                id: colorMainBtn
                width:  control.btnSize
                height: control.btnSize
                radius: 10
                color:  control.colorGroupOpen
                        ? "#E78518"
                        : Qt.rgba(0.102, 0.11, 0.125, control.bgAlpha)
                Behavior on color { ColorAnimation { duration: 180 } }

                property string currentIcon: {
                    switch (control.activeColor) {
                        case "RGB": return "qrc:/qt/qml/pointcloud3d/icons/rgb.svg"
                        case "Intensity": return "qrc:/qt/qml/pointcloud3d/icons/intensity.svg"
                    }
                }

                ToolButton {
                    anchors.fill: parent
                    icon.source:  parent.currentIcon
                    icon.width:   control.iconSize
                    icon.height:  control.iconSize
                    icon.color:   control.colorGroupOpen ? "white" : "#B0B8C8"
                    display:      AbstractButton.IconOnly
                    background:   Item {}
                    onClicked:    control.colorGroupOpen
                                  ? control.closeGroups()
                                  : control.openGroup("color")
                }
            }

            Row {
                spacing: control.groupGap
                visible: control.colorGroupOpen
                Rectangle {
                    width:  colorSubRow.width + 10
                    height: control.btnSize
                    radius: 10
                    color:  Qt.rgba(0.145, 0.157, 0.188, control.bgAlpha)
                    Row {
                        id: colorSubRow
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: [
                                { key: "RGB",       icon: "qrc:/qt/qml/pointcloud3d/icons/rgb.svg"       },
                                { key: "Intensity", icon: "qrc:/qt/qml/pointcloud3d/icons/intensity.svg" }
                            ]
                            delegate: Rectangle {
                                id: colorItem
                                required property var modelData
                                width:  control.btnSize
                                height: control.btnSize
                                radius: 8
                                color:  control.activeColor === colorItem.modelData.key
                                        ? Qt.rgba(0.898, 0.482, 0.016, 0.85) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                ToolButton {
                                    anchors.fill: parent
                                    icon.source:  colorItem.modelData.icon
                                    icon.width:   control.iconSize
                                    icon.height:  control.iconSize
                                    icon.color:   control.activeColor === colorItem.modelData.key
                                                  ? "white" : "#8A94A8"
                                    display: AbstractButton.IconOnly
                                    background: Item {}
                                    onClicked: {
                                        control.activeColor = colorItem.modelData.key
                                        operation("color", colorItem.modelData.key, [])
                                        control.closeGroups()
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
            spacing: control.groupGap

            Rectangle {
                id: viewMainBtn
                width:  control.btnSize
                height: control.btnSize
                radius: 10
                color:  control.viewGroupOpen
                        ? "#E78518"
                        : Qt.rgba(0.102, 0.11, 0.125, control.bgAlpha)
                Behavior on color { ColorAnimation { duration: 180 } }

                property string currentIcon: {
                    switch (control.activeView) {
                        case "front":  return "qrc:/qt/qml/pointcloud3d/icons/front_view.svg"
                        case "left":   return "qrc:/qt/qml/pointcloud3d/icons/left_view.svg"
                        case "right":  return "qrc:/qt/qml/pointcloud3d/icons/right_view.svg"
                        case "top":    return "qrc:/qt/qml/pointcloud3d/icons/top_view.svg"
                        case "bottom": return "qrc:/qt/qml/pointcloud3d/icons/bottom_view.svg"
                        default:       return "qrc:/qt/qml/pointcloud3d/icons/back_view.svg"
                    }
                }
                ToolButton {
                    anchors.fill: parent
                    icon.source:  viewMainBtn.currentIcon
                    icon.width:   control.iconSize
                    icon.height:  control.iconSize
                    icon.color:   control.viewGroupOpen ? "white" : "#B0B8C8"
                    display:      AbstractButton.IconOnly
                    background:   Item {}
                    onClicked:    control.viewGroupOpen
                                  ? control.closeGroups()
                                  : control.openGroup("view")
                }
            }

            Row {
                spacing: control.groupGap
                visible: control.viewGroupOpen
                Rectangle {
                    width:  viewSubRow.width + 10
                    height: control.btnSize
                    radius: 10
                    color:  Qt.rgba(0.145, 0.157, 0.188, control.bgAlpha)
                    Row {
                        id: viewSubRow
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: [
                                { key: "back",   icon: "qrc:/qt/qml/pointcloud3d/icons/back_view.svg"   },
                                { key: "front",  icon: "qrc:/qt/qml/pointcloud3d/icons/front_view.svg"  },
                                { key: "left",   icon: "qrc:/qt/qml/pointcloud3d/icons/left_view.svg"   },
                                { key: "right",  icon: "qrc:/qt/qml/pointcloud3d/icons/right_view.svg"  },
                                { key: "top",    icon: "qrc:/qt/qml/pointcloud3d/icons/top_view.svg"    },
                                { key: "bottom", icon: "qrc:/qt/qml/pointcloud3d/icons/bottom_view.svg" },
                            ]
                            delegate: Rectangle {
                                id: viewItem
                                required property var modelData
                                width:  control.btnSize
                                height: control.btnSize
                                radius: 8
                                color:  control.activeView === viewItem.modelData.key
                                        ? Qt.rgba(0.898, 0.482, 0.016, 0.85) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                ToolButton {
                                    anchors.fill: parent
                                    icon.source:  viewItem.modelData.icon
                                    icon.width:   control.iconSize
                                    icon.height:  control.iconSize
                                    icon.color:   control.activeView === viewItem.modelData.key
                                                  ? "white" : "#8A94A8"
                                    display: AbstractButton.IconOnly
                                    background: Item {}
                                    onClicked: {
                                        control.activeView = viewItem.modelData.key
                                        control.operation("view", viewItem.modelData.key, [])
                                        control.closeGroups()
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
            spacing: control.groupGap

            Rectangle {
                width:  control.btnSize
                height: control.btnSize
                radius: 10
                color:  control.filterGroupOpen
                        ? Qt.rgba(0.898, 0.482, 0.016, 0.92)
                        : Qt.rgba(0.102, 0.11, 0.125, control.bgAlpha)
                Behavior on color { ColorAnimation { duration: 180 } }
                ToolButton {
                    anchors.fill: parent
                    icon.source:  "qrc:/qt/qml/pointcloud3d/icons/pointcloud_filter.svg"
                    icon.width:   control.iconSize
                    icon.height:  control.iconSize
                    icon.color:   control.filterGroupOpen ? "white" : "#B0B8C8"
                    display:      AbstractButton.IconOnly
                    background:   Item {}
                    onClicked:    control.filterGroupOpen
                                  ? control.closeGroups()
                                  : control.openGroup("filter")
                }
            }

            Item {
                visible: control.filterGroupOpen
                width:   filterPanel.width
                height:  control.btnSize
                clip:    false

                Rectangle {
                    id: filterPanel
                    anchors.top: parent.top
                    width:  filterContent.width + 24
                    height: filterContent.height + 24
                    radius: 10
                    color:  Qt.rgba(0.145, 0.157, 0.188, control.bgAlpha)

                    Column {
                        id: filterContent
                        anchors.centerIn: parent
                        spacing: 14
                        width: 220

                        Row {
                            spacing: 8
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: "#4CAF50"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: "点数: " + control.pcGeomAttrs.pointCount
                                color: "#CCCCCC"
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 1
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        Column {
                            width: parent.width
                            spacing: 6

                            Row {
                                width: parent.width
                                Label {
                                    text: "反射率过滤"
                                    color: "#AAAAAA"
                                    font.pixelSize: 11
                                }
                                Item {
                                    width: parent.width
                                             - rangeValLabel.implicitWidth - 55
                                    height: 1
                                }
                                Label {
                                    id: rangeValLabel
                                    text: intensityRangeSlider.first.value.toFixed(0)
                                          + " – "
                                          + intensityRangeSlider.second.value.toFixed(0)
                                    color: control.accentColor
                                    font.pixelSize: 11
                                }
                            }

                            RangeSlider {
                                id: intensityRangeSlider
                                width:    parent.width
                                from:     control.pcGeomAttrs.minIntensity
                                to:       control.pcGeomAttrs.maxIntensity
                                stepSize: 1

                                Material.accent: control.accentColor

                                first.value:  control.pcGeomAttrs.firstIntensity
                                second.value: control.pcGeomAttrs.secondIntensity

                                first.onPressedChanged: {
                                    if (!first.pressed)
                                        control.operation("filter", "firstIntensity", [first.value])
                                }
                                second.onPressedChanged: {
                                    if (!second.pressed)
                                        control.operation("filter", "secondIntensity", [second.value])
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

