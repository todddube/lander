# Cross-Platform Porting Plan: Windows + macOS

This document lays out the full strategy, effort estimates, and technical details for making Lunar Lander build and run on both Windows and macOS while preserving the single-file design philosophy.

---

## Table of Contents

1. [Approach Options](#approach-options)
2. [Recommended Approach](#recommended-approach)
3. [Dependency Inventory](#dependency-inventory)
4. [Code Changes Required](#code-changes-required)
5. [Build System Changes](#build-system-changes)
6. [Effort Estimates](#effort-estimates)
7. [Implementation Order](#implementation-order)
8. [Risk & Gotchas](#risk--gotchas)

---

## Approach Options

### Option A: Abstraction Layer with Native APIs (Recommended)

Keep the single-file design. Use `#ifdef _WIN32` / `#ifdef __APPLE__` preprocessor guards to switch between Win32 (Windows) and Cocoa/Core Graphics (macOS) implementations. Platform-specific code lives behind a thin internal abstraction within `lander.cpp`.

**Pros:** No external dependencies, stays true to the project's self-contained philosophy, maximum control.
**Cons:** More code to write and maintain, Objective-C++ required for macOS Cocoa calls.

### Option B: SDL2 Cross-Platform Library

Replace all Win32 calls with SDL2 (Simple DirectMedia Layer), which provides window management, 2D rendering, input, and audio on both platforms.

**Pros:** Single codepath for both platforms, well-documented, widely used.
**Cons:** Adds an external dependency (SDL2), users must install SDL2 or bundle it, departs from the "no dependencies" philosophy.

### Option C: SFML Cross-Platform Library

Similar to SDL2 but with a more C++-native API.

**Pros:** Clean C++ API, easy 2D rendering.
**Cons:** Same dependency tradeoff as SDL2, less widely deployed.

---

## Recommended Approach

**Option A: Abstraction Layer with Native APIs** — this best fits the project's design philosophy of zero external dependencies and single-file simplicity.

The strategy:

1. Define a **Platform Abstraction Layer (PAL)** — a set of internal functions and types that both platforms implement
2. Use `#ifdef _WIN32` and `#ifdef __APPLE__` to compile the correct implementation
3. On macOS, use **Objective-C++** (`.mm` file extension or `-ObjC++` flag) to call Cocoa and Core Graphics APIs
4. Game logic, physics, particles, scoring, terrain — all remain untouched

---

## Dependency Inventory

### What Must Be Replaced (Platform-Specific)

| Subsystem | Windows API | macOS Replacement | Lines Affected |
|---|---|---|---|
| Window creation & event loop | `RegisterClass`, `CreateWindowEx`, `GetMessage`, `DispatchMessage`, `WindowProc` | `NSApplication`, `NSWindow`, `NSView`, `NSEvent` (Cocoa) | ~80 lines |
| Graphics rendering | GDI: `CreatePen`, `LineTo`, `Polyline`, `Polygon`, `Ellipse`, `SetPixel`, `TextOut`, `CreateFont`, `BitBlt` (~25 functions) | Core Graphics: `CGContextRef`, `CGContextStrokePath`, `CGContextFillPath`, `CGContextSetRGBStrokeColor`, `CTFont` | ~500 lines |
| Double buffering | `CreateCompatibleDC`, `CreateCompatibleBitmap`, `BitBlt` | `NSBitmapImageRep` or layer-backed `NSView` (automatic) | ~20 lines |
| Sound (PCM audio) | `waveOutOpen`, `waveOutWrite`, `waveOutPrepareHeader` | `AudioQueueNewOutput`, `AudioQueueEnqueueBuffer` (AudioToolbox) | ~80 lines |
| Sound (Beep) | `Beep(freq, duration)` | Generate sine wave buffer, play via AudioQueue | ~30 lines |
| Timer / game loop | `SetTimer`, `WM_TIMER` | `CVDisplayLink` or `NSTimer` | ~10 lines |
| Threading | `CreateThread`, `WaitForSingleObject`, `CloseHandle`, `Sleep` | `std::thread`, `std::this_thread::sleep_for` (already portable C++17) | ~15 lines |
| String handling | `wchar_t`, `L""`, `StringCchPrintf`, `StringCchCopy`, `std::wofstream` | `char` / `std::string`, `snprintf`, `std::ofstream` | ~60 lines |
| Entry point | `WinMain` | `int main()` (or `NSApplicationMain`) | ~15 lines |
| High score file I/O | Binary read/write with `wchar_t` paths and `wchar_t` struct fields | Binary read/write with `char` paths and `char` struct fields | ~40 lines |
| Settings file I/O | `wchar_t` based INI parsing | `char` based INI parsing | ~30 lines |
| Resource file | `lander.rc.in` (version info) | `Info.plist` (app bundle metadata) | New file |
| Manifest | `lander.manifest` (DPI, UAC) | Not needed | N/A |
| Build script | `build.bat` | `build.sh` | New file |

### What Stays the Same (Already Portable)

| Component | Notes |
|---|---|
| Game physics (`UpdateGame`, `ApplyThrust`) | Pure math, no platform calls |
| Terrain generation (`InitTerrain`) | Uses `<random>`, `<cmath>` — portable |
| Particle system | Pure data structures and math |
| Collision detection | Pure geometry |
| Scoring logic | Pure arithmetic |
| Game state machine | Enum + switch — portable |
| Star field | Data + rendering abstracted |
| Data structures (`Vector2`, `Lander`, `TerrainPoint`, `Particle`, `Star`) | Plain C++ structs |
| Constants section | All `constexpr` / `const` values |
| Standard includes (`<vector>`, `<cmath>`, `<algorithm>`, `<random>`, `<string>`, `<fstream>`) | C++17 standard library |

---

## Code Changes Required

### 1. Platform Abstraction Layer (PAL)

Define these internal abstractions at the top of `lander.cpp`:

```cpp
// ============================================================================
// Platform Abstraction Layer
// ============================================================================

// Color type (replaces COLORREF)
using PlatColor = uint32_t;  // Stored as 0x00RRGGBB on all platforms

inline PlatColor MakeColor(uint8_t r, uint8_t g, uint8_t b) {
    return (r << 16) | (g << 8) | b;
}
inline uint8_t ColorR(PlatColor c) { return (c >> 16) & 0xFF; }
inline uint8_t ColorG(PlatColor c) { return (c >> 8) & 0xFF; }
inline uint8_t ColorB(PlatColor c) { return c & 0xFF; }

// Platform drawing context (opaque, passed to render functions)
struct PlatContext;  // Defined per-platform

// Platform functions (implemented per-platform)
void PlatDrawLine(PlatContext* ctx, int x1, int y1, int x2, int y2, PlatColor color, int width = 1);
void PlatDrawPolyline(PlatContext* ctx, const POINT* pts, int count, PlatColor color, int width = 1);
void PlatDrawPolygon(PlatContext* ctx, const POINT* pts, int count, PlatColor fillColor);
void PlatDrawEllipse(PlatContext* ctx, int x, int y, int rx, int ry, PlatColor color, int width = 1);
void PlatDrawPixel(PlatContext* ctx, int x, int y, PlatColor color);
void PlatDrawRect(PlatContext* ctx, int x, int y, int w, int h, PlatColor fillColor);
void PlatDrawText(PlatContext* ctx, const char* text, int x, int y, PlatColor color,
                  int fontSize, bool bold = false, bool centered = false);
void PlatMeasureText(PlatContext* ctx, const char* text, int fontSize, int* width, int* height);
```

### 2. String Migration: `wchar_t` to `char`

On macOS (and POSIX in general), `wchar_t` is 4 bytes (UTF-32) and file APIs use `char*` (UTF-8). The cleanest approach:

| Current (Windows) | New (Cross-Platform) |
|---|---|
| `wchar_t buffer[256]` | `char buffer[256]` |
| `L"string literal"` | `"string literal"` |
| `StringCchPrintf(buf, size, fmt, ...)` | `snprintf(buf, size, fmt, ...)` |
| `StringCchCopy(dst, size, src)` | `strncpy(dst, src, size)` or `snprintf` |
| `std::wofstream` / `std::wifstream` | `std::ofstream` / `std::ifstream` |
| `std::wstring` | `std::string` |
| `const wchar_t* HIGH_SCORE_FILE` | `const char* HIGH_SCORE_FILE` |
| `wchar_t name[32]` in `HighScore` | `char name[32]` in `HighScore` |

**This change affects both platforms.** Windows supports `char*` / UTF-8 just fine for file I/O and `snprintf`. GDI's `TextOutA` / `DrawTextA` accept `char*`. So we can unify on `char` everywhere.

### 3. Entry Point

```cpp
#ifdef _WIN32
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int nCmdShow) {
    // Windows window creation and message loop
}
#elif defined(__APPLE__)
int main(int argc, char* argv[]) {
    // Cocoa NSApplication setup and run loop
}
#endif
```

### 4. Window & Event Loop (macOS)

Replace the Win32 window/message loop with Cocoa:

```objc
// macOS implementation (Objective-C++ within #ifdef __APPLE__)
@interface GameView : NSView
@end

@implementation GameView
- (void)drawRect:(NSRect)dirtyRect {
    // Get CGContext, call RenderGame()
}
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent*)event {
    // Map event.keyCode to game key states
}
- (void)keyUp:(NSEvent*)event {
    // Clear game key states
}
@end
```

Use `NSTimer` or `CVDisplayLink` for the game loop (replaces `SetTimer` / `WM_TIMER`).

### 5. Graphics (macOS)

Replace GDI calls with Core Graphics (`CGContext`):

| GDI Function | Core Graphics Equivalent |
|---|---|
| `CreatePen` + `SelectObject` | `CGContextSetStrokeColorWithColor` + `CGContextSetLineWidth` |
| `MoveToEx` + `LineTo` | `CGContextMoveToPoint` + `CGContextAddLineToPoint` + `CGContextStrokePath` |
| `Polyline` | `CGContextAddLines` + `CGContextStrokePath` |
| `Polygon` | `CGContextAddLines` + `CGContextFillPath` |
| `Ellipse` | `CGContextFillEllipseInRect` or `CGContextStrokeEllipseInRect` |
| `SetPixel` | `CGContextFillRect` with 1x1 rect |
| `FillRect` | `CGContextFillRect` |
| `CreateFont` + `TextOut` | `CTFontCreateWithName` + `CTLineDraw` (Core Text) |
| `BitBlt` (double buffer) | Layer-backed NSView handles this automatically |
| `RGB(r,g,b)` | `CGColorCreateGenericRGB(r/255.0, g/255.0, b/255.0, 1.0)` |

**Key difference:** Core Graphics uses a coordinate system where Y=0 is at the **bottom** of the screen (flipped from GDI). Apply a transform once:
```objc
CGContextTranslateCTM(ctx, 0, viewHeight);
CGContextScaleCTM(ctx, 1.0, -1.0);
```

### 6. Sound (macOS)

Replace WinMM `waveOut*` with AudioToolbox `AudioQueue`:

```cpp
#ifdef __APPLE__
#include <AudioToolbox/AudioToolbox.h>

// AudioQueue callback fills buffers with generated PCM samples
void AudioCallback(void* userData, AudioQueueRef queue, AudioQueueBufferRef buffer) {
    // Generate sine wave or silence
}

void InitAudio() {
    AudioStreamBasicDescription fmt = {};
    fmt.mSampleRate = 44100;
    fmt.mFormatID = kAudioFormatLinearPCM;
    fmt.mFramesPerPacket = 1;
    fmt.mChannelsPerFrame = 1;
    fmt.mBitsPerChannel = 16;
    fmt.mBytesPerFrame = 2;
    fmt.mBytesPerPacket = 2;
    fmt.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    AudioQueueNewOutput(&fmt, AudioCallback, nullptr, nullptr, nullptr, 0, &audioQueue);
}
#endif
```

Replace `Beep(freq, duration)` with a helper that generates a sine wave buffer at the given frequency and plays it through the AudioQueue.

### 7. Threading

Replace Windows threading with C++ standard library (works on both platforms):

| Windows | C++17 Standard |
|---|---|
| `CreateThread(...)` | `std::thread t(func, args...)` |
| `WaitForSingleObject(handle, INFINITE)` | `t.join()` |
| `CloseHandle(handle)` | Automatic (RAII) |
| `Sleep(ms)` | `std::this_thread::sleep_for(std::chrono::milliseconds(ms))` |
| `ZeroMemory(ptr, size)` | `std::memset(ptr, 0, size)` |
| `volatile BOOL` flag | `std::atomic<bool>` |

This change benefits both platforms — it's cleaner C++17 and eliminates Windows-specific threading.

### 8. Key Code Mapping

Map platform key codes to a common enum:

```cpp
enum class GameKey {
    UP, DOWN, LEFT, RIGHT,
    THRUST,     // Space
    ESCAPE,
    ENTER,
    BACKSPACE,
    KEY_W, KEY_A, KEY_S, KEY_D,
    KEY_P, KEY_Q, KEY_R, KEY_Y, KEY_N, KEY_M
};

// keys[] array indexed by GameKey instead of VK_* codes
bool keys[static_cast<int>(GameKey::COUNT)] = {};
```

### 9. POINT Struct

Replace Windows `POINT` with a portable version:

```cpp
#ifndef _WIN32
struct POINT { long x, y; };
#endif
```

Or use the existing `Vector2` struct where appropriate.

---

## Build System Changes

### CMakeLists.txt Updates

```cmake
cmake_minimum_required(VERSION 3.16)
project(LunarLander)

# Read version
file(READ "${CMAKE_SOURCE_DIR}/VERSION" VERSION_STRING)
string(STRIP "${VERSION_STRING}" VERSION_STRING)

# Common sources
set(SOURCES lander.cpp)

if(WIN32)
    add_executable(lander WIN32 ${SOURCES})
    target_link_libraries(lander user32 gdi32 winmm)
    # Existing manifest/resource handling
    configure_file(lander.rc.in ${CMAKE_BINARY_DIR}/lander.rc @ONLY)
    target_sources(lander PRIVATE ${CMAKE_BINARY_DIR}/lander.rc)

elseif(APPLE)
    # Objective-C++ for Cocoa integration
    set_source_files_properties(lander.cpp PROPERTIES
        COMPILE_FLAGS "-x objective-c++"
    )
    add_executable(lander MACOSX_BUNDLE ${SOURCES})

    # Link macOS frameworks
    target_link_libraries(lander
        "-framework Cocoa"
        "-framework CoreGraphics"
        "-framework AudioToolbox"
        "-framework QuartzCore"
    )

    # App bundle metadata
    set_target_properties(lander PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/Info.plist.in"
        MACOSX_BUNDLE_BUNDLE_NAME "Lunar Lander"
        MACOSX_BUNDLE_BUNDLE_VERSION "${VERSION_STRING}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${VERSION_STRING}"
    )
endif()

target_compile_features(lander PRIVATE cxx_std_17)
```

### New Files for macOS

| File | Purpose |
|---|---|
| `build.sh` | Shell script equivalent of `build.bat` for macOS |
| `Info.plist.in` | App bundle metadata (replaces `lander.rc.in` role) |

### build.sh (new)

```bash
#!/bin/bash
# Build Lunar Lander on macOS
set -e

mkdir -p build
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")

if command -v cmake &>/dev/null; then
    cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release
else
    # Direct clang++ build
    clang++ -std=c++17 -O2 -Wall -Wextra \
        -x objective-c++ \
        -framework Cocoa \
        -framework CoreGraphics \
        -framework AudioToolbox \
        -framework QuartzCore \
        -DLANDER_VERSION_STRING="\"$VERSION\"" \
        -o build/lander \
        lander.cpp
fi
echo "Build complete: build/lander"
```

### Info.plist.in (new)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Lunar Lander</string>
    <key>CFBundleIdentifier</key>
    <string>com.lunarlander.game</string>
    <key>CFBundleVersion</key>
    <string>@VERSION_STRING@</string>
    <key>CFBundleShortVersionString</key>
    <string>@VERSION_STRING@</string>
    <key>CFBundleExecutable</key>
    <string>lander</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
```

---

## Effort Estimates

### By Component

| Component | Effort | Description |
|---|---|---|
| **PAL type/function definitions** | Small | Define `PlatColor`, `PlatContext`, draw function signatures |
| **String migration (wchar_t → char)** | Medium | ~60 locations, mechanical but tedious, affects both platforms |
| **Threading migration** | Small | ~15 lines, replace with `std::thread` / `std::atomic` |
| **Windows PAL implementation** | Medium | Wrap existing GDI calls behind PAL functions |
| **macOS window + event loop** | Large | NSApplication, NSWindow, NSView, keyboard handling (~150 lines Obj-C++) |
| **macOS graphics (Core Graphics)** | Large | Reimplement all draw calls (~300 lines), coordinate flip, text rendering |
| **macOS sound (AudioToolbox)** | Medium | AudioQueue setup, sine wave generation, buffer management (~100 lines) |
| **Game logic refactoring** | Small | Replace `COLORREF`→`PlatColor`, `POINT`→portable, remove `RGB()` macro usage |
| **Build system (CMake)** | Small | Platform conditionals in CMakeLists.txt |
| **Build script (build.sh)** | Small | New shell script for macOS |
| **Info.plist** | Small | New file, straightforward |
| **Testing & debugging** | Large | Verify rendering, input, sound, game feel on macOS |

### Overall Scope

| Metric | Estimate |
|---|---|
| New lines of code (macOS platform layer) | ~600-800 |
| Modified lines (shared code refactoring) | ~200-300 |
| New files | 2-3 (`build.sh`, `Info.plist.in`, possibly rename `.cpp` → `.mm` or add compile flag) |
| Existing file changes | `lander.cpp`, `CMakeLists.txt` |

---

## Implementation Order

### Phase 1: Foundation (Do First)

1. **String migration** — Convert all `wchar_t` / `L""` to `char` / `""` and `snprintf`. This is mechanical and benefits code clarity on both platforms. Test that Windows still works after this change.

2. **Threading migration** — Replace `CreateThread` / `Sleep` / etc. with `std::thread` / `std::this_thread`. Portable C++17, no platform #ifdefs needed.

3. **Define PAL types** — `PlatColor`, `POINT` portability, `GameKey` enum.

### Phase 2: Abstraction (Refactor Rendering)

4. **Define PAL draw functions** — The function signatures listed above.

5. **Windows PAL implementation** — Wrap existing GDI calls behind PAL functions. Verify Windows still works identically.

6. **Refactor `RenderGame()`** — Change all direct GDI calls to use PAL functions. This is the largest single change.

### Phase 3: macOS Implementation

7. **macOS entry point & window** — `NSApplication`, `NSWindow`, `GameView : NSView`, keyboard events, game loop timer.

8. **macOS graphics** — Core Graphics implementation of all PAL draw functions.

9. **macOS sound** — AudioToolbox/AudioQueue implementation.

### Phase 4: Build & Polish

10. **Build system** — Update `CMakeLists.txt`, create `build.sh`, create `Info.plist.in`.

11. **Testing** — Full gameplay testing on both platforms.

12. **CI/CD** — Update GitHub Actions workflow for macOS builds (add `macos-latest` runner).

---

## Risk & Gotchas

### Coordinate System Flip
Core Graphics has Y=0 at bottom, GDI has Y=0 at top. A single `CGContextScaleCTM(ctx, 1, -1)` transform at the start of each frame handles this, but text rendering may need additional attention to avoid upside-down text.

### Objective-C++ Mixing
The macOS Cocoa API requires Objective-C (or Objective-C++). Since the game is C++, the file must be compiled as Objective-C++ on macOS. This is done via compiler flag (`-x objective-c++`) without changing the `.cpp` extension, or by renaming to `.mm`. The `-x objective-c++` flag approach is cleaner for keeping a single filename.

### Text Rendering Differences
Core Text (macOS) and GDI (Windows) render fonts differently. Text sizes, spacing, and appearance will not be pixel-identical. The game's UI layouts may need minor adjustments per platform to look good.

### SetPixel Performance
`SetPixel` on GDI is already slow; the Core Graphics equivalent (`CGContextFillRect` with a 1x1 rect) is even slower. For the star field and particle rendering, consider drawing into a raw pixel buffer and blitting it. This affects ~30 `SetPixel` calls per frame, which should still be acceptable at 60 FPS for this game's complexity.

### Sound Timing
`Beep()` on Windows is synchronous and blocks the calling thread. On macOS, the replacement (AudioQueue sine wave) is asynchronous. The intro sound sequence and landing jingle use timed `Beep()` calls in sequence — these need to be adapted to use callbacks or timed dispatches.

### High Score File Format
The current binary format writes `wchar_t name[32]` directly. After the string migration to `char`, the on-disk format changes. Existing Windows save files become incompatible. Either:
- Accept the format break (recommended — it's a game, scores are not critical)
- Write a migration path that reads the old format

### Retina / HiDPI
macOS Retina displays have 2x pixel density. The game's `WINDOW_WIDTH` / `WINDOW_HEIGHT` constants define the logical size. Core Graphics handles scaling automatically when using `NSView` with `wantsBestResolutionOpenGLSurface` or layer backing. No code changes needed, but visual testing is important.

### macOS Minimum Version
Targeting macOS 14+ (Sonoma, 2023) is reasonable and gives access to all modern Cocoa and Core Graphics APIs. Set `LSMinimumSystemVersion` in Info.plist and `-mmacosx-version-min=14.0` in compiler flags.

### GitHub Actions CI
The existing release workflow (`release.yml`) runs on `windows-latest`. Add a parallel `macos-latest` job that builds with `clang++` or CMake and produces a `.app` bundle or `.dmg`.

---

## Implementation Status

### Phase 1: Foundation — COMPLETE

All Phase 1 changes have been implemented in `lander.cpp` on the `phase1-foundation` branch:

| Task | Status | Details |
|---|---|---|
| String migration (`wchar_t` -> `char`) | Done | ~60 locations converted. All `L""` literals, `StringCchPrintf`, `StringCchCopy`, `std::wofstream`/`wifstream` replaced with `char`-based equivalents. GDI calls switched to explicit `A`-suffix variants (`TextOutA`, `DrawTextA`, `CreateFontA`, `RegisterClassA`, `CreateWindowExA`, `DefWindowProcA`, `GetTextExtentPoint32A`). |
| Threading migration | Done | `CreateThread`/`WaitForSingleObject`/`CloseHandle` replaced with `std::thread`/`.join()`. `Sleep()` replaced with `std::this_thread::sleep_for()`. `volatile bool` replaced with `std::atomic<bool>`. `ZeroMemory` replaced with `std::memset`. |
| PAL types defined | Done | `PlatColor` type (`uint32_t`, stored as `0x00RRGGBB`), `MakeColor`/`ColorR`/`ColorG`/`ColorB` helpers, `PlatColorToNative`/`NativeToPlatColor` conversion functions, portable `POINT` struct for non-Windows. |
| `COLORREF` -> `PlatColor` in structs | Done | `Particle::color` and `Shockwave::color` changed from `COLORREF` to `PlatColor`. |
| UNICODE/strsafe.h removal | Done | `#define UNICODE`/`_UNICODE` removed, `<strsafe.h>` removed, `<windows.h>` wrapped in `#ifdef _WIN32`. |
| New includes added | Done | `<thread>`, `<atomic>`, `<chrono>`, `<cstring>`, `<cstdio>`, `<cstdint>`. |

### Phase 2: Abstraction — COMPLETE

All Phase 2 changes have been implemented in `lander.cpp` on the `phase1-foundation` branch:

| Task | Status | Details |
|---|---|---|
| PAL drawing interface defined | Done | `PlatContext` (opaque struct), `PlatTextAlign` enum, 14 PAL function signatures declared: `PlatBeginFrame`, `PlatEndFrame`, `PlatClear`, `PlatDrawLine`, `PlatDrawPolyline`, `PlatDrawPolygonFilled`, `PlatDrawEllipseOutline`, `PlatDrawRect`, `PlatDrawRectOutline`, `PlatDrawPixel`, `PlatDrawText`, `PlatDrawTextXY`, `PlatMeasureTextWidth`. |
| Windows PAL implementation | Done | Full `#ifdef _WIN32` implementation wrapping GDI calls. `PlatContext` struct wraps `HDC`/`HBITMAP`. Each PAL function manages its own GDI object lifecycle (create/select/use/restore/delete). `PlatInitContext` handles double-buffer DC creation. |
| RenderGame refactored to use PAL | Done | All ~870 lines of `RenderGame()` converted from direct GDI calls to PAL function calls. Function signature changed from `void RenderGame(HDC hdc)` to `void RenderGame(PlatContext* ctx)`. No direct GDI calls remain in rendering code. |
| WindowProc WM_PAINT updated | Done | Paint handler now calls `PlatInitContext(hdc)` -> `PlatBeginFrame()` -> `RenderGame(ctx)` -> `PlatEndFrame(ctx, hdc)`. |

### Phase 3: macOS Implementation — NOT STARTED

Remaining work: Cocoa window/event loop, Core Graphics PAL implementation, AudioToolbox sound.

### Phase 4: Build & Polish — NOT STARTED

Remaining work: CMakeLists.txt cross-platform update, `build.sh`, `Info.plist.in`, CI/CD updates.
