cmake_minimum_required(VERSION 3.27)

project(hyprbars-macos
  DESCRIPTION "macOS-style title bars with traffic lights for Hyprland"
  VERSION 0.1.0
  LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)

set(SRC main.cpp barDeco.cpp BarPassElement.cpp appName.cpp lights.cpp maximizedDecorations.cpp)

# Built as hyprbars-macos.so (no lib prefix). The Hyprland-facing plugin name
# stays "hyprbars", so the hl.plugin.hyprbars Lua namespace and the
# plugin:hyprbars:* options match hyprbars and Omarchy's titlebars.
add_library(hyprbars-macos SHARED ${SRC})
set_target_properties(hyprbars-macos PROPERTIES PREFIX "")
# Hyprland exposes inline globals through its headers, so whole-library hidden
# visibility breaks the host API. Our own types/globals have unique OmarchyFloating names.
target_compile_options(hyprbars-macos PRIVATE -fno-gnu-unique)

find_package(PkgConfig REQUIRED)
pkg_check_modules(deps REQUIRED IMPORTED_TARGET
  hyprland
  cairo
  libdrm
  libinput
  libudev
  pixman-1
  wayland-server
  xkbcommon
)
target_link_libraries(hyprbars-macos PRIVATE rt PkgConfig::deps)

install(TARGETS hyprbars-macos LIBRARY DESTINATION lib/hyprbars-macos)
