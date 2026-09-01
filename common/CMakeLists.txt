find_package(Qt6 6.5 REQUIRED COMPONENTS Core)

add_library(windra-common STATIC
    WindraSettings.cpp
    WindraSettings.h
)

target_include_directories(windra-common PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(windra-common PUBLIC Qt6::Core)
set_target_properties(windra-common PROPERTIES POSITION_INDEPENDENT_CODE ON)
