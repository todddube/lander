# Lunar Lander

A classic lunar lander game for Windows, written in C++17 using Win32 GDI API. Navigate your spacecraft through space and land safely on the moon's surface while managing fuel and velocity!

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
- **No External Dependencies** - Only Windows SDK required
- **Modern C++17** - Clean, modern codebase
- **60 FPS Gameplay** - Smooth animation and physics
- **Double Buffering** - Flicker-free rendering

---

## Building from Source

### Prerequisites

You need one of the following installed on Windows:

| Option | What to Install |
|--------|-----------------|
| **CMake (Recommended)** | [CMake 3.20+](https://cmake.org/download/) + [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) or MinGW |
| **Visual Studio** | [Visual Studio 2019+](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++" workload |
| **MinGW** | [MinGW-w64](https://www.mingw-w64.org/downloads/) - Add `bin` folder to PATH |

### Quick Build

```batch
# Clone the repository
git clone https://github.com/todddube/lander.git
cd lander

# Build (uses CMake, falls back to MSVC or MinGW)
build.bat

# Run the game
build\lander.exe
```

### Build Methods

#### CMake (Recommended)
```batch
# Configure
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release

# Run
build\lander.exe
```

#### Visual Studio (Developer Command Prompt)
```batch
# Open "Developer Command Prompt for VS" first
cl /O2 /EHsc /std:c++17 /W4 /I.\build /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib
```

#### MinGW
```batch
g++ -std=c++17 -O2 -Wall -Wextra -I./build -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows
```

### Build Script Options

```batch
build.bat              # Release build (default)
build.bat Debug        # Debug build
build.bat 1.2.0        # Build with specific version
build.bat 1.2.0 Debug  # Version + Debug
```

### Build Troubleshooting

| Problem | Solution |
|---------|----------|
| `'cmake' is not recognized` | Install CMake and add to PATH |
| `'cl' is not recognized` | Use "Developer Command Prompt for VS" |
| `'g++' is not recognized` | Add MinGW bin directory to PATH |
| Linker errors | Ensure linking `user32.lib`, `gdi32.lib`, `winmm.lib` |

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

- **Base Landing**: 100 points × level
- **Fuel Bonus**: 2 points per unit remaining × level
- **Speed Bonus**: 50 points for very gentle landing
- **Center Bonus**: 100 points for landing in center of pad

---

## Project Structure

```
lander/
├── lander.cpp          # Main game source (single file)
├── CMakeLists.txt      # CMake build configuration
├── build.bat           # Smart build script
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
- **Single-file design** - All code in `lander.cpp` (~2000 lines)
- **Entity-component pattern** - Lander, terrain, particles
- **State machine** - Clean game state management
- **Double buffering** - Flicker-free rendering

### Physics
- **Gravity simulation** - Constant downward acceleration
- **Thrust vectors** - Directional thrust based on rotation
- **Velocity clamping** - Terminal velocity enforcement
- **Collision detection** - Terrain intersection testing

### Graphics
- **Win32 GDI** - Hardware-accelerated 2D rendering
- **Vector rendering** - Points, lines, and polygons
- **Particle system** - Explosion and thruster effects
- **Procedural terrain** - Runtime-generated landscapes

### Audio
- **waveOut API** - Custom synthesized sounds
- **Rocket thrust** - Continuous engine rumble
- **Explosion** - Multi-phase KABOOM effect
- **Space theme** - Cinematic intro music

### Compatibility
- **Windows 7+** - Full compatibility
- **DPI Aware** - Scales properly on high-DPI displays
- **No admin required** - Standard user privileges

---

## License

Copyright (c) 2025 Todd Dube

---

## Acknowledgments

Inspired by the classic 1969 Lunar Lander arcade game and its many variants.
