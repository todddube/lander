# Changelog

All notable changes to Lunar Lander will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-11-10

### Added

#### Core Gameplay
- Classic lunar lander physics with gravity and thrust simulation
- Main thruster for upward thrust (rotates with lander)
- Side thrusters for rotation control (left/right)
- Fuel management system with limited fuel per level
- Velocity-based landing safety checks
- Landing pad collision detection

#### Level System
- Progressive difficulty across unlimited levels
- Procedural terrain generation
- Dynamic landing pad placement
- Increasing terrain roughness per level
- Bonus fuel per level advancement

#### Scoring System
- Base landing score multiplied by level
- Fuel conservation bonus (2 pts per unit remaining)
- Speed bonus for very gentle landings
- Center pad bonus for precision landing
- High score tracking (top 10)
- Persistent high score storage with player names

#### Visual Features
- Starfield background with 100 stars
- Vector-based lander rendering
- Animated thrust flames
- Particle explosion effects on crashes
- Green highlighted landing pads
- Real-time HUD displaying:
  - Current score
  - Level number
  - Lives remaining
  - Fuel gauge
  - Velocity indicator
  - Speed warning when too fast

#### Game States
- Title screen with instructions
- Active gameplay state
- Landing success state with message
- Crash state with explosion
- Game over screen with final stats
- High score entry screen
- High score display screen
- Pause functionality

#### Input System
- Dual control schemes (Arrow keys / WASD)
- Thrust controls with fuel consumption
- Menu navigation
- Text entry for high score names
- Pause/resume functionality
- Quick restart from game over

#### Sound Effects
- Thrust beep during thruster activation
- Crash explosion sound
- Landing success musical sequence
- Menu selection confirmation

### Technical

#### Architecture
- Single-file C++ design (~1200 lines)
- Modern C++17 standard compliance
- Win32 GDI-based rendering
- Double-buffered graphics (flicker-free)
- 60 FPS target frame rate with timer-based updates
- Entity-component structure for game objects

#### Graphics
- Vector2 math library for 2D operations
- Rotation matrix transformations for lander
- Linear interpolation for terrain collision
- Procedural terrain generation with configurable difficulty
- Particle system with lifetime tracking

#### Data Persistence
- Binary file storage for high scores
- Automatic save/load on startup/exit
- Graceful handling of missing score file

#### Build System
- CMake 3.20+ support with version injection
- MSVC compiler support with /W4 warnings
- MinGW/GCC support with full warnings
- Smart build.bat script with auto-detection
- Windows resource file compilation
- Manifest embedding for DPI awareness

#### Compatibility
- Windows 7, 8, 8.1, 10, 11 support
- Per-monitor DPI awareness (V2)
- No administrative privileges required
- No external dependencies (Windows SDK only)

#### Code Quality
- Comprehensive inline documentation
- Doxygen-style function comments
- Clear section headers and organization
- Modern C++ practices (constexpr, noexcept)
- Type-safe enums (enum class)
- RAII for resource management

---

## Future Ideas

### Gameplay Enhancements
- Multiple landing pads per level with different point values
- Moving landing pads for increased difficulty
- Wind effects that push the lander
- Bonus fuel pickups in flight
- Enemy UFOs or obstacles
- Time bonus for fast landings
- Perfect landing achievements

### Visual Improvements
- Color gradients for thrust flames
- Animated star twinkle effects
- Terrain shadows or depth
- Multiple lander skins/colors
- Landing pad animations
- Screen shake on crash
- Smooth camera following lander

### Audio Enhancements
- Continuous thruster sound (varies with power)
- Ambient space music
- Different crash sounds based on impact
- Fuel warning beep when low
- Level complete fanfare
- High score celebration sound

### Features
- Replay system to watch previous attempts
- Ghost replay of best landing
- Statistics tracking (total landings, crashes, etc.)
- Mission mode with specific objectives
- Training mode with unlimited fuel
- Two-player split-screen or hot-seat mode
- Online leaderboards
- Steam achievements integration

### Technical
- Config file for custom key bindings
- Fullscreen mode support
- Resolution scaling options
- Save game state for continuation
- Mod support for custom terrains
- Level editor
- OpenGL or DirectX rendering option

---

## Version History

[1.0.0]: https://github.com/yourusername/lander/releases/tag/v1.0.0
