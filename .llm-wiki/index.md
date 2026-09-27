---
updated: 2026-09-27
covers: [overview, navigation]
status: current
---

# Index — emulationstation

The map of this repository. **Read this first, then jump to the files it points to.**
This repo packages **EmulationStation** (RetroPie fork, built from source) + **RetroArch** + libretro
cores as a Docker image. It runs fullscreen on the Linux host's own X11 display (GPU, controllers,
PulseAudio from the host); there is no web UI. There is no application code: the repo is a Dockerfile, Bash scripts and XML/INI config.
User-facing text (README, logs, UI strings, comments) is in **Spanish**.

## Stack

- **Languages:** Dockerfile (multi-stage, Ubuntu 22.04), Bash, EmulationStation XML config,
  RetroArch `.cfg`, one PowerShell script. No Node/Python, so there is no package manager or lockfile.
- **Build:** `docker compose build` (or `docker compose up -d --build`)
- **Run (Linux + X11):** `xhost +local:docker && docker compose up -d --build`
- **Logs / shell:** `docker compose logs -f` · `docker compose exec emulationstation bash`
- **Test / lint / typecheck:** none configured (no CI, no shellcheck, no tests). Verify by building
  and checking the `>> ROMs detectadas:` table in the logs. See [recipes](recipes.md#verify-a-change).
- **Deploy:** Portainer stack from this Git repo (`pull_policy: build` rebuilds on every deploy).

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Image build | `Dockerfile`, `.dockerignore` | Stage 1 compiles ES, FCEUmm, FBNeo and PCSX ReARMed. Stage 2 is the lean runtime with RetroArch and apt cores (stripped binaries, no VLC plugins) | [image-build](modules/image-build.md) |
| Container startup | `entrypoint.sh` | UID/GID mapping, first-run config copy, ROM dirs, device groups, waits for the host X server, ES restart loop | [entrypoint](modules/entrypoint.md) |
| Systems | `config/es_systems.cfg` | One `<system>` per console: ROM folder, extensions, RetroArch core command | [systems](modules/systems.md) |
| Herramientas + ROM summary | `tools/es-rom-summary`, `tools/Recargar lista de juegos.sh` | Always-present "Herramientas" system; ROM count table for logs and for the in-ES description | [herramientas](modules/herramientas.md) |
| Controllers / input | `config/es_input.cfg`, `config/retroarch.cfg`, `config/retroarch-autoconfig/` | Keyboard, Xbox 360, Xbox One/Series (USB + Bluetooth) and PS Classic mappings for ES and RetroArch, 2 players; per-profile exit hotkey | [input](modules/input.md) |
| Performance defaults | `config/es_settings.cfg`, `config/retroarch.cfg` | ES power saver / screensaver / transitions; RetroArch no-vsync (Xwayland hang), windowed fullscreen, no shaders | [architecture](architecture.md#key-decisions--constraints) |
| Compose / deploy | `docker-compose.yml`, `scripts/crear-carpetas-roms.{sh,ps1}` | Single `emulationstation` service on the host X11 display, volumes, env vars, host ROM folder setup, Portainer | [deploy](modules/deploy.md) |
| User docs | `README.md` | Spanish user guide (systems table, controls, Portainer, customization) | — |

## Where to start by task

- **Add a console/system** → [recipes](recipes.md#add-a-system), [systems](modules/systems.md), `config/es_systems.cfg`, `Dockerfile`
- **Add or bump a libretro core** → [image-build](modules/image-build.md), `Dockerfile`
- **Startup / permissions / display bug** → [entrypoint](modules/entrypoint.md), `entrypoint.sh`
- **"No systems" / ROMs not detected** → [herramientas](modules/herramientas.md), [systems](modules/systems.md)
- **Controller mapping** → [input](modules/input.md)
- **Ports, volumes, env vars, Portainer** → [deploy](modules/deploy.md), `docker-compose.yml`
- **Change default config shipped to users** → [recipes](recipes.md#change-a-default-config) (first-run copy gotcha)
- **Run / debug locally** → [recipes](recipes.md#run-locally)

## Also see

- [architecture](architecture.md): how the pieces fit together
- [conventions](conventions.md): how to write changes that match this repo
- [glossary](glossary.md): domain terms (ES, core, romset, gamelist…)
- [log](log.md): recent wiki changes
