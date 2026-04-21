pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import pointcloud3d

Rectangle {
    id: control
    anchors.fill: parent
    color: "transparent"
    clip: true

    component Step: QtObject {
        readonly property Label label: stepLabel
        readonly property Slider slider: stepSlider
    }

    readonly property Step step: Step{}

    property string ptId: ""

    signal moveLeft(step: real)
    signal moveRight(step: real)
    signal moveUp(step: real)
    signal moveDown(step: real)

    // 顶部色条——编辑模式指示 ────────────────────────────────
    Rectangle {
        id: colorBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 4;
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#FF4500" }
            GradientStop { position: 1.0; color: "#E57B04" }
        }
    }

    Rectangle {
        anchors {
            top: colorBar.bottom
            left: colorBar.left
        }
        width: 40
        height: 20
        bottomRightRadius: 10
        color: "#FF4500"
        z: 10

        Label {
            text: control.ptId
            color: "#D0D8D8"; font.pixelSize: 12; font.bold: true
            anchors {
                top:  parent.top
                left: parent.left
                leftMargin: 4
                verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── D-pad + 步长 ─────────────────────────────────────
    Row {
        id: controlRow
        spacing: 20
        anchors {
            top: colorBar.bottom
            topMargin: 8
            horizontalCenter: parent.horizontalCenter
        }

        // ── 左侧：D-pad ──────────────────────────────────
        Grid {
            columns: 3; rows: 3; spacing: 4
            Item { width: 40; height: 40 }
            DPadButton { text: "▲"; onPressed: control.moveUp(stepSlider.value) }
            Item { width: 40; height: 40 }
            DPadButton { text: "◀"; onPressed: control.moveLeft(stepSlider.value) }
            Rectangle {
                width: 40; height: 40; radius: 20
                color: Qt.rgba(1, 1, 1, 0.06)
                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#E57B04" }
            }
            DPadButton { text: "▶"; onPressed: control.moveRight(stepSlider.value) }
            Item { width: 40; height: 40 }
            DPadButton { text: "▼"; onPressed: control.moveDown(stepSlider.value)}
            Item { width: 40; height: 40 }
        }

        // ── 右侧：步长设置 ──────────────────────────────────
        Column {
            width: 80
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            // 当前数值显示
            Label {
                id: stepLabel
                text: "步长：" + stepSlider.value.toFixed(0)
                color: "#E57B04"
                font.pixelSize: 12
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Slider {
                id: stepSlider
                height: 100
                orientation: Qt.Vertical
                from: 1
                to: 10
                stepSize: 1
                value: 1
                Material.accent: "#E57B04"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
