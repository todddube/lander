cmake_minimum_required(VERSION 3.20)

# macOS deployment target must be set before project()
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS deployment version")
endif()

# Export compile_commands.json for IDE/clangd integration
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Read version from VERSION file (single source of truth)
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

# Generate version header from template
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/version.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/version.h"
    @ONLY
)

if(APPLE)
    # macOS: Compile as Objective-C++ and link Apple frameworks
    # COMPILE_OPTIONS (not deprecated COMPILE_FLAGS) for per-file flags
    set_source_files_properties(lander.cpp PROPERTIES COMPILE_OPTIONS "-x;objective-c++")
    add_executable(lander lander.cpp)
    target_include_directories(lander PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
    target_link_libraries(lander PRIVATE
        "-framework Cocoa"
        "-framework CoreGraphics"
        "-framework CoreText"
        "-framework AudioToolbox")
    target_compile_options(lander PRIVATE -Wall -Wextra -Wpedantic)
    set_target_properties(lander PROPERTIES
        MACOSX_BUNDLE FALSE  # bare executable; set TRUE to build a .app bundle
        XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++17"
    )
elseif(WIN32)
    # Windows: Generate resource file and link Win32 libraries
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/lander.rc.in"
        "${CMAKE_CURRENT_BINARY_DIR}/lander.rc"
        @ONLY
    )

    add_executable(lander WIN32
        lander.cpp
        "${CMAKE_CURRENT_BINARY_DIR}/lander.rc"
    )
    target_include_directories(lander PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
    target_link_libraries(lander PRIVATE
        user32
        gdi32
        winmm
    )

    if(MSVC)
        target_compile_options(lander PRIVATE /W4)
        set_target_properties(lander PROPERTIES
            LINK_FLAGS "/MANIFEST:EMBED /MANIFESTINPUT:${CMAKE_CURRENT_SOURCE_DIR}/lander.manifest"
        )
    else()
        target_compile_options(lander PRIVATE -Wall -Wextra -Wpedantic)
    endif()
endif()

# Output directory
set_target_properties(lander PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
