# Lunar Lander - AI Development Guide

This document provides context and guidelines for AI assistants (like Claude) working on the Lunar Lander codebase.

---

## Project Overview

**Lunar Lander** is a classic arcade-style game written in modern C++17 for Windows. It's a single-file application that uses only the Windows SDK (Win32 API) for graphics, input, and sound.

### Design Philosophy
- **Simplicity**: Single C++ file, no external dependencies
- **Classic gameplay**: Faithful to the original lunar lander concept
- **Modern code**: C++17 features, clean architecture, well-documented
- **Self-contained**: Everything needed to build and run in one directory

---

## Quick Build Commands

```batch
# Smart build (tries CMake, MSVC, MinGW in order)
build.bat

# CMake build
cmake -B build -S .
cmake --build build --config Release

# Direct MSVC compilation
cl /Zi /EHsc /std:c++17 /W4 /Fe:build\lander.exe lander.cpp user32.lib gdi32.lib winmm.lib

# Direct MinGW compilation
g++ -std=c++17 -O2 -Wall -Wextra -o build\lander.exe lander.cpp -luser32 -lgdi32 -lwinmm -mwindows
```

---

## Architecture

### Single-File Design
The entire game is in `lander.cpp` (~1200 lines). This intentional design choice:
- Makes the codebase easy to understand and navigate
- Eliminates build complexity
- Allows quick iteration and testing
- Serves as an educational example

**DO NOT** split into multiple files unless explicitly requested.

### Code Organization

The file is organized into clear sections marked by banner comments:

```cpp
// ============================================================================
// Section Name
// ============================================================================
```

**Sections** (in order):
1. **Platform Configuration** - Unicode setup, Windows targeting
2. **System Includes** - Standard library and Windows headers
3. **Game Constants** - Tweakable gameplay parameters
4. **Core Data Structures** - Vector2, Lander, TerrainPoint, Particle, etc.
5. **Global Game State** - All game state variables
6. **Function Prototypes** - Forward declarations
7. **Initialization Functions** - InitGame(), InitTerrain(), etc.
8. **Game Loop Functions** - UpdateGame(), RenderGame()
9. **Physics Functions** - UpdatePhysics(), ApplyThrust(), collision detection
10. **Particle System** - Explosion and particle effects
11. **Rendering Functions** - All drawing code
12. **High Score Functions** - Save/load/update scores
13. **Sound Functions** - Beep-based sound effects
14. **Utility Functions** - Lerp, Clamp, etc.
15. **Windows Message Handling** - WindowProc(), WinMain()

### Game Loop

The game uses a **timer-based loop** (not a traditional while loop):

```cpp
// In WM_CREATE:
SetTimer(hwnd, 1, TARGET_FRAME_TIME, nullptr);  // 16ms = ~60 FPS

// In WM_TIMER:
UpdateGame();
InvalidateRect(hwnd, nullptr, FALSE);  // Triggers WM_PAINT

// In WM_PAINT:
RenderGame(hdc);
```

This approach integrates with Windows message loop and prevents blocking.

### State Machine

Game states are managed via `enum class GameState`:

```cpp
enum class GameState {
    TITLE_SCREEN,      // Main menu
    PLAYING,           // Active gameplay
    PAUSED,            // Paused (not fully implemented)
    LANDING_SUCCESS,   // Just landed successfully
    CRASHED,           // Just crashed
    GAME_OVER,         // Out of lives
    HIGH_SCORES,       // Viewing high scores
    ENTER_NAME         // Entering name for high score
};
```

State transitions happen in `WindowProc` (input) and `UpdateGame` (gameplay events).

### Entity System

**Core entities:**
- `Lander` - Player spacecraft with position, velocity, fuel, rotation
- `TerrainPoint` - Vertex in terrain mesh (x, y, isLandingPad flag)
- `Particle` - Explosion/effect particles with lifetime
- `Star` - Background stars (x, y, brightness)

All entities stored in global vectors or structs.

---

## Critical Implementation Details

### Physics Simulation

**Gravity:**
```cpp
lander.vel.y += GRAVITY;  // Constant downward acceleration
```

**Thrust:**
```cpp
// Main thruster applies force in direction lander is facing
lander.vel.y -= THRUST_POWER * std::cos(lander.rotation);
lander.vel.x += THRUST_POWER * std::sin(lander.rotation);
```

**Velocity Clamping:**
```cpp
if (lander.vel.length() > MAX_VELOCITY) {
    float ratio = MAX_VELOCITY / lander.vel.length();
    lander.vel.x *= ratio;
    lander.vel.y *= ratio;
}
```

### Terrain Generation

Terrain is procedurally generated in `InitTerrain()`:
1. Generate random heights with increasing roughness per level
2. Choose random position for landing pad
3. Make landing pad section perfectly flat
4. Store as array of `TerrainPoint` structs

