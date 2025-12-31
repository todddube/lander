@echo off
setlocal enabledelayedexpansion

:: Smart build script for Lander
:: Tries CMake first, falls back to direct compiler if needed
:: Usage: build.bat [version] [Debug|Release]

set "BUILD_TYPE=Release"
set "VERSION_OVERRIDE="

:: Parse arguments
:parse_args
if "%~1"=="" goto end_parse
echo %~1 | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if %ERRORLEVEL%==0 (
    set "VERSION_OVERRIDE=%~1"
    shift
    goto parse_args
)
if /i "%~1"=="Debug" (
    set "BUILD_TYPE=Debug"
    shift
    goto parse_args
)
if /i "%~1"=="Release" (
    set "BUILD_TYPE=Release"
    shift
    goto parse_args
)
shift
goto parse_args
:end_parse

:: Read version from VERSION file if not overridden
if not defined VERSION_OVERRIDE (
    if exist VERSION (
        set /p VERSION_OVERRIDE=<VERSION
    ) else (
        set "VERSION_OVERRIDE=1.0.0"
    )
)

echo ========================================
echo Building Lander v%VERSION_OVERRIDE% [%BUILD_TYPE%]
echo ========================================

:: Create build directory
if not exist build mkdir build

:: Try CMake first (preferred method)
where cmake >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [CMake] Configuring build...
    cmake -B build -S . -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
    if %ERRORLEVEL%==0 (
        echo [CMake] Building...
        cmake --build build --config %BUILD_TYPE%
        if %ERRORLEVEL%==0 (
            echo.
            echo ========================================
            echo Build successful! Executable: build\lander.exe
            echo ========================================
            exit /b 0
        )
    )
    echo [CMake] Build failed, trying direct compilation...
)

:: Parse version into components
echo [Build] Generating version files...
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION_OVERRIDE%") do (
    set "VER_MAJOR=%%a"
    set "VER_MINOR=%%b"
    set "VER_PATCH=%%c"
)

:: Generate version.h from template pattern
(
echo #ifndef VERSION_H
echo #define VERSION_H
echo.
echo #define LANDER_VERSION_MAJOR %VER_MAJOR%
echo #define LANDER_VERSION_MINOR %VER_MINOR%
echo #define LANDER_VERSION_PATCH %VER_PATCH%
echo #define LANDER_VERSION_STRING "%VERSION_OVERRIDE%"
echo #define LANDER_AUTHOR "Todd Dube"
echo #define LANDER_COPYRIGHT "Copyright (c) 2025 Todd Dube"
echo.
echo #endif // VERSION_H
) > build\version.h

:: Generate lander.rc with correct version (single source of truth)
(
echo #include ^<windows.h^>
echo.
echo #ifdef RC_INVOKED
echo.
echo #define VER_FILEVERSION             %VER_MAJOR%,%VER_MINOR%,%VER_PATCH%,0
echo #define VER_FILEVERSION_STR         "%VERSION_OVERRIDE%.0\0"
echo.
echo #define VER_PRODUCTVERSION          %VER_MAJOR%,%VER_MINOR%,%VER_PATCH%,0
echo #define VER_PRODUCTVERSION_STR      "%VERSION_OVERRIDE%\0"
echo.
echo #define VER_COMPANYNAME_STR         "Todd Dube"
echo #define VER_FILEDESCRIPTION_STR     "Classic Lunar Lander Game"
echo #define VER_INTERNALNAME_STR        "lander"
echo #define VER_LEGALCOPYRIGHT_STR      "Copyright (c) 2025 Todd Dube"
echo #define VER_ORIGINALFILENAME_STR    "lander.exe"
echo #define VER_PRODUCTNAME_STR         "Lunar Lander"
echo.
echo VS_VERSION_INFO VERSIONINFO
echo FILEVERSION     VER_FILEVERSION
echo PRODUCTVERSION  VER_PRODUCTVERSION
echo FILEFLAGSMASK   VS_FFI_FILEFLAGSMASK
echo FILEFLAGS       0
echo FILEOS          VOS__WINDOWS32
echo FILETYPE        VFT_APP
echo FILESUBTYPE     VFT2_UNKNOWN
echo BEGIN
echo     BLOCK "StringFileInfo"
echo     BEGIN
echo         BLOCK "040904B0"
echo         BEGIN
echo             VALUE "CompanyName",      VER_COMPANYNAME_STR
echo             VALUE "FileDescription",  VER_FILEDESCRIPTION_STR
echo             VALUE "FileVersion",      VER_FILEVERSION_STR
echo             VALUE "InternalName",     VER_INTERNALNAME_STR
echo             VALUE "LegalCopyright",   VER_LEGALCOPYRIGHT_STR
echo             VALUE "OriginalFilename", VER_ORIGINALFILENAME_STR
echo             VALUE "ProductName",      VER_PRODUCTNAME_STR
echo             VALUE "ProductVersion",   VER_PRODUCTVERSION_STR
echo         END
echo     END
echo     BLOCK "VarFileInfo"
echo     BEGIN
echo         VALUE "Translation", 0x409, 1200
echo     END
echo END
echo.
echo #endif
) > build\lander.rc

:: Compile resource file
where rc.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [Build] Compiling resources...
    rc.exe /fo build\lander.res build\lander.rc
)

:: Try MSVC (cl.exe)
where cl.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [MSVC] Compiling with cl.exe...
    set "CL_FLAGS=/Zi /EHsc /std:c++17 /W4 /I.\build"
    if /i "%BUILD_TYPE%"=="Debug" (
        set "CL_FLAGS=!CL_FLAGS! /Od /DDEBUG"
    ) else (
        set "CL_FLAGS=!CL_FLAGS! /O2 /DNDEBUG"
    )
    if exist build\lander.res (
        cl !CL_FLAGS! /Fe:build\lander.exe lander.cpp build\lander.res user32.lib gdi32.lib winmm.lib
    ) else (
        cl !CL_FLAGS! /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib
    )
    if %ERRORLEVEL%==0 (
        echo.
        echo ========================================
        echo Build successful! Executable: build\lander.exe
        echo ========================================
        exit /b 0
    )
    echo [MSVC] Build failed, trying MinGW...
)

:: Try MinGW (g++)
where g++.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [MinGW] Compiling with g++...
    set "GCC_FLAGS=-std=c++17 -Wall -Wextra -I./build"
    if /i "%BUILD_TYPE%"=="Debug" (
        set "GCC_FLAGS=!GCC_FLAGS! -g -DDEBUG"
    ) else (
        set "GCC_FLAGS=!GCC_FLAGS! -O2 -DNDEBUG"
    )
    if exist build\lander.res (
        g++ !GCC_FLAGS! -o build\lander.exe lander.cpp build\lander.res -luser32 -lgdi32 -lwinmm -mwindows
    ) else (
        g++ !GCC_FLAGS! -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows
    )
    if %ERRORLEVEL%==0 (
        echo.
        echo ========================================
        echo Build successful! Executable: build\lander.exe
        echo ========================================
        exit /b 0
    )
)

echo.
echo ========================================
echo ERROR: No suitable compiler found!
echo Install one of: CMake, MSVC, or MinGW
echo ========================================
exit /b 1
