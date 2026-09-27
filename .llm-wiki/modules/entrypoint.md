---
updated: 2026-09-27
covers: [entrypoint, startup, display, permissions]
status: current
---

# Entrypoint (container startup)

`entrypoint.sh` runs as root under tini. It prepares users, config, folders and devices, waits for
the host X server, and then runs ES as `es` in a restart loop.

## Key files & entry points

- `entrypoint.sh`: the whole startup sequence (see the flow in [architecture](../architecture.md#control-flow-container-start)).

## How it works

0. Exits with a Spanish hint if `$DISPLAY` is unset.
1. **PUID/PGID** → `usermod -o` / `groupmod -o` on `es`.
2. **es_systems.cfg precedence:** if `~/.emulationstation/es_systems.cfg` exists and its sha256 is
   in the allowlist of old, unmodified shipped versions, it is deleted so `/etc` is used. Otherwise it is
   kept, with a warning if it lacks `/opt/es-tools` (herramientas).
3. **First-run copies** of `es_input.cfg`, `es_settings.cfg` and `retroarch.cfg` from `/etc/emulationstation/defaults/`.
4. `mkdir -p` each `/roms/*` `<path>` from the effective systems cfg, plus `/roms/bios`.
5. **Device groups:** for each `/dev/input/event*`, `js*` and `/dev/dri/*` with a non-root GID, create a
   `host<gid>` group if needed and add `es` to it.
6. `chown` only the home entries not already owned by `es` (`find … ! -user/-group … -exec chown -h`),
   plus `/roms` + first-level subdirs.
7. If CMD is `emulationstation`: for a local `DISPLAY` (`:N`), wait until `/tmp/.X11-unix/XN` exists
   (the container can start before the desktop). Then loop: `es-rom-summary --gamelist FILE` (writes the
   herramientas gamelist and prints the `>> ROMs detectadas:` table to the logs) → `emulationstation
   --no-splash` → restart after 1s unless `ES_RESTART` ≠ `true`. Any other CMD is `exec`'d as `es`.

## Gotchas & constraints

- The sha256 allowlist only covers **historical** shipped `es_systems.cfg` versions that used to be
  copied into the volume. Editing `config/es_systems.cfg` today does not require adding a hash.
- `chown /roms /roms/*` is not recursive. ROM files keep host ownership.
- ES exiting normally (menu "Quit") restarts it, which is intended. To stop, stop the container.
- ES runs fullscreen at the host's current resolution; there is no resolution setting.
- The ROM table is printed on every ES (re)start, so a "Recargar lista de juegos" also shows fresh counts in the logs.
- Must be LF line endings in the image (see [conventions](../conventions.md#do--dont)).

## Related

- [herramientas](herramientas.md), [systems](systems.md), [input](input.md), [deploy](deploy.md)
