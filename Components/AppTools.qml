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

    // 按 objectName 或指定的回调方法查找组件（返回 null 或首个匹配的组件）
    function findComponent(root, nameOrCallback, listName = "children") {
        if (!root || !root.length) {
            return null
        }

        var stack = [].concat(root)

        var validate = null
        if (typeof nameOrCallback == "function") {
            validate = (cmpt) => nameOrCallback(cmpt)
        } else {
            validate = (cmpt) => cmpt.objectName == nameOrCallback
        }

        while(stack.length > 0) {
            const cmpt = stack.pop()
            if (validate(cmpt)) {
                return cmpt
            }

            if(cmpt[listName] && cmpt[listName].length > 0) {
                for (var i = 0; i < cmpt[listName].length; i++) {
                    if (validate(cmpt[listName][i])) {
                        return cmpt[listName][i]
                    }
                }
                stack = stack.concat(cmpt[listName])
            }
        }

        return null
    }
}
