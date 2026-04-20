pragma Singleton

import QtQuick 2.15

import pointcloud3d 1.0

Item {
    id: appTheme

    enum Mode {
        Light = 0,
        Dark,
        Main
    }

    enum Dock {
        Top,
        Left,
        Right,
        Bottom,
        Manual
    }

    enum Direction {
        Horizontal,
        Vertical
    }

    component BaseT: QtObject {
        readonly property string black: "#000"
        readonly property string white: "#fff"
        readonly property string transparent: "transparent"
    }

    component TextT: QtObject {
        readonly property string primary: "#de000000"
        readonly property string secondary: "#99000000"
        readonly property string disabled: "#61000000"
    }

    component BackgroundT: QtObject {
        readonly property string paper: "#fff"
        readonly property string _default: "#fff"
    }

    component ActionT: QtObject {
        readonly property string active: "#8a000000"
        readonly property string hover: "#0a000000"
        readonly property string selected: "#14000000"
        readonly property string disabled: "#42000000"
        readonly property string disabledBackground:  "#1f000000"
        readonly property string focus: "#1f000000"
    }

    component GreyT: QtObject {
        readonly property string _50:  "#fafafa"
        readonly property string _100: "#f5f5f5"
        readonly property string _150: "#f1f1f1"
        readonly property string _200: "#eeeeee"
        readonly property string _300: "#e0e0e0"
        readonly property string _400: "#bdbdbd"
        readonly property string _500: "#9e9e9e"
        readonly property string _600: "#757575"
        readonly property string _700: "#616161"
        readonly property string _800: "#424242"
        readonly property string _900: "#212121"
        readonly property string a100:  "#f5f5f5"
        readonly property string a200:  "#eeeeee"
        readonly property string a400:  "#bdbdbd"
        readonly property string a700:  "#616161"
    }

    component GridLinesT: QtObject {
        readonly property string grid: "#CCCCCC"
        readonly property string line: "#4169E1"
        readonly property string startPoint: "#00FF00"
        readonly property string endPoint: "#FF0000"
        readonly property string selectShadow: "#0000FF"
        readonly property string transparent: "transparent"
    }

    component PaletteT: QtObject {
        property string primary
        property string secondary
        property string error
        property string warning
        property string info
        property string success
        property string selection
        readonly property BaseT base: BaseT {}
        readonly property string divider: "#1f000000"
        readonly property TextT text: TextT {}
        readonly property BackgroundT background: BackgroundT {}
        readonly property ActionT action: ActionT {}
        readonly property GreyT grey: GreyT {}
        readonly property GridLinesT gridline: GridLinesT {}
    }

    component Viewport: QtObject {
        property real headerHeight: 48
        property real footerHeight: 48
        readonly property real padding: 20
        readonly property real width: Screen.desktopAvailableWidth
        readonly property real height: Screen.desktopAvailableHeight
        readonly property real contentHeight: height - headerHeight - footerHeight
        readonly property real noFooterHeight: height - headerHeight
    }

    readonly property PaletteT palette: PaletteT {
        readonly property alias primary: _palette.primary
        readonly property alias secondary: _palette.secondary
        readonly property alias error: _palette.error
        readonly property alias warning: _palette.warning
        readonly property alias info: _palette.info
        readonly property alias success: _palette.success
        readonly property alias selection: _palette.selection
    }

    // 设置消息分类图标（Text 组件 TextFormat = AutoText | RichText）
    component TextIcon: QtObject {
        readonly property string success: {
            return `<font color="${AppTheme.palette.success}" size="4"><b>√&nbsp;&nbsp;</b></font>`
        }
        readonly property string info: {
            return `<font color="${AppTheme.palette.info}" size="4"><b>i&nbsp;&nbsp;</b></font>`
        }
        readonly property string warning: {
            return `<font color="${AppTheme.palette.warning}" size="4"><b>!&nbsp;&nbsp;</b></font>`
        }
        readonly property string error: {
            return `<font color="${AppTheme.palette.error}" size="4"><b>x&nbsp;&nbsp;</b></font>`
        }
    }

    readonly property TextIcon textIcon: TextIcon {}

    readonly property Viewport viewport: Viewport {}

    property int mode: AppTheme.Mode.Main

    QtObject {
        id: _palette

        property string primary: raw.primary.light
        property string secondary: raw.secondary.light
        property string error: raw.error.light
        property string warning: raw.warning.light
        property string info: raw.info.light
        property string success: raw.success.light
        property string selection: raw.selection.light

        readonly property variant raw: {
            "primary": {
                "main": "#1976d2",
                "light": "#42a5f5",
                "dark": "#1565c0"
            },
            "secondary": {
                "main": "#9c27b0",
                "light": "#ba68c8",
                "dark": "#7b1fa2"
            },
            "error": {
                "main": "#d32f2f",
                "light": "#ef5350",
                "dark": "#c62828"
            },
            "warning": {
                "main": "#ED6C02",
                "light": "#ff9800",
                "dark": "#e65100"
            },
            "info": {
                "main": "#0288d1",
                "light": "#03a9f4",
                "dark": "#01579b"
            },
            "success": {
                "main": "#2e7d32",
                "light": "#4caf50",
                "dark": "#1b5e20"
            },
            "selection": {
                "main": "#000080",
                "light": "#000080",
                "dark": "#0000B2"
            },
            "material": {
                "primary": "#E78518",
                "light": "#FFBC72",
                "warning": "#EA4335",
                "text": {
                  "main": "#D0D8D8",
                  "light": "white",
                  "dark": "#8A94A8",
                },
                "background": {
                  "main": "transparent",
                  "light": "#D0D8D8",
                  "dark": "#8A94A8",
                }
            },
        }

        function update() {
            const themeName = ["light", "dark", "main"][appTheme.mode] || "light"
            primary = raw.primary[themeName]
            secondary = raw.secondary[themeName]
            error = raw.error[themeName]
            warning = raw.warning[themeName]
            info = raw.info[themeName]
            success = raw.success[themeName]
            selection = raw.selection[themeName]
        }
    }

    function color(path, opacity) {
        const defaultColor = _palette.raw.primary.main

        const keys = path.split(".")
        let node = _palette.raw
        for (const key of keys) {
            if (node === undefined || node === null || typeof node !== "object") {
                return defaultColor
            }
            node = node[key]
        }
        if (node === undefined || node === null || typeof node !== "string") {
            return defaultColor
        }

        const hex = node.trim()

        if (opacity === undefined || opacity === null || opacity >= 1.0) {
            return hex
        }

        const r = parseInt(hex.slice(1, 3), 16) / 255
        const g = parseInt(hex.slice(3, 5), 16) / 255
        const b = parseInt(hex.slice(5, 7), 16) / 255
        const a = Math.max(0, Math.min(1, opacity))

        return Qt.rgba(r, g, b, a)
    }

    Component.onCompleted: {
        _palette.update()
        modeChanged.connect(function() {
            _palette.update()
        })
    }
}
