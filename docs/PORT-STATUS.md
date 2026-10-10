# Port status: 14.1-based Android port → 16.0-beta4

## 1. Upstream (OpenTTD/OpenTTD)

- Stable: **15.3** `14ec60f` (2026-04-04).
- Testing/v16 latest: **16.0-beta4** `f4134d8` (2026-09-20). Pre-release chain: beta1 `c77a363` (2026-06-25), beta2 `e4620d5` (2026-07-12), beta3 `c56e08d` (2026-09-19).
- v16 highlights: backwards trains (+ reduced-speed-no-cab mode), double-ended ships, bridges over depots, 10k vehicles/type, LibSoxr resampling, screensaver mode, save-dialog folder creation, picker collections, font-size setting, NewGRF town/waypoint APIs, map-gen improvements.
- No `os/android/` upstream — **no official Android support**. The pelya port is the only Android path (SDL + `commandergenius` wrapper).
- Savegame version: 14.0 ends ≈ SLV 334–341; 15.0 → `EngineMultiRailtype=362`; 16.0-beta4 → `DoubleEndedShips=368`. Forward load OK, backward impossible, netplay same-major only.

## 2. Game fork (pelya/openttd-android)

- Branches: `master` (stale, ≈13.0-RC1, `.ottdrev` 12.2), `1.4`–`1.11`, `12`, `13`, **`14`** (maintained).
- Branch `14` tip `a3163e003` (2025-04-23): upstream `14.1` + ~15 Android/touch commits (Miguel Horta: button-ratio slider, font tab, genworld compact, viewport revert, dropdown sizing; Sergii Pylypenko: yapf_road compile fix).
- `.ottdrev` on `14`: `14.1 20240503 0 b3c704a63 1 1 2024` (old 7-field format).
- Android delta vs upstream `14.1` (`61342620b..a3163e003`): **156 files, +6167/−1183**:
  - **Build fixes (keep)**: `CMakeLists.txt` (`if(ANDROID)` shared `application` lib, Timidity, `log z expat`), `cmake/FindICU.cmake` (Android pkg-config path), `cmake/FindFontconfig.cmake`, `cmake/FindTimidity.cmake` + `src/music/libtimidity.*`, `FindVersion.cmake` (no git probe on Android), `InstallAndPackage.cmake`, `.ottdrev`.
  - **Runtime entrypoint (keep)**: `src/os/unix/unix_main.cpp` (`main→SDL_main` on `__ANDROID__`), `src/os/unix/unix.cpp` (Android browser intents, `__android_log_print`, `HAS_STATVFS` guard), `src/openttd.cpp` (`FONTCONFIG_FONTS`, 16bpp fallback, cloud-save hooks), `src/video/sdl_v.cpp` (screenkeyboard, multitouch joystick, clipboard), `src/video/sdl2_v.cpp` (touch RMB pos), `src/video/video_driver.*` (cloud-save `GameLoop`, clipboard).
  - **Touch UI (large, rebase needed)**: `widget.*`, `window.*`, `viewport*`, `toolbar_gui.*`, `settings_gui.*`, `table/settings/*`, ~40 dialog files, `build_confirmation_*` (new), `help/tutorial` merge, `english.txt` tablet strings + 20 translations, `android-extract/store-strings.sh`.
  - **Emscripten (out of scope)**: `os/emscripten/*`, `em_proxy.*`, AWS workflow.
  - **Upstream backports/noise (drop)**: fontcache cleanups, `yapf_road.cpp` one-liner, changelog headers, `todo.txt`.

## 3. SDL wrapper (pelya/commandergenius, `sdl_android` `16fd3ea`)

