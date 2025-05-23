cmake_minimum_required(VERSION 3.16)

project(Checkers VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation directory" FORCE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(QT_QML_GENERATE_QMLLS_INI ON)
set(CMAKE_DISABLE_FIND_PACKAGE_WrapVulkanHeaders TRUE)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
    Multimedia
)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(${CMAKE_PROJECT_NAME}
    src/main.cpp
    resources/sounds/sounds.qrc
    resources/icons/icons.qrc
    resources/appicon.rc
)

set(QML_FILES
    qml/Main.qml
    qml/Board.qml
    qml/Piece.qml
)

set(QML_SINGLETONS
    qml/Singletons/GameLogic.qml
    qml/Singletons/AIPlayer.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)


qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI Odizinne.Checkers
    VERSION 1.0
    QML_FILES ${QML_FILES} ${QML_SINGLETONS}
)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
    Qt6::Quick
    Qt6::Multimedia
)

include(GNUInstallDirs)
install(TARGETS ${CMAKE_PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
qt_generate_deploy_qml_app_script(
    TARGET ${CMAKE_PROJECT_NAME}
    OUTPUT_SCRIPT deploy_script
    NO_TRANSLATIONS
    DEPLOY_TOOL_OPTIONS --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --skip-plugin-types imageformats,designer,iconengines,qmllint,generic,networkinformation,help,qmltooling,sqldrivers,tls,qmlls
)

install(SCRIPT ${deploy_script})
