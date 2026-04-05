cmake_minimum_required(VERSION 3.16)

project(pointcloud3d VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Quick3D)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(apppointcloud3d
    main.cpp
)

set_source_files_properties(Components/AppTheme.qml Components/AppTools.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(apppointcloud3d
    URI pointcloud3d
    VERSION 1.0
    QML_FILES
        Main.qml
        Components/AppTheme.qml
        Components/AppTools.qml
    SOURCES
        AndroidUtils.h
        AndroidUtils.cpp
        CornerBracketGeometry.h
        CornerBracketGeometry.cpp
        PcdLoader.h
        PcdLoader.cpp
        PointCloudGeometry.h
        PointCloudGeometry.cpp
    RESOURCES
        shaders/pointcloud.frag
        shaders/pointcloud.vert
        shaders/cornerbracket.frag
        shaders/cornerbracket.vert
        icons/top_view.svg
        icons/right_view.svg
        icons/left_view.svg
        icons/intensity.svg
        icons/front_view.svg
        icons/back_view.svg
        icons/rgb.svg
        icons/pointcloud_filter.svg
    NO_RESOURCE_TARGET_PATH
    IMPORTS
        QtQuick3D
        QML_FILES Pages/View3DForPC.qml
)

set_property(TARGET apppointcloud3d APPEND PROPERTY
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(apppointcloud3d PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.apppointcloud3d
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


include(GNUInstallDirs)
install(TARGETS apppointcloud3d
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET apppointcloud3d
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
