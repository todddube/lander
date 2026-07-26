# Lunar Lander - AI Development Guide

This document provides context and guidelines for AI assistants (like Claude) working on the Lunar Lander codebase.

---

## Project Overview

**Lunar Lander** is a classic arcade-style game written in modern C++17 for **Windows and macOS**.
It's a single-file application that uses only each platform's native SDK for graphics, input, and
sound — Win32 (GDI/WinMM) on Windows and Cocoa/CoreGraphics/CoreText/AudioToolbox on macOS. No
third-party libraries are required.

Platform-specific code lives behind a **Platform Abstraction Layer (PAL)** and `#ifdef _WIN32` /
`#ifdef __APPLE__` guards, all within the single `lander.cpp`. On macOS the file is compiled as
Objective-C++ (`-x objective-c++`). Linux is not currently supported.

### Design Philosophy
- **Simplicity**: Single C++ file, no external dependencies
- **Classic gameplay**: Faithful to the original lunar lander concept
- **Modern code**: C++17 features, clean architecture, well-documented
- **Self-contained**: Everything needed to build and run in one directory
- **Portable core, native shells**: Game logic is platform-independent; only the PAL backends and
  entry points are platform-specific

> **See also:** [`recommendation.md`](recommendation.md) for the current best-practices review and
> prioritized cleanup roadmap, and [`platform.md`](platform.md) for the cross-platform porting plan
> and status.

---

## Quick Build Commands

### Windows

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

### macOS

```bash
# Smart build (prefers CMake, falls back to direct clang++)
./build_mac.sh

# CMake build
cmake -B build -S .
cmake --build build

# Direct clang++ (compiled as Objective-C++, links Apple frameworks)
clang++ -std=c++17 -O2 -x objective-c++ \
    -framework Cocoa -framework CoreGraphics \
    -framework CoreText -framework AudioToolbox \
    -o build/lander lander.cpp
```

---

## Architecture

### Single-File Design
The entire game is in `lander.cpp` (~3,300 lines). This intentional design choice:
- Makes the codebase easy to understand and navigate
- Eliminates build complexity
- Allows quick iteration and testing
- Serves as an educational example

The file grew substantially during the cross-platform migration because it now holds **two full
graphics backends, two audio backends, and two OS entry points** alongside the shared game logic.
The portable game logic itself remains compact; the size is platform-shell code behind `#ifdef`s.

**DO NOT** split into multiple files unless explicitly requested.

### Code Organization

The file is organized into clear sections marked by banner comments:

```cpp
// ============================================================================
// Section Name
// ============================================================================
```

**Sections** (in order — approximate line ranges):
1. **Platform Configuration** - `#include` guards for `<windows.h>` (Win) / Cocoa+CoreGraphics+CoreText+AudioToolbox (mac); VK_* mappings for macOS
2. **System / Library Includes** - Standard library headers; version header (`__has_include("version.h")` with `-D` fallback)
3. **Platform Abstraction Types** - `PlatColor`, color helpers, portable `POINT`
4. **Platform Abstraction Layer (PAL) — Drawing Interface** - `PlatContext` + `PlatDraw*` declarations
5. **Game Constants** - Tweakable gameplay parameters
6. **Core Data Structures** - Vector2, Lander, TerrainPoint, Particle, Shockwave, Star, GameSettings, etc.
7. **Global Game State** - All game state variables (currently ~30 file-scope globals)
8. **Function Prototypes** - Forward declarations
9. **Initialization Functions** - InitGame(), InitTerrain(), etc.
10. **Game Loop Functions** - UpdateGame(), RenderGame()
11. **Physics Functions** - UpdatePhysics(), ApplyThrust(), collision detection
12. **Particle System** - Explosion and particle effects
13. **Rendering Functions** - All drawing code (calls PAL, not GDI/CG directly)
14. **High Score Functions** - Save/load/update scores
15. **Settings Functions** - Load/save `lander.ini`
16. **Sound Functions** - Shared PCM generators + platform sinks (WinMM waveOut / macOS AudioQueue)
17. **Utility Functions** - Lerp, Clamp, etc.
18. **Portable Event Handlers** - `HandleKeyDown` / `HandleQuit`, shared by both platforms
19. **PAL Windows Implementation** - GDI-backed `Plat*` functions (`#ifdef _WIN32`)
20. **PAL macOS Implementation** - CoreGraphics/CoreText/AudioToolbox `Plat*` functions (`#ifdef __APPLE__`, Objective-C++)
21. **macOS Window & Entry Point** - `NSApplication`/`NSWindow`/`NSView`, `main()`
22. **Windows Message Handling** - WindowProc(), WinMain()

