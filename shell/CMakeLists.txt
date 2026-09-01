find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Qml Gui DBus)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(windra-shell
    src/main.cpp
    src/ShellBackend.cpp
    src/ShellBackend.h
    src/PopupController.cpp
    src/PopupController.h
    src/ProcessRunner.cpp
    src/ProcessRunner.h
    src/BatteryService.cpp
    src/BatteryService.h
    src/PowerProfilesService.cpp
    src/PowerProfilesService.h
    src/AudioBackend.cpp
    src/AudioBackend.h
    src/AudioService.cpp
    src/AudioService.h
    src/NetworkBackend.h
    src/NetworkManagerBackend.cpp
    src/NetworkManagerBackend.h
    src/NmcliBackend.cpp
    src/NmcliBackend.h
    src/MockNetworkBackend.cpp
    src/MockNetworkBackend.h
    src/WifiNetworkModel.cpp
    src/WifiNetworkModel.h
    src/NetworkService.cpp
    src/NetworkService.h
    src/ApplicationModel.cpp
    src/ApplicationModel.h
)

target_include_directories(windra-shell PRIVATE src)

qt_add_qml_module(windra-shell
    URI Windra.Shell
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/design/Theme.js
        qml/design/Format.js
        qml/controls/WindraPopup.qml
        qml/controls/WindraIconButton.qml
        qml/controls/WindraButton.qml
        qml/controls/WindraSlider.qml
        qml/controls/WindraToggle.qml
        qml/controls/WindraListItem.qml
        qml/controls/WindraSectionTitle.qml
        qml/controls/WindraTooltip.qml
        qml/controls/WindraTextField.qml
        qml/controls/BatteryIcon.qml
        qml/controls/VolumeIcon.qml
        qml/controls/WifiIcon.qml
        qml/controls/SignalBars.qml
        qml/controls/LockIcon.qml
        qml/components/AppTile.qml
        qml/components/BottomDock.qml
        qml/components/ClockPill.qml
        qml/components/SearchBox.qml
        qml/components/StatusIsland.qml
        qml/components/NotificationToast.qml
        qml/panels/LauncherPanel.qml
        qml/panels/PowerMenu.qml
        qml/panels/BatteryPopup.qml
        qml/panels/VolumePopup.qml
        qml/panels/WifiPopup.qml
        qml/panels/CalendarPopup.qml
        qml/panels/RunningAppsPopup.qml
    RESOURCES
        qml/assets/wallpaper/windra-meadow.png
        qml/assets/icons/power.svg
        qml/assets/icons/folder.svg
        qml/assets/icons/web.svg
        qml/assets/icons/notes.svg
        qml/assets/icons/calc.svg
        qml/assets/icons/apps.svg
        qml/assets/icons/settings.svg
        qml/assets/icons/wifi.svg
        qml/assets/icons/volume.svg
        qml/assets/icons/battery.svg
        qml/assets/icons/chevron.svg
        qml/assets/icons/search.svg
        qml/assets/icons/terminal.svg
)

target_link_libraries(windra-shell PRIVATE
    Qt6::Quick
    Qt6::Qml
    Qt6::Gui
    Qt6::DBus
    windra-common
)

install(TARGETS windra-shell RUNTIME DESTINATION bin)
