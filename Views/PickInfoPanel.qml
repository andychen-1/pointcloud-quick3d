pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import pointcloud3d

Rectangle {
    id: control
    z: 10
    anchors { top: parent.top; right: parent.right; bottom: parent.bottom
              topMargin: 20; rightMargin: 20; bottomMargin: 20 }
    width: 280
    color: "#20808080";
    radius: 8
    visible: model?.count > 0

    required property ListModel model

    property int activePtId: -1
    property alias dpadItem: dpadCtr.children

    property bool showEditor: false
    property int editorHeight: 150

    signal clearAll()

    Component.onCompleted: {
        if (dpadCtr.children && dpadCtr.children.length > 0) {
            const dpad = AppTools.findComponent(dpadCtr.children, (child)=> child instanceof DPadPC)
            if (dpad) {
                dpad.anchors.fill = dpadCtr
            }
        }
    }

    Row {
        id: headerRow
        anchors { top: parent.top; left: parent.left; right: parent.right
                  topMargin: 8; leftMargin: 8; rightMargin: 8 }
        height: 28
        Label {
            text: {
                if (control.model) {
                    return "选中点  (" + control.model.count + ")"
                }
                return ""
            }
            color: "#E57B04"; font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
        Item { width: parent.width - clearAllBtn.implicitWidth - 90; height: 1 }
        ToolButton {
            id: clearAllBtn
            anchors.verticalCenter: parent.verticalCenter
            onClicked: { control.model?.clear(); control.activePtId = -1; control.clearAll() }
            contentItem: Label {
                text: "清除全部"; color: "#FF4500"; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: clearAllBtn.pressed ? "#80FF4500" : "transparent"; radius: 4 }
        }
    }

    Rectangle {
        id: piDivider
        anchors { top: headerRow.bottom; left: parent.left; right: parent.right; topMargin: 8 }
        height: 1; color: Qt.rgba(1, 1, 1, 0.1)
    }

    ListView {
        id: selListView
        anchors {
            top: piDivider.bottom; left: parent.left; right: parent.right
            leftMargin: 8; rightMargin: 8; topMargin: 8
        }
        height: parent.height - headerRow.height - piDivider.height -
                (dpadCtr.height > 0 ? dpadCtr.height + 8 : 0) - 31
        clip: true
        model: control.model
        delegate: Rectangle {
            id: selItem
            required property int  index
            required property int  rawIdx
            required property real rawX
            required property real rawY
            required property real rawZ
            required property int  ptId

            readonly property bool isActive: selItem.ptId === control.activePtId
            width: ListView.view.width; height: 54
            color:  index % 2 === 0 ? Qt.rgba(1,1,1,0.04) : "transparent"
            border.color: selItem.isActive ? "#EBE57B04" : "transparent"
            border.width: 1; radius: 4

            onIsActiveChanged: {
                if (!isActive) {
                    editBtn.toggle = false
                    control.showEditor = false
                }
            }

            TapHandler {
                onTapped: {
                    control.activePtId =
                        (control.activePtId === selItem.ptId) ? -1 : selItem.ptId
                }
            }

            Label {
                id: idxLabel
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                text: "#" + (selItem.index + 1)
                color: selItem.isActive ? "#D0D8D8" : "#B0B8C8"
                font.pixelSize: 13; font.bold: true; width: 22
            }

            Column {
                anchors {
                    left: idxLabel.right; leftMargin: 4
                    right: removeBtn.left; rightMargin: 4
                    verticalCenter: parent.verticalCenter
                }
                spacing: 3
                Label {
                    text: "X: " + selItem.rawX.toFixed(3) + "   Y: " + selItem.rawY.toFixed(3)
                    color: selItem.isActive ? "#D0D8D8" : "#B0B8C8"
                    font.pixelSize: 12; font.family: "monospace"
                }
                Label {
                    text: "Z: " + selItem.rawZ.toFixed(3)
                    color: selItem.isActive ? "#999" : "#666"
                    font.pixelSize: 12; font.family: "monospace"
                }
            }

            RoundButton {
                id: editBtn
                property bool toggle: false
                anchors { right: parent.right; rightMargin: 44; verticalCenter: parent.verticalCenter }
                width: 28; height: 28
                onClicked: {
                    control.activePtId = selItem.ptId
                    toggle = !toggle
                    control.showEditor = toggle
                }
                display: AbstractButton.IconOnly
                icon.source: "qrc:/qt/qml/pointcloud3d/icons/dpad.svg"
                icon.color: toggle && selItem.ptId === control.activePtId ? "#FF6060" : "#B0B8C8"
                icon.width: width; icon.height: height; padding: 4
                background: Rectangle {
                    anchors.fill: parent
                    color: editBtn.pressed ? "#22FF0000" : "transparent"; radius: 14
                }
            }

            RoundButton {
                id: removeBtn
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                width: 28; height: 28
                onClicked: {
                    if (control.activePtId === selItem.ptId) control.activePtId = -1
                    control.model?.remove(selItem.index)
                }
                display: AbstractButton.IconOnly
                icon.source: "qrc:/qt/qml/pointcloud3d/icons/close.svg"
                icon.color: pressed ? "#FF6060" : "#B0B8C8"
                icon.width: width; icon.height: height; padding: 4
                background: Rectangle {
                    anchors.fill: parent
                    color: removeBtn.pressed ? "#22FF0000" : "transparent"; radius: 14
                }
            }
        }
    }

    Item {
        id: dpadCtr
        anchors {
            bottom: parent.bottom; left: parent.left; right: parent.right;
        }
        clip: true
        height: control.showEditor && control.activePtId >= 0 ? control.editorHeight : 0

        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad // 添加缓动效果更平滑
            }
        }
    }
}
