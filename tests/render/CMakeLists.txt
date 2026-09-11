find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Qml Gui)

qt_add_executable(windra-render-test
    main.cpp
)

target_link_libraries(windra-render-test PRIVATE
    Qt6::Quick
    Qt6::Qml
    Qt6::Gui
)

set_target_properties(windra-render-test PROPERTIES
    WIN32_EXECUTABLE FALSE
)