**Important:** Landing pad width should be wide enough to land on but challenging.

### Collision Detection

**Two-step process:**
1. **CheckTerrainCollision()** - Is lander touching terrain?
   - Get lander bottom Y coordinate
   - Find terrain segment at lander X
   - Interpolate terrain height at that X
   - Compare with lander Y

2. **CheckLandingPadCollision()** - Is collision on landing pad?
   - Check if terrain segment index is within landing pad range

**Landing success requires:**
- Collision on landing pad (`CheckLandingPadCollision()` returns true)
- Low velocity (`lander.vel.length() < SAFE_LANDING_SPEED`)
- Nearly vertical (`std::abs(lander.rotation) < 0.2f`)

### Rendering System

**Double buffering** prevents flicker:
```cpp
static HDC hdcMem = nullptr;
static HBITMAP hbmMem = nullptr;

// Create memory DC once
if (!hdcMem) {
    hdcMem = CreateCompatibleDC(hdc);
    hbmMem = CreateCompatibleBitmap(hdc, WINDOW_WIDTH, WINDOW_HEIGHT);
    SelectObject(hdcMem, hbmMem);
}

// Draw to memory DC
FillRect(hdcMem, &rect, hBrush);
// ... all drawing operations ...

// Copy to screen
BitBlt(hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMem, 0, 0, SRCCOPY);
```

**Coordinate system:**
- Origin (0,0) is top-left corner
- X increases rightward
- Y increases downward
- Terrain Y values are near bottom of screen

### Sound Generation

Using Windows `Beep()` function:
```cpp
Beep(frequency_hz, duration_ms);
```

**Sound effects:**
- Thrust: 200 Hz, 20ms (short beep)
- Crash: 100 Hz, 300ms (low rumble)
- Landing: 800→600→400 Hz sequence (musical)

**Note:** Beep is synchronous (blocks), so keep durations short.

---

## Common Modifications

### Adjusting Difficulty

**Easier:**
- Increase `SAFE_LANDING_SPEED` (allow faster landings)
- Increase `INITIAL_FUEL` (more fuel available)
- Decrease `GRAVITY` (slower fall)
- Increase `THRUST_POWER` (stronger thrusters)

**Harder:**
- Decrease `SAFE_LANDING_SPEED` (require gentler landing)
- Decrease `INITIAL_FUEL` (less fuel available)
- Increase `GRAVITY` (faster fall)
- Decrease `THRUST_POWER` (weaker thrusters)

### Adding New Features

**New game objects:**
1. Define struct in "Core Data Structures" section
2. Add global vector/variable in "Global Game State"
3. Add update logic in `UpdateGame()`
4. Add rendering in `RenderGame()`

**New game state:**
1. Add to `GameState` enum
2. Add case in `UpdateGame()` switch
3. Add case in `RenderGame()` switch
4. Add transition logic in `WindowProc`

### Modifying Scoring

All scoring happens in the landing success check in `UpdateGame()`:
```cpp
int landingScore = SCORE_BASE_LANDING;
landingScore += static_cast<int>(lander.fuel) * SCORE_FUEL_BONUS;
// Add more bonuses here
score += landingScore * level;  // Multiply by level
```

### Changing Controls

Input is handled in `WindowProc` under `WM_KEYDOWN` and `WM_KEYUP`. The `keys[]` array tracks key states, checked in `ApplyThrust()`.

To add new controls:
1. Handle key in `WindowProc` → set `keys[VK_...]`
2. Check key state in `ApplyThrust()` or `UpdateGame()`

---

## Build System Notes

### Version Management

Version is stored in `VERSION` file (e.g., `1.0.0`).

**CMake builds:**
- Reads `VERSION` file
- Parses major.minor.patch
- Generates `build/version.h` from `version.h.in` template

**build.bat:**
- Can override version: `build.bat 1.2.3`
- Generates `version.h` manually if CMake not available

### Resource Compilation

`lander.rc` contains Windows version info. It's compiled by:
- CMake: Automatically as part of `add_executable()`
- build.bat: Calls `rc.exe` if available
- Manual: `rc.exe /fo build\lander.res lander.rc`

Link the `.res` file with the executable for embedded version info.

---

## Platform-Specific Notes

### Windows API Usage

**Graphics (GDI):**
- `CreatePen()`, `SelectObject()`, `DeleteObject()` - Drawing tools
- `MoveToEx()`, `LineTo()`, `Polyline()` - Vector drawing
- `TextOut()`, `DrawText()` - Text rendering
- `CreateFont()` - Font creation

**Input:**
- `WM_KEYDOWN`, `WM_KEYUP` - Keyboard events
- `WM_CHAR` - Character input for text entry
- Virtual key codes: `VK_UP`, `VK_SPACE`, etc.

**Timing:**
- `SetTimer()` - Creates periodic timer
- `WM_TIMER` - Timer event message

