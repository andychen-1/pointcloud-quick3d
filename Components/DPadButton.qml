import QtQuick
import QtQuick.Controls

Rectangle {
    id: control

    default property alias contentItem: contentItem.children

    property string text: ""
    signal pressed()

    width: 40; height: 40; radius: 8
    color: holdArea.containsPress ? "#E78518" : Qt.rgba(1, 1, 1, 0.10)
    Behavior on color { ColorAnimation { duration: 80 } }

    Item {
        id: contentItem
        anchors.fill: parent

        Label {
            anchors.centerIn: parent
            text: control.text; color: "#B0B8C8"; font.pixelSize: 16
        }
    }

    // 初始延迟计时器（首次触发后等待一段时间再开始连发）
    Timer {
        id: initialDelay
        interval: 400                           // 首次按下后 400ms 开始连发
        repeat: false
        onTriggered: repeatTimer.start()
    }

    // 连发计时器（带加速）
    Timer {
        id: repeatTimer
        interval: 200                           // 初始连发间隔 200ms
        repeat: true
        onTriggered: {
            control.pressed()
            // 加速：每次触发后缩短间隔，最快 40ms
            interval = Math.max(40, interval * 0.80)
        }
    }

    MouseArea {
        id: holdArea
        anchors.fill: parent

        onPressed: {
            control.pressed()                   // 立即触发一次
            repeatTimer.interval = 200          // 重置加速状态
            initialDelay.start()
        }

        onReleased: {
            initialDelay.stop()
            repeatTimer.stop()
        }

        onCanceled: {                           // 手指滑出时也要停止
            initialDelay.stop()
            repeatTimer.stop()
        }
    }
}

