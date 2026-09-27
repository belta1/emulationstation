---
updated: 2026-09-27
covers: [architecture]
status: current
---

# Architecture

## Overview

A single Docker image (two build stages) that runs EmulationStation as a frontend. ES launches
RetroArch with a libretro core for each game. The container draws fullscreen on the **host's X11
server** (mounted `/tmp/.X11-unix`, GPU via `/dev/dri`). There is no web UI (the old
Xvfb/x11vnc/noVNC mode was removed), no network API and no database. State lives in three volumes: ROMs, ES
config and RetroArch config.

## Components

- **Builder stage** (`Dockerfile`, `AS builder`): compiles EmulationStation `ES_VERSION` (v2.11.2),
  clones the Carbon theme, and builds the `fceumm` and `fbneo` cores, which Ubuntu does not package.
- **Runtime stage** (`Dockerfile`): Ubuntu 24.04 with `retroarch` (1.18), `libretro-*` apt cores, tini and
  gosu. The config is baked into `/etc/emulationstation/`.
- **Entrypoint** (`entrypoint.sh`): runs as root, prepares everything, then drops to user `es` via
  `gosu`. See [entrypoint](modules/entrypoint.md).
- **Systems config** (`config/es_systems.cfg` → `/etc/emulationstation/es_systems.cfg`): the single
  source of truth for systems. Four other files read it (below).
- **Herramientas tooling** (`tools/`): a fake "system" whose only entry is a reload script, so ES
  never shows its "no systems" dead end. See [herramientas](modules/herramientas.md).
- **Compose** (`docker-compose.yml`): one service, `emulationstation`, on the host X11 display.

## Control flow (container start)

```
tini → entrypoint.sh (root)
  ├─ require $DISPLAY
  ├─ usermod/groupmod to PUID/PGID
  ├─ drop stale unmodified es_systems.cfg copy from volume (sha256 allowlist)
  ├─ first-run copy of es_input.cfg / es_settings.cfg / retroarch.cfg into volumes
  ├─ mkdir /roms/<system> for every <path> in es_systems.cfg, plus /roms/bios
  ├─ add `es` to host GIDs owning /dev/input/*, /dev/dri/*
  ├─ chown only home files not already owned by es
  ├─ wait for the host X socket /tmp/.X11-unix/X<n>
  └─ loop: es-rom-summary --gamelist <herramientas gamelist.xml>  (also prints ">> ROMs detectadas:")
           gosu es emulationstation --no-splash   (restart on exit unless ES_RESTART≠true)
game launch: ES → `es-retroarch -L /usr/lib/libretro/<core>.so %ROM%` (from es_systems.cfg)
             → retroarch -f --appendconfig /etc/emulationstation/retroarch-forzado.cfg …
             → wmctrl -r RetroArch -b add,fullscreen   (GNOME otherwise only maximizes it)
```

## Who reads `es_systems.cfg`

| Reader | How | Assumes |
|--------|-----|---------|
| EmulationStation | XML | normal ES schema |
| `entrypoint.sh` | `grep -oP '(?<=<path>)…'` | `<path>` on one line; only `/roms/*` paths get dirs |
| `tools/es-rom-summary` | line-based `awk` | `<name>`, `<path>`, `<extension>` each on its own line |
| `scripts/crear-carpetas-roms.sh` | `grep -oP` | same as entrypoint |
| `scripts/crear-carpetas-roms.ps1` | `[xml]` parse | valid XML |

The user copy `~/.emulationstation/es_systems.cfg` (volume) takes precedence over `/etc` for ES,
the entrypoint and es-rom-summary.

## Boundaries & external dependencies

- Build-time Git clones: RetroPie/EmulationStation, es-theme-carbon, libretro-fceumm, FBNeo (all
  `--depth 1`; the cores and theme are unpinned HEAD).
- Host (Linux only): `/dev/input` + `/run/udev` (controllers), `/dev/dri` (GPU), `/tmp/.X11-unix`
  (needs `xhost +local:docker`), the PulseAudio socket, and host IPC (`ipc: host`, for X11 MIT-SHM).

## Key decisions & constraints

- `es_systems.cfg` is **not** copied to the volume, so new systems ship with the image. `es_input.cfg`,
  `es_settings.cfg` and `retroarch.cfg` **are** copied on first run only, so user menu changes persist.
- Low resource use is a goal: `config/es_settings.cfg` enables ES `PowerSaverMode` (ES sleeps between
  events), black screensaver and instant transitions; `config/retroarch.cfg` uses **no vsync** (GLX OML_sync_control hangs forever under Xwayland; the compositor is tear-free and `audio_sync` paces frames), windowed
  fullscreen and no shaders/rewind/run-ahead; binaries and built cores are stripped; no VLC plugins.
- ES runs in a restart loop. "Recargar lista de juegos" kills ES on purpose to force a rescan.