### Platform Abstraction Layer (PAL)

Rendering is fully decoupled from the OS. `RenderGame(PlatContext* ctx)` calls only `Plat*`
functions (e.g. `PlatDrawLine`, `PlatDrawPolygonFilled`, `PlatDrawText`), declared once and
implemented twice — once with GDI (`#ifdef _WIN32`) and once with CoreGraphics/CoreText
(`#ifdef __APPLE__`). Both backends present a **top-left origin** coordinate system; the macOS
backend applies a Y-flip transform so game code needs no per-platform coordinate logic.

Colors use the portable `PlatColor` type (`0x00RRGGBB`); `PlatColorToNative` /
`NativeToPlatColor` convert to/from Windows `COLORREF` where needed.

**When adding rendering:** add a `Plat*` call, and implement it in *both* backends. Never call GDI
or CoreGraphics directly from game/render logic.

> **Note:** Audio and the main-loop timer are **not** yet behind a PAL-style interface — they are
> `#ifdef`-branched with duplicated function names. See [`recommendation.md`](recommendation.md)
> §2.4 for the plan to finish those seams.

### Game Loop

The game uses a **timer-based loop** (not a traditional while loop) on both platforms:

**Windows** (Win32 message loop):
```cpp
// In WM_CREATE:
SetTimer(hwnd, 1, TARGET_FRAME_TIME, nullptr);  // 16ms = ~60 FPS

// In WM_TIMER:
UpdateGame();
InvalidateRect(hwnd, nullptr, FALSE);           // Triggers WM_PAINT

// In WM_PAINT:
PlatInitContext(hdc); PlatBeginFrame();
RenderGame(ctx);
PlatEndFrame(ctx, hdc);
```

**macOS** (Cocoa run loop): an `NSTimer` at ~60 FPS calls `UpdateGame()` and marks the view dirty;
`GameView drawRect:` obtains a `CGContext`, wraps it in a `PlatContext`, and calls `RenderGame`.

Both approaches integrate with the native run loop and avoid a busy-wait. **Note:** the timer/loop
is not yet abstracted behind a common seam — see [`recommendation.md`](recommendation.md) §2.4.

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

Audio is **synthesized PCM**, not simple beeps. The DSP that generates samples is shared
(`GenerateRocketSound`, `GenerateExplosionSound`); only the output sink is platform-specific:

- **Windows:** WinMM `waveOut*` — double-buffered streaming for continuous thrust; a background
  thread refills buffers. Some short cues (menu/landing/intro) still use blocking `Beep()`.
- **macOS:** AudioToolbox `AudioQueue` — streaming thrust plus a `MacBeep` helper that synthesizes
  a sine-wave buffer for one-shot cues (fully asynchronous).

**Sound effects:**
- Thrust: continuous synthesized rocket rumble (streamed, varies over time)
- Crash: multi-phase synthesized explosion ("KABOOM")
- Landing / menu / intro: short tonal cues

**Note:** on Windows the remaining `Beep()` cues are synchronous (they block the calling thread).
Prefer the async PCM path; see [`recommendation.md`](recommendation.md) §1.3 and §2.4. Audio state
is touched from a background thread — keep DSP filter state per-stream and guard shared flags with
`std::atomic`.

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

