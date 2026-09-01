find_package(Qt6 6.5 REQUIRED COMPONENTS Core Test)

function(windra_add_qt_test target)
    add_executable(${target} ${ARGN})
    target_include_directories(${target} PRIVATE
        ${PROJECT_SOURCE_DIR}/shell/src
    )
    target_link_libraries(${target} PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME ${target} COMMAND ${target})
endfunction()

windra_add_qt_test(windra-test-popup-controller
    tst_popupcontroller.cpp
    ${PROJECT_SOURCE_DIR}/shell/src/PopupController.cpp
    ${PROJECT_SOURCE_DIR}/shell/src/PopupController.h
)

windra_add_qt_test(windra-test-wifi-model
    tst_wifinetworkmodel.cpp
    ${PROJECT_SOURCE_DIR}/shell/src/WifiNetworkModel.cpp
    ${PROJECT_SOURCE_DIR}/shell/src/WifiNetworkModel.h
    ${PROJECT_SOURCE_DIR}/shell/src/NetworkBackend.h
)
