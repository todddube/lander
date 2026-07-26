# Lunar Lander — Code & Project Review

**Date:** 2026-07-25
**Reviewed version:** 1.0.2
**Scope:** `lander.cpp` (3,328 lines), build system, CI/CD, and project documentation.

This document captures a best-practices review of the codebase and a prioritized set of
recommendations. It is advisory: nothing here changes gameplay, and the items are ordered so
the highest-value, lowest-risk fixes come first.

---

## Executive Summary

The cross-platform migration is in good shape. The **rendering** layer is cleanly abstracted
behind a Platform Abstraction Layer (PAL) with two complete, conforming backends (Win32/GDI and
macOS/CoreGraphics+CoreText), and text has already moved off `wchar_t` to UTF-8 `char`. That is
the hard part of the port, and it was done well.

The remaining debt falls into three buckets:

1. **Documentation drift** — the docs no longer describe the code. `CLAUDE.md`, `platform.md`,
   and `CHANGELOG.md` all describe a ~1,200-line, Windows-only, `Beep()`-based game. The code is
   a 3,328-line cross-platform game with synthesized PCM audio. This is the single biggest
   maintenance risk because it misleads every future contributor (human or AI).
2. **A few real correctness/portability bugs** — an unguarded array access, non-portable binary
   save files, and blocking calls on the game loop.
3. **Structural debt** — all game state is global, and there is no testable logic core. The PAL
   proves the seam is achievable; it just hasn't been applied to logic/audio/timing yet.

### Health snapshot

| Area | Status | Notes |
|---|---|---|
| Rendering abstraction | 🟢 Good | Clean PAL, two backends, logic-agnostic |
| String/encoding portability | 🟢 Good | Migrated to UTF-8 `char` |
| Build system | 🟢 Good | CMake handles Win + mac; `build.bat` / `build_mac.sh` |
| Audio abstraction | 🟡 Partial | `#ifdef`-branched, not interface-abstracted; Windows still blocks on `Beep()` |
| Timing / main loop | 🟡 Partial | Two entry points, no `PlatTimer` seam |
| Correctness | 🟢 P1 fixed | OOB read, non-portable saves, blocking calls, audio races — all addressed |
| Architecture / testability | 🔴 Weak | All-global state, zero tests, no logic seam |
| CI/CD | 🔴 Windows-only | macOS code exists but is never built or shipped |
| Documentation accuracy | 🔴 Stale | Docs describe a different, older program |

---

## Priority 1 — Correctness & Portability (fix first)

> **Status: ✅ Addressed (2026-07-25).** All four items below are implemented in `lander.cpp` with
> Win32 + macOS parity. The macOS target builds clean under `-Wall -Wextra -Wpedantic`; the
> high-score format has a passing round-trip test. Details noted per item.

These are real defects, each with a concrete failure mode.

### 1.1 Unguarded terrain access — possible out-of-bounds read ✅
`lander.cpp:666` computes `terrain[landingPadEnd].x` with no bounds check. `landingPadEnd` can
equal `terrain.size()`. The render path already guards the equivalent access at `lander.cpp:1256`,
so the fix is to apply the same guard here.
**Fix:** clamp/verify `landingPadEnd < terrain.size()` before indexing.
**Done:** `InitTerrain` now clamps the pad into `[0, TERRAIN_POINTS-1]` at the root, and the
scoring site (`UpdateGame`) plus the render path both guard with strict `<` bounds.

### 1.2 Non-portable binary save files ✅
High scores are written/read by `reinterpret_cast`-ing the raw `HighScore` struct
(`lander.cpp:1745`, `1759`). Struct padding and endianness differ across compilers/platforms, so
a `lander_scores.dat` written on Windows may not read correctly on macOS (and vice-versa) — a
concrete regression now that the same code runs on both.
**Fix:** serialize field-by-field with fixed-width types, or write a small text/JSON format.
Version the file header so future format changes are detectable.
**Done:** `SaveHighScores`/`LoadHighScores` now use a versioned line-based **text** format
(`LANDER_HIGHSCORES 1` header, then `score level name` per line; the name is written last so it may
contain spaces). Unrecognized/old binary files are ignored gracefully (one-time reset, no garbage).
Round-trip verified by a standalone test.

### 1.3 Blocking calls on the game / UI thread ✅
- `std::this_thread::sleep_for(50ms)` inside `UpdateGame` on crash (`lander.cpp:678`) stalls the
  render loop.
- `PlaySound_Landing()` chains synchronous tone calls (~400–550 ms), and `PlaySound_Crash()` blocks
  ~1 s waiting for playback to finish — both invoked from `UpdateGame`, freezing rendering/input.
