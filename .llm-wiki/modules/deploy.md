---
updated: 2026-09-27
covers: [compose, deploy, portainer, volumes, scripts]
status: current
---

# Compose & deployment

How the image is run: one Compose service on the host X11 display, the volumes, the env vars, the
host ROM folder and Portainer.

## Key files & entry points

- `docker-compose.yml`
  - `emulationstation`: `network_mode: host` (for udev hotplug events), `ipc: host` (X11 MIT-SHM with
    the host X server), X11 socket, PulseAudio socket, `/dev/dri`, `/dev/input`, `/run/udev`,
    `device_cgroup_rules: c 13:* rmw`, `restart: unless-stopped`. No ports.
  - `build: .`, `image: emulationstation:latest`, `pull_policy: build`.
  - Volumes: `${ROMS_DIR:-~/docker_compose/config/emulationstation}:/roms`, named `es-config`, `retroarch-config`.
- `scripts/crear-carpetas-roms.sh` / `.ps1`: pre-create the host ROM folders from `config/es_systems.cfg`.

## How it works

- Env: `ROMS_DIR`, `DISPLAY` (default `:0`), `XDG_RUNTIME_DIR` (default `/run/user/1000`, for the
  PulseAudio socket), `PUID`, `PGID` (via `.env` or the Portainer env). `ROMS_HOST_DIR` is set from
  `ROMS_DIR` for display only.
- Portainer: a stack from Git (`refs/heads/main`, `docker-compose.yml`). **Pull and redeploy** rebuilds
  because of `pull_policy: build`. The Portainer host must be the machine with the screen.

## Gotchas & constraints

- **Portainer + `~`:** Compose runs inside the Portainer container, so `~` is wrong. `ROMS_DIR` must be absolute.
- `pull_policy: build` exists because Portainer and `compose up` would otherwise reuse a stale image.
  If the logs lack `>> ROMs detectadas:`, delete the `emulationstation:latest` image and redeploy.
- The host must run `xhost +local:docker` inside its desktop session. NVIDIA needs the container toolkit + `gpus: all`.
- Adding an env var means updating the Dockerfile `ENV` (if it needs a default), the compose
  `environment`, and the README variable table.

## Related

- [entrypoint](entrypoint.md), [input](input.md), [recipes](../recipes.md#release--deploy)
