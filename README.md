# OpenTTD Android port — v16 update (CI-driven)

Orchestration repo for updating the unofficial Android port of OpenTTD to
**v16 latest (`16.0-beta4`)**. All heavy lifting happens in **GitHub Actions**
— no local NDK required.

## Current state (researched 2026-10-10)

| Component | State |
|---|---|
| Upstream stable | `15.3` (`14ec60f`, 2026-04-04) |
| Upstream v16 latest | `16.0-beta4` (`f4134d8`, 2026-09-20). Beta1–3 changelogs: backwards trains/ships, LibSoxr resampling, bridges over depots, screensaver mode, NewGRF town variables, 10k vehicle limit |
| Upstream nightly | `20261002` master |
| Game fork (`pelya/openttd-android`) | Latest maintained branch **`14`** at `a3163e003` (2025-04-23, "Fixed compilation"), based on upstream `14.1` (`61342620b`, 2024-05-03) + touch-UI customisations. `master` branch is stale (≈13.0-RC1 era, 2023). No `15`/`16` branches |
| SDL wrapper (`pelya/commandergenius`, `sdl_android`) | Submodule `project/jni/application/openttd/src` pinned to **`branch = 13`**. `AndroidAppSettings.cfg` at `14.1.rev128` / `AppVersionCode=1410128`, **`LibSdlVersion=1.2`**, data pack `openttd-data-14.1-0.zip.xz` |

## Why this is a big update

- **SDL1.2 removed upstream** (`c0edbe0d3`, Jan 2025, #13298). `src/video/sdl_v.cpp` and `src/sound/sdl_s.cpp` are gone. The port **must switch to SDL2** (`LibSdlVersion=2`, uppercase `SDL2` modules, in-game touch controls, orientation hints). This repo's `android-wrapper/` already does that.
- **New optional deps**: `opusfile` + `soxr` in `vcpkg.json` (Ogg-Opus SFX #13055, LibSoxr resampling #15924). Absent libs = features silently disabled; NDK prebuilts need decisions.
- **ICU**: upstream deleted `cmake/FindICU.cmake`, now uses CMake builtin `FindICU` (`ICU_I18N_FOUND`). The pelya `PC_ICU_*` shim in `AndroidBuild.sh` must be extended (see note in that file).
- **`.ottdrev` format**: 7 fields → 6 (`REV_YEAR` derived). Old scripts emit mismatched revs → `norev0000` (network-incompatible) builds.
- **Scale**: `14.1..16.0-beta4` = **1717 files** changed. Port customisations = **156 files** (+6167/−1183). A direct `git merge` yields **~213 conflicted files** (measured locally). Touch-UI rebase (`widget.cpp`, `window.cpp`, `toolbar_gui`, `viewport`, ~40 dialogs) is the long pole.
- **Toolchain**: C++20 unchanged, `cmake_minimum` 3.16 → 3.17. NDK Clang fine.

## What lives here

- `android-wrapper/` — v16-ready wrapper configs copied from `commandergenius/project/jni/application/openttd/` and adapted: `LibSdlVersion=2`, version `16.0-beta4.rev1` / `AppVersionCode=1600001`, data pack `openttd-data-16.0-beta4-0.zip.xz`, `AndroidBuild.sh` SDL2 case + ICU/soxr notes, `pack-data.sh` `VER` bump.
- `.github/workflows/android-v16.yml` — CI: port-status report (merge-base, diff stats, conflict count, SDL1.2/dep/`.ottdrev` checks), host CMake configure sanity, wrapper config checks.
- `docs/PORT-STATUS.md` — detailed gap analysis and rebase checklist.
- `scripts/merge-report.sh` — same checks as CI, runnable locally.

## How to use

- Watch CI on every push/PR: the **port-status** job summarises merge conflicts and migration blockers.
- Rebase work happens in branches `port-14` (snapshot reference) → `port-16` (target). Game sources are **not vendored** here; CI fetches `pelya/openttd-android#14` and `OpenTTD/OpenTTD#16.0-beta4` on demand.
- Local quick check: `bash scripts/merge-report.sh` (needs `git`, network).

## Sources

- https://github.com/OpenTTD/OpenTTD (upstream, `16.0-beta4` `f4134d8`)
- https://github.com/pelya/openttd-android (game fork, branch `14` `a3163e003`)
- https://github.com/pelya/commandergenius (SDL wrapper, `sdl_android` `16fd3ea`)
- This repo: https://github.com/steamytooolz-commits/openttd-android-v16
