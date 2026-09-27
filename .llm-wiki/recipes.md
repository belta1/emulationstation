---
updated: 2026-09-27
covers: [recipes, how-to]
status: current
---

# Recipes

No package manager, tests or linters exist here. Every workflow goes through Docker Compose.

## Run locally

```bash
xhost +local:docker && docker compose up -d --build   # fullscreen on the host X11 display (Linux)
docker compose logs -f                             # follow logs
docker stats emulationstation                      # CPU/RAM (ES idle should be near 0%)
docker compose exec emulationstation bash          # shell (root; ES runs as user `es`)
docker compose down        # stop   |   docker compose down -v   # also wipe es-config/retroarch-config volumes
```

Optional `.env` next to `docker-compose.yml`: `ROMS_DIR`, `DISPLAY`, `XDG_RUNTIME_DIR`, `PUID`,
`PGID`. See [deploy](modules/deploy.md).

## Verify a change

1. `xhost +local:docker && docker compose up -d --build`
2. `docker compose logs emulationstation`: expect `>> ROMs detectadas:` with one row per `/roms/*`
   system. A missing table means an old image is running.
3. On the host screen, check that the systems appear, then launch a game (exits with Esc / Guide).
4. If you touched `entrypoint.sh` or `tools/*` from a Windows checkout, watch for CRLF errors
   (see [conventions](conventions.md#do--dont)).

## Add a system

1. Add a `<system>` block to `config/es_systems.cfg`, with each tag on its own line. `<path>` must be
   `/roms/<name>`. The command is `retroarch -f -L /usr/lib/libretro/<core>_libretro.so %ROM%`.
2. Make sure the core exists: add a `libretro-<x>` apt package to the runtime stage of `Dockerfile`, or
   build it in the builder stage and `cp` the `.so` to `/src/cores/` (see [image-build](modules/image-build.md)).
   Check the exact `.so` filename the package installs.
3. Nothing else is needed for folders or counts: the entrypoint, `es-rom-summary` and `scripts/` derive them.
4. Update the systems table in `README.md` (and the tree listing of ROM folders).
5. Rebuild and [verify](#verify-a-change).

## Add or bump a core built from source

Copy the FCEUmm/FBNeo pattern in the builder stage: `ARG <X>_REPO` → `git clone --depth 1` →
`make … -j"$(nproc)"` → `cp <core>_libretro.so /src/cores/`. The runtime stage moves `/tmp/cores/*.so`
into `/usr/lib/libretro/` automatically.

## Change a default config

`config/es_input.cfg`, `config/es_settings.cfg` and `config/retroarch.cfg` are copied to the volumes **only on first run**.
Existing installs keep their old copy. Tell users to `docker compose down -v` (as README does), or
add migration logic to `entrypoint.sh` (compare with the `es_systems.cfg` sha256 allowlist there).
`config/retroarch-autoconfig/` and `config/es_systems.cfg` are baked into the image and apply on rebuild.

## Add a Herramientas tool

Put `tools/<Nombre>.sh` in the repo, `COPY` it into `/opt/es-tools/` in `Dockerfile` (JSON form if
the name has spaces), and make sure `chmod +x /opt/es-tools/*.sh` covers it. For a custom
name/description, extend the gamelist emitted by `tools/es-rom-summary --gamelist`. See [herramientas](modules/herramientas.md).

## Create host ROM folders ahead of time

```bash
./scripts/crear-carpetas-roms.sh [dest]                                        # Linux/macOS
powershell -ExecutionPolicy Bypass -File scripts\crear-carpetas-roms.ps1 [-Destino C:\ruta]   # Windows
```

## Release / deploy

Push to `main`. In Portainer: **Stacks → (stack) → Pull and redeploy**. `pull_policy: build` rebuilds
with cache. `ROMS_DIR` must be an absolute path in Portainer. Details in [deploy](modules/deploy.md).
