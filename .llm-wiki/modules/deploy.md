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
    the host X server), X11 socket, the whole host `XDG_RUNTIME_DIR` read-only at `/run/user/host`
    (PulseAudio socket + X cookie), `/dev/dri`, `/dev/input`, `/run/udev`,
    `device_cgroup_rules: c 13:* rmw`, `restart: unless-stopped`. No ports.
  - `build: .`, `image: emulationstation:latest`, `pull_policy: build`.
  - Volumes: `${ROMS_DIR:-~/docker_compose/config/emulationstation}:/roms`, named `es-config`, `retroarch-config`.
- `scripts/crear-carpetas-roms.sh` / `.ps1`: pre-create the host ROM folders from `config/es_systems.cfg`.

## How it works

- Desktop launch: `scripts/instalar-acceso-directo.sh` (run once on the host, also via `curl | bash`
  from raw GitHub, so no local clone is needed) writes `~/.local/bin/lanzar-emulationstation` and a
  `.desktop` entry. The launcher only does `docker restart emulationstation` (the Portainer-managed
  container; running Compose from a clone would create a clashing second project). Restarting also
  re-copies the X cookie, which changes on every login. Errors go to `notify-send`.

- Env: `ROMS_DIR`, `DISPLAY` (default `:0`), `XDG_RUNTIME_DIR` (default `/run/user/1000`, for the
  PulseAudio socket and X cookie), `XAUTH_FILE` (optional cookie path inside the container), `PUID`, `PGID` (via `.env` or the Portainer env). `ROMS_HOST_DIR` is set from
  `ROMS_DIR` for display only.
- Portainer: a stack from Git (`refs/heads/main`, `docker-compose.yml`). **Pull and redeploy** rebuilds
  because of `pull_policy: build`. The Portainer host must be the machine with the screen.

## Gotchas & constraints

- **Portainer + `~`:** Compose runs inside the Portainer container, so `~` is wrong. `ROMS_DIR` must be absolute.
- `pull_policy: build` exists because Portainer and `compose up` would otherwise reuse a stale image.
  If the logs lack `>> ROMs detectadas:`, delete the `emulationstation:latest` image and redeploy.
- X access uses the session cookie (see [entrypoint](entrypoint.md)); `xhost +local:docker` is only a
  fallback when no cookie is found. NVIDIA needs the container toolkit + `gpus: all`.
- Adding an env var means updating the Dockerfile `ENV` (if it needs a default), the compose
  `environment`, and the README variable table.

## Related

- [entrypoint](entrypoint.md), [input](input.md), [recipes](../recipes.md#release--deploy)
