# Lunar Lander

A classic lunar lander game written in C++17 for Windows and macOS. Navigate your spacecraft through space and land safely on the moon's surface while managing fuel and velocity!

## Features

### Gameplay
- **Physics Simulation** - Realistic gravity and thrust mechanics
- **Fuel Management** - Limited fuel requires careful thruster control
- **Landing Pads** - Find and land on designated safe zones
- **Multiple Levels** - Increasing difficulty with rougher terrain
- **Lives System** - Three lives to achieve the highest score
- **Particle Effects** - Dynamic explosion and thruster particles

### Progression
- **Score System** - Points for successful landings, fuel conservation, and speed
- **High Score Tracking** - Persistent top 10 scores with names
- **Level Advancement** - Terrain gets more challenging each level
- **Bonus Scoring** - Extra points for gentle landings and center pad hits

### Presentation
- **Vector Graphics** - Clean, classic arcade-style visuals
- **Starfield Background** - Dynamic space environment
- **Terrain Generation** - Procedural terrain for each level
- **Real-time HUD** - Displays score, level, lives, fuel, and velocity
- **Sound Effects** - Realistic rocket thrust and explosion sounds
- **Space Frontier Intro** - Cinematic startup theme

### Technical
- **Single File Design** - Entire game in one C++ file
- **Cross-Platform** - Runs on Windows and macOS
- **No External Dependencies** - Only platform SDK required
- **Modern C++17** - Clean, modern codebase
- **60 FPS Gameplay** - Smooth animation and physics
- **Double Buffering** - Flicker-free rendering

---

## Building from Source

### Windows

#### Prerequisites

You need one of the following installed on Windows:

