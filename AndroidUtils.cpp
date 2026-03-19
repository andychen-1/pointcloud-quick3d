#include "AndroidUtils.h"
#include <QtCore/private/qandroidextras_p.h>

AndroidUtils::AndroidUtils(QObject *parent)
    : QObject{parent}
{}

void AndroidUtils::setFullscreen(bool enabled)
{
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([enabled]() {
        QJniObject activity = QNativeInterface::QAndroidApplication::context();

        QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
        QJniObject decorView = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
        QJniObject layoutParams = window.callObjectMethod("getAttributes", "()Landroid/view/WindowManager$LayoutParams;");

        if (enabled) {
            // 设置内容钻进刘海区 (LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES = 1)
            layoutParams.setField<int>("layoutInDisplayCutoutMode", 1);
            // 构造沉浸式 Flags (系统 UI 标志)
            // 0x00001000: IMMERSIVE_STICKY
            // 0x00000400: LAYOUT_FULLSCREEN
            // 0x00000200: LAYOUT_HIDE_NAVIGATION
            // 0x00000100: LAYOUT_STABLE
            // 0x00000004: FULLSCREEN
            // 0x00000002: HIDE_NAVIGATION
            decorView.callMethod<void>("setSystemUiVisibility", "(I)V", 0x1706);
        } else {
            // 恢复默认刘海策略 (LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT = 0)
            layoutParams.setField<int>("layoutInDisplayCutoutMode", 0);
            // 清除所有全屏标志位
            decorView.callMethod<void>("setSystemUiVisibility", "(I)V", 0);
        }
        window.callMethod<void>("setAttributes", "(Landroid/view/WindowManager$LayoutParams;)V", layoutParams.object());
    });
}

void AndroidUtils::setOrientation(int orientation)
{
    // 必须在 Android 主线程执行
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([orientation]() {
        QJniObject activity = QNativeInterface::QAndroidApplication::context();
        if (activity.isValid()) {
            // 调用 Activity.setRequestedOrientation(int orientation)
            activity.callMethod<void>("setRequestedOrientation", "(I)V", orientation);
        }
    });
}
