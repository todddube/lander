# 🚀 Lunar Lander

A classic lunar lander game for Windows, written in C++17 using Win32 GDI API. Navigate your spacecraft through space and land safely on the moon's surface while managing fuel and velocity!

## ✨ Features

### 🎮 Gameplay
- **Physics Simulation** - Realistic gravity and thrust mechanics
- **Fuel Management** - Limited fuel requires careful thruster control
- **Landing Pads** - Find and land on designated safe zones
- **Multiple Levels** - Increasing difficulty with rougher terrain
- **Lives System** - Three lives to achieve the highest score
- **Particle Effects** - Dynamic explosion and thruster particles

### 📊 Progression
- **Score System** - Points for successful landings, fuel conservation, and speed
- **High Score Tracking** - Persistent top 10 scores with names
- **Level Advancement** - Terrain gets more challenging each level
- **Bonus Scoring** - Extra points for gentle landings and center pad hits

### 🎨 Presentation
- **Vector Graphics** - Clean, classic arcade-style visuals
- **Starfield Background** - Dynamic space environment
- **Terrain Generation** - Procedural terrain for each level
- **Real-time HUD** - Displays score, level, lives, fuel, and velocity
- **Sound Effects** - Beep-based thrust, crash, and landing sounds

### 🔧 Technical
- **Single File Design** - Entire game in one C++ file
- **No External Dependencies** - Only Windows SDK required
- **Modern C++17** - Clean, modern codebase
- **60 FPS Gameplay** - Smooth animation and physics
- **Double Buffering** - Flicker-free rendering

---

## 📥 Quick Start

### Download & Run
1. Download `lander.exe` from the [latest release](../../releases)
2. Double-click to play!

### Building from Source
```batch
# Clone the repository
git clone <repository-url>
cd lander

# Build using CMake (recommended)
cmake -B build -S .
cmake --build build --config Release

# Or use the smart build script
build.bat

# Run the game
build\lander.exe
```

---

## 🎮 How to Play

### Controls

| Key | Action |
|-----|--------|
| **↑ / W** | Main thruster (upward thrust) |
| **← / A** | Left thruster (rotate left) |
| **→ / D** | Right thruster (rotate right) |
| **SPACE** | Start game / Restart |
| **H** | View high scores |
| **P** | Pause game |
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

✅ **Safe Landing:**
- Velocity < 1.5
- Nearly vertical orientation
- Touch down on green landing pad
- Lander intact

❌ **Crash:**
- Too fast (velocity > 1.5)
- Tilted too far
- Hit terrain outside landing pad
- Out of fuel before landing

### Scoring

- **Base Landing**: 100 points × level
- **Fuel Bonus**: 2 points per unit remaining × level
- **Speed Bonus**: 50 points for very gentle landing
- **Center Bonus**: 100 points for landing in center of pad

---

## 🏗️ Building

### Prerequisites
- Windows 10/11
- One of the following:
  - CMake 3.20+ (recommended)
  - Visual Studio 2019+ (MSVC)
  - MinGW-w64 (GCC)

### Build Methods

#### CMake (Recommended)
```batch
# Configure
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release

# Output: build\lander.exe
```

#### Visual Studio (MSVC)
```batch
# Open Developer Command Prompt
cl /Zi /EHsc /std:c++17 /W4 /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib
```

#### MinGW
```batch
g++ -std=c++17 -O2 -Wall -Wextra -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows
```

#### Smart Build Script
```batch
# Tries CMake, falls back to MSVC, then MinGW
build.bat

# Build with specific version
build.bat 1.0.0

# Debug build
build.bat Debug
```

---

## 📁 Project Structure

```
lander/
├── lander.cpp          # Main game source (single file)
├── lander.rc           # Windows resource file
├── lander.manifest     # Windows manifest (DPI, compatibility)
├── CMakeLists.txt      # CMake build configuration
├── build.bat           # Smart build script
├── VERSION             # Semantic version number
├── version.h.in        # Version header template
├── README.md           # This file
├── CHANGELOG.md        # Version history
├── CLAUDE.md           # AI development guidelines
├── RELEASE.md          # Release process documentation
├── .gitignore          # Git exclusions
└── build/              # Build output directory
```

---

## 🎯 Technical Details

### Architecture
- **Single-file design** - All code in `lander.cpp` (~1200 lines)
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

### Data Persistence
- **High scores** - Binary file storage (`lander_scores.dat`)
- **Score tracking** - Top 10 scores with names and levels

### Compatibility
- **Windows 7+** - Full compatibility
- **DPI Aware** - Scales properly on high-DPI displays
- **No admin required** - Standard user privileges

---

## 🔊 Sound

The game uses Windows Beep API for sound effects:
- **Thrust** - Short beep during thruster activation
- **Landing** - Musical sequence for successful landing
- **Crash** - Low-frequency explosion sound

---

## 🏆 High Scores

High scores are automatically saved to `lander_scores.dat` in the game directory. The top 10 scores are tracked with player names and the level reached.

---

## 📝 License

Copyright (c) 2025 Todd Dube

---

## 🙏 Acknowledgments

Inspired by the classic 1969 Lunar Lander arcade game and its many variants.

---

**Enjoy the game! 🌙🚀**
