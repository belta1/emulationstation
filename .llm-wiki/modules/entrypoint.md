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

0. Exits with a Spanish hint if `$DISPLAY` is unset. Defines `copiar_cookie_x` (see step 8).
1. **PUID/PGID** → `usermod -o` / `groupmod -o` on `es`.
2. **es_systems.cfg precedence:** if `~/.emulationstation/es_systems.cfg` exists and its sha256 is
   in the allowlist of old, unmodified shipped versions, it is deleted so `/etc` is used. Otherwise it is
   kept, with a warning if it lacks `/opt/es-tools` (herramientas).
3. **First-run copies** of `es_input.cfg`, `es_settings.cfg` and `retroarch.cfg` from `/etc/emulationstation/defaults/`.
4. `mkdir -p` each `/roms/*` `<path>` from the effective systems cfg, plus `/roms/bios`.
5. **Device groups:** for each `/dev/input/event*`, `js*` and `/dev/dri/*` with a non-root GID, create a
   `host<gid>` group if needed and add `es` to it.
6. `chown` only the home entries not already owned by `es` (`find … ! -user/-group … -exec chown -h`),
   plus `/roms` + first-level subdirs. Creates `/tmp/runtime-es` (0700, `es`). Every `gosu` call
   uses `ES_ENV`: `HOME`, `XDG_RUNTIME_DIR=/tmp/runtime-es`, `XAUTHORITY=~/.Xauthority`.
7. If CMD is `emulationstation`: for a local `DISPLAY` (`:N`), wait until `/tmp/.X11-unix/XN` exists
   (the container can start before the desktop). Then loop: `es-rom-summary --gamelist FILE` (writes the
   herramientas gamelist and prints the `>> ROMs detectadas:` table to the logs) → `copiar_cookie_x` →
   `emulationstation --no-splash` → restart after 1s unless `ES_RESTART` ≠ `true`. Any other CMD is
   `exec`'d as `es` (after `copiar_cookie_x`).
8. **X cookie (`copiar_cookie_x`)**:
   - Takes `XAUTH_FILE`, or the newest of `/run/user/host/.mutter-Xwaylandauth.*` (GNOME Wayland),
     `gdm/Xauthority` (GNOME X11) or `xauth_*` (KDE).
   - Rewrites it into `~/.Xauthority` with family `ffff`, so the cookie works for any hostname.
   - If there is no cookie, prints a one-time `AVISO` and falls back to `xhost`.

## Gotchas & constraints

- The sha256 allowlist only covers **historical** shipped `es_systems.cfg` versions that used to be
  copied into the volume. Editing `config/es_systems.cfg` today does not require adding a hash.
- `chown /roms /roms/*` is not recursive. ROM files keep host ownership.
- ES exiting normally (menu "Quit") restarts it, which is intended. To stop, stop the container.
- The cookie changes on every login, which is why it is re-copied inside the loop. After a re-login,
  ES picks up the new cookie on its next restart.
- ES runs fullscreen at the host's current resolution; there is no resolution setting.
- The ROM table is printed on every ES (re)start, so a "Recargar lista de juegos" also shows fresh counts in the logs.
- Must be LF line endings in the image (see [conventions](../conventions.md#do--dont)).

## Related

- [herramientas](herramientas.md), [systems](systems.md), [input](input.md), [deploy](deploy.md)
