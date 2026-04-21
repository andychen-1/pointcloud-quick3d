cmake_minimum_required(VERSION 3.16)
project(pointcloud3d VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Quick3D)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(apppointcloud3d
    main.cpp
)

set_source_files_properties(
    Components/AppTheme.qml
    Components/AppTools.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(apppointcloud3d
    URI pointcloud3d
    VERSION 1.0
    QML_FILES
        Main.qml
        Components/AppTheme.qml
        Components/AppTools.qml
        Components/DPadButton.qml
        Views/DPadPC.qml
        Views/ToolbarPC.qml
        Views/View3DPC.qml
        Views/PickInfoPanel.qml
        Views/AxisIndicator.qml
    SOURCES
        AndroidUtils.h AndroidUtils.cpp
        CornerBracketGeometry.h CornerBracketGeometry.cpp
        PcdLoader.h PcdLoader.cpp
        PointCloudGeometry.h PointCloudGeometry.cpp
        EventGrabGuard.h EventGrabGuard.cpp
    RESOURCES
        shaders/pointcloud.vert shaders/pointcloud.frag
        shaders/cornerbracket.vert shaders/cornerbracket.frag
        icons/top_view.svg icons/bottom_view.svg
        icons/right_view.svg icons/left_view.svg
        icons/intensity.svg icons/front_view.svg
        icons/back_view.svg icons/rgb.svg icons/dpad.svg
        icons/pointcloud_filter.svg icons/close.svg icons/point_select.svg
    IMPORTS
        QtQuick
        QtQuick.Controls
        QtQuick.Controls.Material
        QtQuick3D
)

set_property(TARGET apppointcloud3d APPEND PROPERTY
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
)

set_target_properties(apppointcloud3d PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(apppointcloud3d PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Quick
    Qt::Quick3D
)
