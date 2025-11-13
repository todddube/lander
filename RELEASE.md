# Release Process

This document describes the release process for Lunar Lander.

---

## Table of Contents

1. [Version Numbering](#version-numbering)
2. [Release Checklist](#release-checklist)
3. [Creating a Release](#creating-a-release)
4. [Build Instructions](#build-instructions)
5. [Distribution](#distribution)

---

## Version Numbering

Lunar Lander follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking changes (incompatible API changes, major rewrites)
- **MINOR**: New features (backward-compatible functionality)
- **PATCH**: Bug fixes (backward-compatible bug fixes)

### Examples

- `1.0.0` → `1.0.1` - Fixed collision bug
- `1.0.1` → `1.1.0` - Added new power-ups
- `1.1.0` → `2.0.0` - Complete rewrite with new engine

---

## Release Checklist

Before creating a release:

- [ ] All features complete and tested
- [ ] No known critical bugs
- [ ] Code compiles without warnings on:
  - [ ] MSVC (Visual Studio)
  - [ ] MinGW (GCC)
  - [ ] CMake build
- [ ] Game tested on:
  - [ ] Windows 10
  - [ ] Windows 11
- [ ] All gameplay features work:
  - [ ] Controls responsive
  - [ ] Landing mechanics correct
  - [ ] Scoring accurate
  - [ ] High scores save/load
  - [ ] Sound effects play
  - [ ] All game states accessible
- [ ] Documentation updated:
  - [ ] README.md reflects current features
  - [ ] CHANGELOG.md has entry for this version
  - [ ] CLAUDE.md updated if architecture changed
- [ ] Version number updated in:
  - [ ] `VERSION` file
  - [ ] `lander.rc` (VER_FILEVERSION and VER_PRODUCTVERSION)
  - [ ] CHANGELOG.md (new section header)
- [ ] Git state clean:
  - [ ] All changes committed
  - [ ] Working directory clean (`git status`)
  - [ ] Pushed to remote

---

## Creating a Release

### 1. Update Version

Edit the `VERSION` file:
```batch
echo 1.0.1 > VERSION
```

Update `lander.rc` version numbers:
```cpp
#define VER_FILEVERSION             1,0,1,0
#define VER_FILEVERSION_STR         "1.0.1.0\0"
#define VER_PRODUCTVERSION          1,0,1,0
#define VER_PRODUCTVERSION_STR      "1.0.1\0"
```

### 2. Update CHANGELOG.md

Add new section at top:
```markdown
## [1.0.1] - 2025-11-15

### Fixed
- Fixed collision detection bug
- Corrected fuel gauge display

### Added
- New explosion particle effects
```

Update version comparison links at bottom:
```markdown
[1.0.1]: https://github.com/username/lander/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/username/lander/releases/tag/v1.0.0
```

### 3. Commit Changes

```batch
git add VERSION lander.rc CHANGELOG.md
git commit -m "Bump version to 1.0.1"
git push
```

### 4. Create Git Tag

```batch
git tag -a v1.0.1 -m "Release version 1.0.1"
git push origin v1.0.1
```

### 5. Build Release Binaries

#### Using CMake (Recommended)
```batch
# Clean previous builds
rmdir /s /q build
mkdir build

# Configure for Release
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release

# Verify executable
build\lander.exe
```

#### Using MSVC
```batch
# Clean
rmdir /s /q build
mkdir build

# Compile
cl /O2 /EHsc /std:c++17 /W4 /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib

# Verify
build\lander.exe
```

#### Using MinGW
```batch
# Clean
rmdir /s /q build
mkdir build

# Compile
g++ -std=c++17 -O2 -Wall -Wextra -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows

# Verify
build\lander.exe
```

### 6. Create Release Package

```batch
# Create release directory
mkdir release-temp
mkdir release-temp\lander-1.0.1

# Copy files
copy build\lander.exe release-temp\lander-1.0.1\
copy README.md release-temp\lander-1.0.1\
copy CHANGELOG.md release-temp\lander-1.0.1\
copy LICENSE release-temp\lander-1.0.1\

# Create ZIP (using PowerShell)
powershell Compress-Archive -Path release-temp\lander-1.0.1 -DestinationPath lander-1.0.1-windows.zip

# Clean up
rmdir /s /q release-temp
```

### 7. Create GitHub Release

1. Go to repository on GitHub
2. Click "Releases" → "Draft a new release"
3. Fill in:
   - **Tag**: `v1.0.1` (use existing tag)
   - **Title**: `Lunar Lander v1.0.1`
   - **Description**: Copy from CHANGELOG.md
4. Upload `lander-1.0.1-windows.zip`
5. Click "Publish release"

---

## Build Instructions

### Prerequisites

#### Option 1: CMake + Visual Studio
- Install [CMake](https://cmake.org/download/) 3.20+
- Install [Visual Studio 2019+](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++"

#### Option 2: Visual Studio Only
- Install [Visual Studio 2019+](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++"

#### Option 3: MinGW-w64
- Install [MinGW-w64](https://www.mingw-w64.org/downloads/)
- Add to PATH: `C:\mingw64\bin` (or wherever installed)

### Build Process

#### CMake Build (All Platforms)

```batch
# Configure
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release

# Output: build\Release\lander.exe (MSVC) or build\lander.exe (MinGW)
```

#### Visual Studio Developer Command Prompt

```batch
# Open "Developer Command Prompt for VS"
cd path\to\lander

# Compile
cl /O2 /EHsc /std:c++17 /W4 /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib

# Output: build\lander.exe
```

#### MinGW Command Prompt

```batch
# Open command prompt
cd path\to\lander

# Compile
g++ -std=c++17 -O2 -Wall -Wextra -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows

# Output: build\lander.exe
```

#### Smart Build Script

```batch
# Tries CMake → MSVC → MinGW automatically
build.bat

# Override version
build.bat 1.0.1

# Debug build
build.bat Debug

# Release build (default)
build.bat Release
```

### Compiler Flags Explained

#### MSVC (`cl.exe`)
- `/O2` - Optimize for speed
- `/EHsc` - Enable C++ exception handling
- `/std:c++17` - Use C++17 standard
- `/W4` - Warning level 4 (high)
- `/Fe:output.exe` - Specify output filename
- `/Zi` - Generate debug info (Debug builds)
- `/DNDEBUG` - Define NDEBUG macro (Release builds)

#### MinGW (`g++`)
- `-std=c++17` - Use C++17 standard
- `-O2` - Optimize for speed
- `-Wall -Wextra` - Enable all warnings
- `-o output.exe` - Specify output filename
- `-luser32 -lgdi32 -lwinmm` - Link Windows libraries
- `-mwindows` - Build Windows GUI app (no console)
- `-g` - Generate debug info (Debug builds)
- `-DNDEBUG` - Define NDEBUG macro (Release builds)

### Build Troubleshooting

**Problem:** `'cl' is not recognized`
- **Solution:** Use "Developer Command Prompt for VS" or run `vcvarsall.bat`

**Problem:** `'g++' is not recognized`
- **Solution:** Add MinGW bin directory to PATH

**Problem:** `'cmake' is not recognized`
- **Solution:** Install CMake and add to PATH

**Problem:** Linker errors about missing libraries
- **Solution:** Ensure linking `user32.lib`, `gdi32.lib`, `winmm.lib`

**Problem:** Warning about deprecated functions
- **Solution:** Ignore or update to use `StringCchPrintf` instead of `sprintf`

**Problem:** Application won't run on other PCs
- **Solution:** Compile with `/MT` (static runtime) instead of `/MD`
  ```batch
  cl /O2 /MT /EHsc /std:c++17 /W4 /Fe:lander.exe lander.cpp user32.lib gdi32.lib winmm.lib
  ```

---

## Distribution

### Package Contents

A release package should include:
- `lander.exe` - Game executable
- `README.md` - User documentation
- `CHANGELOG.md` - Version history
- `LICENSE` - License file (if applicable)

### Recommended Distribution Methods

1. **GitHub Releases** (Primary)
   - Upload ZIP to GitHub releases page
   - Users download directly from repository

2. **itch.io** (Optional)
   - Good for game visibility
   - Built-in update notifications

3. **Direct Download** (Optional)
   - Host ZIP on personal website
   - Provide direct download link

### File Naming Convention

```
lander-{version}-{platform}.zip
```

Examples:
- `lander-1.0.0-windows.zip`
- `lander-1.0.1-windows.zip`
- `lander-2.0.0-windows-x64.zip`

---

## Automated Release (Advanced)

### GitHub Actions (CI/CD)

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup CMake
        uses: lukka/get-cmake@latest

      - name: Build
        run: |
          cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
          cmake --build build --config Release

      - name: Package
        run: |
          mkdir release
          copy build\Release\lander.exe release\
          copy README.md release\
          copy CHANGELOG.md release\

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: release/*
```

### Automated Build Script

Create `create-release.bat`:

```batch
@echo off
setlocal

set /p VERSION=<VERSION
echo Creating release for version %VERSION%...

:: Build
call build.bat Release

:: Package
mkdir release-temp\lander-%VERSION%
copy build\lander.exe release-temp\lander-%VERSION%\
copy README.md release-temp\lander-%VERSION%\
copy CHANGELOG.md release-temp\lander-%VERSION%\

:: ZIP
powershell Compress-Archive -Path release-temp\lander-%VERSION% -DestinationPath lander-%VERSION%-windows.zip -Force

:: Clean
rmdir /s /q release-temp

echo Release package created: lander-%VERSION%-windows.zip
```

Usage:
```batch
create-release.bat
```

---

## Post-Release

After releasing:

1. **Verify download** - Download from release page and test
2. **Announce** - Post on social media, forums, etc.
3. **Monitor feedback** - Watch for bug reports
4. **Plan next version** - Add future ideas to CHANGELOG.md

---

## Hotfix Process

For critical bugs requiring immediate release:

1. Create hotfix branch: `git checkout -b hotfix-1.0.1`
2. Fix bug
3. Test thoroughly
4. Bump PATCH version
5. Merge to main: `git checkout main && git merge hotfix-1.0.1`
6. Follow normal release process
7. Delete hotfix branch: `git branch -d hotfix-1.0.1`

---

## Questions?

If you encounter issues during release, check:
- Build system documentation in CLAUDE.md
- Compiler documentation (MSVC/GCC)
- CMake documentation
- GitHub releases documentation