`lander.rc.in` is the template for Windows version info; CMake runs `configure_file()` to produce
`build/lander.rc` (injecting the version). It's compiled by:
- CMake: Automatically as part of `add_executable()` (Windows only)
- build.bat: Calls `rc.exe` if available
- Manual: `rc.exe /fo build\lander.res build\lander.rc`

Link the `.res` file with the executable for embedded version info. macOS has no equivalent
resource step (bundle metadata would come from an `Info.plist`; the current build produces a bare
executable — see `CMakeLists.txt`).

---

## Platform-Specific Notes

### Windows API Usage (behind `#ifdef _WIN32`)

**Graphics (GDI):** `CreatePen`/`SelectObject`/`DeleteObject`, `MoveToEx`/`LineTo`/`Polyline`,
`TextOutA`/`DrawTextA`, `CreateFontA` — all wrapped by the Win32 PAL implementation.
**Input:** `WM_KEYDOWN`/`WM_KEYUP`, `WM_CHAR`, virtual key codes (`VK_UP`, `VK_SPACE`, …).
**Timing:** `SetTimer` / `WM_TIMER`.
**Audio:** WinMM `waveOut*` (streaming) + `Beep` (short cues).
**Entry point:** `WinMain`.

### macOS API Usage (behind `#ifdef __APPLE__`, Objective-C++)

**Graphics:** CoreGraphics (`CGContext*`) for shapes, CoreText (`CTFont`/`CTLine`) for text —
wrapped by the macOS PAL implementation. A Y-flip transform gives a top-left origin.
**Input:** `NSView keyDown:/keyUp:`; hardware keycodes mapped to the same `VK_*` values (see the
`VK_*` `#define`s at the top of the file).
**Timing:** `NSTimer` on the main run loop.
**Audio:** AudioToolbox `AudioQueue` (streaming) + `MacBeep` sine synthesis (short cues).
**Entry point:** `main()` → `NSApplication`.

### Strings / Encoding (both platforms)

- All strings are `char*` / `"string"` (UTF-8). **No `wchar_t` / `L""`.**
- Use `snprintf`, `strncpy`, `std::string`, `std::ifstream`/`std::ofstream`.
- On Windows, GDI is used via the `A`-suffix (ANSI/UTF-8) entry points (`TextOutA`, `DrawTextA`,
  `CreateFontA`, `RegisterClassA`, `CreateWindowExA`, `DefWindowProcA`).

### Compilation Requirements

**Windows — required libraries:** `user32.lib`, `gdi32.lib`, `winmm.lib`.
**macOS — required frameworks:** `Cocoa`, `CoreGraphics`, `CoreText`, `AudioToolbox`; compile with
`-x objective-c++`.

**Required flags (both):**
- `/std:c++17` or `-std=c++17` — C++17 standard
- `/W4` (MSVC) or `-Wall -Wextra -Wpedantic` (clang/GCC) — high warning level
- Windows: `WIN32` defined (GUI app)

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

**Cross-platform:** any change touching rendering, input, audio, timing, or file I/O must be
verified on **both Windows and macOS** — the two backends can diverge silently (e.g. text metrics,
audio timing, save-file layout). CI currently builds Windows only (see
[`recommendation.md`](recommendation.md) §4.2), so macOS verification is manual for now.

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
On Windows this is a GUI app, so `printf()` to stdout won't show. Use:
```cpp
// Windows
OutputDebugStringA("Debug message\n");            // View in debugger / DebugView
MessageBoxA(nullptr, "Debug message", "Debug", MB_OK);
```
On **macOS** the executable runs from a terminal, so `printf`/`fprintf(stderr, ...)` work directly,
and `NSLog(@"...")` appears in Console.app. (Note: strings are now `char*`/UTF-8 — no `L""`.)

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
