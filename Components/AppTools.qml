pragma Singleton

import QtQuick

Item {
    /////////// 定时器 ////////////////
    function setTimeout(callback, delay = 1000) {
        var timer = Qt.createQmlObject(`
            import QtQuick
            Timer {
                property variant callback: null
                interval: ${delay}
                repeat: false
                running: false
                onTriggered: function() { callback && callback() }
            }
        `, Qt.application, "setTimeoutTimer");
        timer.callback = callback
        timer.running = true;
        return timer;
    }
}