| Option | What to Install |
|--------|-----------------|
| **CMake (Recommended)** | [CMake 3.20+](https://cmake.org/download/) + [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) or MinGW |
| **Visual Studio** | [Visual Studio 2019+](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++" workload |
| **MinGW** | [MinGW-w64](https://www.mingw-w64.org/downloads/) - Add `bin` folder to PATH |

#### Quick Build (Windows)

```batch
# Clone the repository
git clone https://github.com/todddube/lander.git
cd lander

# Build (uses CMake, falls back to MSVC or MinGW)
build.bat

# Run the game
build\lander.exe
```

#### Build Methods (Windows)

**CMake (Recommended)**
```batch
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
build\lander.exe
```

**Visual Studio (Developer Command Prompt)**
```batch
cl /O2 /EHsc /std:c++17 /W4 /I.\build /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib
```

**MinGW**
```batch
g++ -std=c++17 -O2 -Wall -Wextra -I./build -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows
```

#### Build Script Options (Windows)

```batch
build.bat              # Release build (default)
build.bat Debug        # Debug build
build.bat 1.2.0        # Build with specific version
build.bat 1.2.0 Debug  # Version + Debug
```

### macOS

#### Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode Command Line Tools: `xcode-select --install`
- Optionally [CMake 3.20+](https://cmake.org/download/) (`brew install cmake`)

#### Quick Build (macOS)

```bash
# Clone the repository
git clone https://github.com/todddube/lander.git
cd lander

# Build with CMake
cmake -B build -S .
cmake --build build

# Or build directly with clang++
mkdir -p build
clang++ -std=c++17 -O2 -x objective-c++ \
    -framework Cocoa -framework CoreGraphics \
    -framework CoreText -framework AudioToolbox \
    -o build/lander lander.cpp

# Run the game
./build/lander
```

### Build Troubleshooting

| Problem | Platform | Solution |
|---------|----------|----------|
| `'cmake' is not recognized` | Windows | Install CMake and add to PATH |
| `'cl' is not recognized` | Windows | Use "Developer Command Prompt for VS" |
| `'g++' is not recognized` | Windows | Add MinGW bin directory to PATH |
| Linker errors (Windows) | Windows | Ensure linking `user32.lib`, `gdi32.lib`, `winmm.lib` |
| `xcode-select: error` | macOS | Run `xcode-select --install` to install dev tools |
| Framework not found | macOS | Ensure Xcode Command Line Tools are installed |

---

## How to Play

### Controls

| Key | Action |
|-----|--------|
| **UP / W / SPACE** | Main thruster (upward thrust) |
| **LEFT / A** | Rotate left |
| **RIGHT / D** | Rotate right |
| **P** | Pause game |
| **Q** | Quit (shows confirmation during game) |
| **R** | Restart (shows confirmation during game) |
| **H** | View high scores (from title screen) |
| **ESC** | Return to title screen |

### Gameplay

1. **Launch** - Press SPACE from the title screen to start
2. **Navigate** - Use arrow keys or WASD to control your lander
3. **Find the Pad** - Look for the green landing pad on the terrain
4. **Land Safely** - Touch down gently with low velocity and upright orientation
5. **Watch Your Meters**:
   - **Fuel** - Runs out quickly! Use thrusters sparingly
   - **Velocity** - Must be under 1.5 for safe landing
   - **Rotation** - Must be nearly vertical to land safely

### Landing Requirements

**Safe Landing:**
- Velocity < 1.5
- Nearly vertical orientation
- Touch down on green landing pad

**Crash:**
- Too fast (velocity > 1.5)
- Tilted too far
- Hit terrain outside landing pad

### Scoring

- **Base Landing**: 100 points x level
- **Fuel Bonus**: 2 points per unit remaining x level
- **Speed Bonus**: 50 points for very gentle landing
- **Center Bonus**: 100 points for landing in center of pad

---

## Project Structure

```
lander/
├── lander.cpp          # Main game source (single file, cross-platform)
├── CMakeLists.txt      # CMake build configuration (Windows + macOS)
├── build.bat           # Windows build script
├── VERSION             # Version number (e.g., 1.0.0)
├── version.h.in        # Version header template
├── lander.rc.in        # Windows resource template
├── README.md           # This file
├── CHANGELOG.md        # Version history
├── CLAUDE.md           # AI development guidelines
├── .gitignore          # Git exclusions
├── .github/
│   └── workflows/      # GitHub Actions (CI/CD)
│       ├── build.yml   # Build verification
│       └── release.yml # Automated releases
└── build/              # Build output directory
```

---

## Releases

Releases are automated via GitHub Actions:

1. **Update version**: Edit the `VERSION` file (e.g., `1.0.1`)
2. **Commit and push**: `git commit -am "Bump to 1.0.1" && git push`
3. **Automatic**: GitHub Actions builds, creates tag, and publishes release

See [Releases](https://github.com/todddube/lander/releases) for download.

---

## Technical Details

### Architecture
- **Single-file design** - All code in `lander.cpp` (~3300 lines)
- **Platform Abstraction Layer** - Portable drawing, sound, and input via `#ifdef` guards
- **Entity-component pattern** - Lander, terrain, particles
- **State machine** - Clean game state management
- **Double buffering** - Flicker-free rendering

### Physics
- **Gravity simulation** - Constant downward acceleration
- **Thrust vectors** - Directional thrust based on rotation
- **Velocity clamping** - Terminal velocity enforcement
- **Collision detection** - Terrain intersection testing

### Graphics
- **Windows**: Win32 GDI — hardware-accelerated 2D rendering
- **macOS**: CoreGraphics — bitmap context with Y-flip for Windows coordinate compatibility
- **Text**: GDI DrawText (Windows) / Core Text (macOS)
- **Particle system** - Explosion and thruster effects
- **Procedural terrain** - Runtime-generated landscapes

### Audio
- **Windows**: waveOut API — custom synthesized sounds
- **macOS**: AudioToolbox AudioQueue — streaming and one-shot playback
- **Rocket thrust** - Continuous engine rumble (double-buffered streaming)
- **Explosion** - Multi-phase synthesized KABOOM effect
- **Space theme** - Cinematic intro music

### Compatibility
- **Windows 7+** - Full compatibility (Win32 GDI)
- **macOS 14+** - Cocoa / CoreGraphics / AudioToolbox
- **DPI Aware** - Scales properly on high-DPI displays (Windows)
- **No admin required** - Standard user privileges

---

## License

Copyright (c) 2025 Todd Dube

---

## Acknowledgments

Inspired by the classic 1969 Lunar Lander arcade game and its many variants.