- `project/jni/application/openttd/src` submodule → `pelya/openttd-android` **`branch = 13`** (behind even the `14` branch).
- `AndroidAppSettings.cfg`: `14.1.rev128`, data `openttd-data-14.1-0.zip.xz`, `LibSdlVersion=1.2`, `SwVideoMode=y`, multitouch on, mouse/two-button on.
- `AndroidBuild.sh`: CMake NDK toolchain build, `AndroidSDL.cmake` shim for prebuilt `APP_MODULES`, `HOST_BINARY_DIR=build-tools` (tools-only host build via `AndroidPreBuild.sh`), per-ABI `libapplication-*.so` + `data/` + `pack-data.sh`.
- `pack-data.sh` `VER=14.1-0`; ICU pack pinned to `icudt62l` / ICU 62.1 (ancient — revisit for v16); `download-data.sh` pulls OpenGFX/OpenSFX/OpenMSX latest + stamps `.ottdrev`.
- `java.patch`: kill process on settings reset so `SDL_main` re-runs cleanly (SDL2 doesn't unload libs).

## 4. v16 blockers (must fix for any v16 APK)

1. **SDL1.2 → SDL2** (critical). Upstream deleted SDL1.2 driver. Wrapper: `LibSdlVersion=2`; `AndroidBuild.sh` SDL2 case (done here); game: drop `sdl_v`/`sdl_s` references, use `VideoDriver_SDL2`/`SoundDriver_SDL2` (`sdl2_v.*`, `sdl2_s.*`); touch controls move in-game; set orientation hints; `exit()` from `main` (no return); expected `ClaimMousePointer`/`Start` signature changes (`bool→void`, `string_view`/`optional`).
2. **CMake deps**: `FindSoxr`/`FindOpusFile`/`FindOpus`/`FindOgg` new; decide NDK prebuilts vs `-DOPTION_*=OFF`/absent (silent disable). `FindICU` custom→builtin (`ICU_I18N_FOUND`, `ICU::i18n`+`ICU::uc`); extend shim or set `ICU_ROOT`. `cmake_minimum 3.17`, `Endian.cmake` removed, `src/CMakeLists` new files (`newgrf/`, `screenshot_*`, `soundloader_*`, `soundresampler_soxr`, `font_unix.h`).
3. **API churn**: `openttd_main(argc,argv)→vector<string_view>`; `FiosIsValidFile→FiosIsHiddenFile(filesystem::path)`; `OTTD2FS/FS2OTTD`, `ShowInfo/ShowOSErrorBox` → `string_view`; driver `GetDriverParam→optional<string_view>`; `video_driver.hpp` DPI/mouse/clipboard rework; `font_unix` FontConfig rewrite; `settings IniFileVersion→8` + `default_rail_road_type`.
4. **Data/packaging**: `VER` bump (done: `16.0-beta4-0`); `changelog.txt→changelog.md` + `known-bugs.txt→known-bugs.md` renames affect asset lists; ICU data version; base sets auto-latest via `download-data.sh`.
5. **Merge scale**: `git merge 16.0-beta4` into port `14` ≈ **213 conflicted files**. Recommended order: (a) minimal build/entrypoint rebase → green CI configure; (b) touch-UI file-by-file (widget/window/viewport/toolbar first, dialogs after); (c) translations last.

## 5. Rebase checklist

- [ ] `CMakeLists.txt` Android block (shared lib, Timidity, log/z/expat) re-applied; Soxr/OpusFile decisions recorded
- [ ] `FindICU` shim extended for builtin module (or `ICU_ROOT`); Fontconfig/Timidity finds verified in CI configure log
- [ ] `unix_main.cpp` SDL_main guard + `unix.cpp` Android intents/log/statvfs re-applied to new signatures
- [ ] `openttd.cpp` fontconfig env + blitter fallback re-applied; cloud-save hooks kept or split out
- [ ] SDL2-only video/sound selection; `sdl_v` references purged
- [ ] `src/CMakeLists.txt` new v16 files present in Android build
- [ ] `.ottdrev` regenerated in new 6-field format for `16.0-beta4`
- [ ] Touch UI: widget/window/viewport/toolbar/settings + dialogs rebased; `english.txt` tablet strings re-added
- [ ] Wrapper: submodule → v16 branch, `AndroidAppSettings.cfg` v16/SDL2 (this repo), data packs rebuilt, `java.patch` re-verified
- [ ] CI green: port-status + host configure + wrapper-check; NDK APK build as follow-up job
