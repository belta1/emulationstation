# Log

Append-only record of changes to this wiki. Newest entries at the bottom. Each entry starts with a
fixed prefix so the log is greppable: `grep "^## \[" log.md | tail -5`.

Format: `## [YYYY-MM-DD] <init|update|lint> | <short summary>`

## [2026-09-27] init | Docker packaging repo (Dockerfile/Bash/XML, no Node/Python); created index, architecture, conventions, glossary, recipes + 6 modules (image-build, entrypoint, systems, herramientas, input, deploy)

## [2026-09-27] update | X11-only, lean image, performance tuning
Removed the browser mode (Xvfb/x11vnc/noVNC, `DISPLAY_MODE`, VNC ports/env); `docker-compose.yml`
now has a single `emulationstation` service on the host X11 display with `ipc: host`. Image: targeted
boost dev libs, stripped ES/cores, no `vlc-plugin-base`/`unzip`, bigger `.dockerignore`. New
`config/es_settings.cfg` (first-run copy: PowerSaverMode, black screensaver, instant transitions),
RetroArch perf defaults, `es-rom-summary --gamelist FILE` (one `find` per system, one call per ES
start), entrypoint waits for the X socket and only chowns mismatched files. Pages: index,
architecture, conventions, glossary, recipes, modules/{entrypoint,deploy,image-build,herramientas,input}.

## [2026-09-27] update | PSX core: Beetle PSX → PCSX ReARMed
`psx` now uses `pcsx_rearmed_libretro.so`, built from source in the builder stage (apt
`libretro-beetle-psx` removed). Lighter on CPU and accepts any BIOS file in `/roms/bios` (e.g.
`SCPH1001.BIN`), with HLE fallback. Pages: modules/{image-build,systems}.md.

## [2026-09-27] update | Xbox One/Series + PlayStation Classic controllers
`es_input.cfg` gained 27 `<inputConfig>`s generated from SDL_GameControllerDB (Xbox One S Bluetooth
02fd/02e0, Xbox One/Series USB, PS Classic). New RetroArch udev profiles per product ID. The Guide
exit hotkey moved from global `retroarch.cfg` into each profile (PS Classic: Select+Start /
Select+Triangle). Pages: modules/input.md, index.
