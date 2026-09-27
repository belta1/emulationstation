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

## [2026-09-27] update | RetroArch vsync off (Xwayland freeze)
On GNOME Wayland hosts, RetroArch 1.7.3 picks GLX_OML_sync_control and blocks forever in the first
swap under Xwayland (games froze on launch). Verified on jfubuntu: 120 frames never finish with
vsync on; finish in ~2 s with vsync off. `config/retroarch.cfg` now ships `video_vsync = "false"`.
Pages: architecture, index.

## [2026-09-27] update | es-retroarch launcher (real fullscreen + forced settings)
New `tools/es-retroarch` (all es_systems commands use it) runs `retroarch -f --appendconfig
/etc/emulationstation/retroarch-forzado.cfg` (forces `video_vsync = "false"` even with an old
volume config) and then `wmctrl -r RetroArch -b add,fullscreen`, because GNOME only maximizes
RetroArch 1.7.3's own fullscreen window. `wmctrl` added to the runtime image. Verified live on
jfubuntu (1920x1080, frames advancing). Documented that Xbox BT `02fd` fw 0903 View/Guide are
invisible to RetroArch. Pages: architecture, recipes, modules/{image-build,input}.