**Fix:** drive post-landing/post-crash delays off the existing frame timer (`stateTimer`) instead
of sleeping, and make the jingle/explosion asynchronous.
**Done:** removed the 50 ms sleep (the thrust thread is already `join()`ed, freeing the device);
`PlaySound_Crash` and `PlaySound_Landing` now run on detached threads on **both** platforms
(mirroring the existing intro-sound pattern), so `UpdateGame` never blocks.

### 1.4 Data-race hazards in the audio path ✅
- `PlaySound_Thrust` does a non-atomic check-then-act on `thrustSoundActive` before spawning the
  thread (`lander.cpp:1982-1984`) — two rapid calls can spawn two threads.
- DSP keeps mutable `static` filter state (`lander.cpp:1847`, `2007`) touched from the audio
  thread.
- `rand()` is used in the audio thread (`lander.cpp:1854`, `2014`) while the rest of the game uses
  the global `std::mt19937 gen` (`354-355`) from the main thread — inconsistent, and `gen` is not
  synchronized.
**Fix:** guard thread creation with an atomic compare-exchange; keep per-stream DSP state in a
struct owned by the audio thread; standardize on one RNG strategy (a thread-local `mt19937` for
audio).
**Done:** `PlaySound_Thrust`/`StopSound_Thrust` now use `compare_exchange_strong` on
`thrustSoundActive` (both platforms) so exactly one thread is created/joined; the DSP filter state
in both generators is now `thread_local` (per-thread, resets cleanly each session); and a new
thread-safe `AudioNoise()` (`thread_local std::mt19937`) replaces every `rand()` call in the audio
path, keeping audio off the main thread's shared `gen`.

---

## Priority 2 — Architecture & Testability

### 2.1 Pervasive global mutable state
~30 file-scope globals hold all game state: `lander`, the entity vectors, `gameState`,
`score`/`level`/`lives`, `keys[256]`, `settings`, the RNG, and audio handles
(`lander.cpp:322-379`). Every routine operates by side effect.
**Recommendation:** encapsulate into a `Game`/`World` struct that owns this state and can be
constructed and reset. This is the prerequisite for testing and for a clean pause/reset. It can be
done incrementally (start by grouping the entity vectors + score/level/lives).

### 2.2 No testable logic core / zero tests
The physics, collision, and scoring are pure math but cannot be linked into a test binary without
dragging in Win32/Cocoa, because they read/write globals and live in one TU with two OS entry
points. There are no tests.
**Recommendation:** once state is encapsulated (2.1), extract `UpdatePhysics`,
`CheckTerrainCollision`, and scoring into functions that take state by reference, and add a tiny
test target (CTest + a header-only assertion set, or Catch2). The PAL already inverts the drawing
dependency, so this is achievable.

### 2.3 Rendering is not side-effect-free
`RenderGame` mutates state: it calls `UpdateBackgroundLanders()` (`lander.cpp:1134`) and advances
`static int cursorBlink` (`lander.cpp:1550-1551`).
**Recommendation:** move those updates into `UpdateGame` so `RenderGame` is a pure read of state.
This makes frame timing correct if the loop is ever decoupled from paint.

### 2.4 Finish the abstraction the PAL started
- **Audio** is `#ifdef`-branched (`PlaySound_*` implemented twice) rather than behind a
  `PlatPlaySound`-style interface. Windows still uses blocking `Beep()` for menu/landing/intro
  while macOS synthesizes PCM — divergent behavior.
- **Timing/main loop** has no seam: `SetTimer`+`WM_TIMER` (`lander.cpp:3208`, `3219`) vs `NSTimer`
  (`3160`), with two separate entry points.
**Recommendation:** add a thin `PlatTimer`/run-loop seam and a `PlatPlaySound` interface mirroring
the drawing PAL, so the two backends converge on behavior.

### 2.5 Linux is not supported
`__linux__` appears nowhere. "Cross-platform" today means Windows + macOS. This is fine as a
stated scope, but the docs should say so (see 4.1), and a future SDL2 or X11/ALSA backend would
slot in behind the PAL.

---

## Priority 3 — Code Quality