**Unicode:**
- All strings are `wchar_t*` / `L"string"`
- Use wide-character functions: `wcslen()`, `StringCchPrintf()`

### Compilation Requirements

**Required libraries:**
- `user32.lib` - Window management
- `gdi32.lib` - Graphics
- `winmm.lib` - Multimedia (Beep sound)

**Required flags:**
- `/std:c++17` or `-std=c++17` - C++17 standard
- `WIN32` defined - Windows GUI app
- `/W4` or `-Wall -Wextra` - High warning level

---

## Testing Checklist

When making changes, verify:
- [ ] Game compiles without warnings
- [ ] Title screen displays correctly
- [ ] Controls respond (arrow keys and WASD)
- [ ] Lander moves and rotates
- [ ] Fuel depletes when thrusting
- [ ] Gravity pulls lander down
- [ ] Terrain generates with landing pad (green)
- [ ] Landing on pad with low speed succeeds
- [ ] Landing too fast or off pad crashes
- [ ] Explosion particles appear on crash
- [ ] Score increases after successful landing
- [ ] Level advances after landing
- [ ] Lives decrease after crash
- [ ] Game over triggers after losing all lives
- [ ] High score entry works
- [ ] High scores save and load
- [ ] Sound effects play

---

## Debugging Tips

**Common issues:**

1. **Lander falls through terrain:**
   - Check collision detection math
   - Ensure terrain Y values are correct (larger Y = lower on screen)

2. **Lander won't rotate:**
   - Verify rotation is updating in `ApplyThrust()`
   - Check rotation is used in rendering transformation

3. **Fuel doesn't deplete:**
   - Ensure `FUEL_USAGE_*` is subtracted in `ApplyThrust()`
   - Check `lander.fuel` is displayed in HUD

4. **Landing always crashes:**
   - Check `SAFE_LANDING_SPEED` threshold
   - Verify rotation angle threshold (radians, not degrees!)
   - Ensure `CheckLandingPadCollision()` returns true

5. **High scores don't save:**
   - Check file path (`lander_scores.dat`)
   - Verify write permissions in game directory
   - Ensure `SaveHighScores()` is called

**printf debugging:**
Since this is a Windows GUI app, `printf()` won't show output. Use:
```cpp
MessageBox(nullptr, L"Debug message", L"Debug", MB_OK);
// Or
OutputDebugString(L"Debug message\n");  // View in debugger
```

---

## Code Style

Follow existing conventions:
- **Variables:** `camelCase` (e.g., `landerPosition`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_VELOCITY`)
- **Functions:** `PascalCase` (e.g., `InitTerrain()`)
- **Structs/Classes:** `PascalCase` (e.g., `Vector2`)
- **Braces:** K&R style (opening brace on same line)
- **Indentation:** 4 spaces
- **Comments:** Describe "why", not "what"
- **Documentation:** Doxygen-style function headers

---

## When Modifying Code

1. **Read the relevant section** before making changes
2. **Maintain the single-file structure** - don't split unless requested
3. **Follow existing patterns** - look at similar code nearby
4. **Update constants** rather than hardcoding values
5. **Test thoroughly** - ensure no regressions
6. **Update documentation** if behavior changes significantly
7. **Keep it simple** - prefer clarity over cleverness

---

## Useful Constants for Tweaking

```cpp
// Window size
WINDOW_WIDTH, WINDOW_HEIGHT

// Physics
GRAVITY                 // Strength of downward pull
THRUST_POWER           // Main thruster strength
SIDE_THRUST_POWER      // Rotation thruster strength
MAX_VELOCITY           // Terminal velocity
SAFE_LANDING_SPEED     // Maximum safe landing velocity

// Fuel
INITIAL_FUEL           // Starting fuel amount
FUEL_USAGE_MAIN        // Fuel consumed per frame by main thruster
FUEL_USAGE_SIDE        // Fuel consumed per frame by side thrusters

// Terrain
TERRAIN_POINTS         // Resolution of terrain (more = smoother)
MIN_LANDING_PAD_WIDTH  // Minimum pad width
MAX_LANDING_PAD_WIDTH  // Maximum pad width

// Scoring
SCORE_BASE_LANDING     // Base points for landing
SCORE_FUEL_BONUS       // Points per fuel unit remaining
SCORE_SPEED_BONUS      // Bonus for very gentle landing
SCORE_CENTER_BONUS     // Bonus for center pad landing

// Gameplay
MAX_HIGH_SCORES        // Number of high scores tracked
STAR_COUNT            // Number of background stars
```

---

## Questions?

If you're unsure about something:
1. Check the inline comments in `lander.cpp`
2. Look at similar existing code
3. Refer to this document
4. Ask the user for clarification

Remember: **Simplicity is key.** This is meant to be a clean, understandable, single-file game that demonstrates game programming concepts without overwhelming complexity.
