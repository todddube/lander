cmake_minimum_required(VERSION 3.20)

# Read version from VERSION file
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VERSION_STRING)
string(STRIP "${VERSION_STRING}" VERSION_STRING)

# Parse version components
string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+).*" "\\1" VERSION_MAJOR "${VERSION_STRING}")
string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+).*" "\\2" VERSION_MINOR "${VERSION_STRING}")
string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+).*" "\\3" VERSION_PATCH "${VERSION_STRING}")

project(Lander VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})

# C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate version header
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/version.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/version.h"
    @ONLY
)

# Add executable with Windows resource file
add_executable(lander WIN32
    lander.cpp
    lander.rc
)

# Include generated headers
target_include_directories(lander PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")

# Link Windows libraries
target_link_libraries(lander PRIVATE
    user32
    gdi32
    winmm
)

# Compiler-specific flags
if(MSVC)
    target_compile_options(lander PRIVATE /W4)
    # Embed manifest
    set_target_properties(lander PROPERTIES
        LINK_FLAGS "/MANIFEST:EMBED /MANIFESTINPUT:${CMAKE_CURRENT_SOURCE_DIR}/lander.manifest"
    )
else()
    target_compile_options(lander PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Output directory
set_target_properties(lander PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