| # | Issue | Location | Fix |
|---|---|---|---|
| 3.1 | Raw `new[]`/`delete[]` for audio buffers — not exception-safe | `1925-1926`, `2108` | Use `std::vector<short>` |
| 3.2 | Particle `type` is a magic `int` (0–5) | `233`, `1066`, `1294` | `enum class ParticleType` |
| 3.3 | Parallel settings arrays hardcoded to size 5, duplicated in two places | `2340-2349`, `1648-1654` | Single source of truth (array of structs / named count) |
| 3.4 | Per-frame `CreateFontA`/`DeleteObject` on every text draw | `2494-2520` | Cache fonts by (size, bold) |
| 3.5 | CoreText attributed-string setup copy-pasted 3× | `2705-2817` | Extract a helper |
| 3.6 | `SaveSettings()` writes to disk on every arrow keypress | `2368`, `2375` | Save once on menu exit |
| 3.7 | Magic numbers for core thresholds (rotation `0.2f`, clamp `±1.57f`, `stateTimer>120`) | `650`, `768`, `693` | Named `constexpr` constants |
| 3.8 | Redundant `vel.length()` (`sqrt`) recomputed many times per frame | `649`, `662`, `1247`, `1488`, `1492` | Compute once per frame, reuse |
| 3.9 | C-style casts in Win32 PAL | `2430`, `2450`, `2462` | `static_cast`/`reinterpret_cast` |
| 3.10 | `keys[wParam]` written without explicit bounds guard | `346`, `3240` | Assert/guard VK ≤ 255 |
| 3.11 | Missing `const`-correctness on parameters | throughout | Pass read-only params by `const&` |

---

## Priority 4 — Documentation, Repo Hygiene & Process

### 4.1 Documentation drift (highest-value doc fix)
The docs describe an older program. Corrected in this review pass:
- **`CLAUDE.md`** claimed "~1200 lines", "for Windows", "only Windows SDK", `Beep()` sound,
  `SetTimer` loop, `wchar_t`/Unicode everywhere. → Updated to reflect the cross-platform reality,
  the PAL, and the current ~3,300-line size.
- **`platform.md`** claimed "Phase 3 macOS — NOT STARTED" and "Phase 4 — NOT STARTED", but both
  are done (55 `CGContext` calls, `NSView`/`NSWindow`, macOS CMake + `build_mac.sh` all present).
  → Status tables updated.
- **`lander.cpp:3`** still reads `@brief Classic lunar lander game for Windows`.
  → Recommend updating to "for Windows and macOS".
- **`CHANGELOG.md`** only documents 1.0.0 as Windows-only "~1200 lines"; VERSION is 1.0.2 with no
  macOS entry. → Recommend adding 1.0.1 / 1.0.2 entries covering the cross-platform work.

### 4.2 CI/CD is Windows-only
Both `.github/workflows/build.yml` and `release.yml` run only on `windows-latest` and ship only a
Windows ZIP. The macOS code path is never built in CI, so a macOS regression would go unnoticed,
and there is no macOS artifact for users.
**Recommendation:** add a `macos-latest` job to `build.yml` (build via CMake / `build_mac.sh`) and
a macOS artifact (`.app`/`.dmg`/tarball) to `release.yml`.

### 4.3 Missing LICENSE file
`README.md` states "Copyright (c) 2025 Todd Dube" and `release.yml:58` does
`cp LICENSE || echo "No LICENSE found"`, but there is no `LICENSE` file in the repo.
**Recommendation:** add a `LICENSE` (the copyright notice implies "all rights reserved"; pick an
explicit license — MIT is common for a project like this — or state the intended terms).

### 4.4 Tracked build/cache artifacts
`.cache/clangd/index/lander.cpp.*.idx` is tracked in git. It's a local IDE cache.
**Recommendation:** add `.cache/` to `.gitignore` and `git rm --cached` the tracked index. Also
consider whether `.claude/settings.local.json` (local-only settings) belongs in version control.

### 4.5 README structure block out of date
`README.md`'s "Project Structure" omits `platform.md`, `build_mac.sh`, `CHANGELOG.md`,
`RELEASE.md`, and `RELEASE_GUIDE.md`. → Updated in this pass.

---

## Quick Wins (low effort, high value)

1. Add the bounds guard at `lander.cpp:666` (1.1) — prevents a potential crash.
2. Replace the three raw `new[]` audio buffers with `std::vector<short>` (3.1).
3. Add `.cache/` to `.gitignore` and untrack the clangd index (4.4).
4. Add a `LICENSE` file (4.3).
5. Add a `macos-latest` job to `build.yml` (4.2) — catches macOS build breaks immediately.
6. Fix the file-header comment at `lander.cpp:3` (4.1).

---

## Suggested Roadmap

**Now (done):** documentation corrected (`CLAUDE.md`, `platform.md`, `README.md`), this review
authored, and **all Priority-1 correctness/portability fixes (1.1–1.4) implemented** with
Win32 + macOS parity.

**Next (small PRs):** remaining quick wins (RAII audio buffers §3.1, `.cache/` untrack, `LICENSE`),
macOS CI job (§4.2).

**Then (focused refactor):** encapsulate global state into a `Game` struct (2.1), extract a
testable logic core with a handful of unit tests (2.2), make `RenderGame` pure (2.3).

**Later (feature-level):** `PlatTimer` + `PlatPlaySound` seams to converge audio/timing behavior
(2.4); optional Linux backend (2.5); portable save-file format (1.2).
