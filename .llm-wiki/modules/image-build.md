---
updated: 2026-09-27
covers: [dockerfile, build, cores]
status: current
---

# Image build

Two-stage `Dockerfile`: the builder stage compiles ES and the missing cores; the runtime stage
installs RetroArch and the apt cores, then bakes in the config. It is kept lean on purpose.

## Key files & entry points

- `Dockerfile`: builder stage (`AS builder`) and runtime stage.
- `.dockerignore`: excludes `roms/`, `*.md`, `.git`, `.github`, `.llm-wiki` and `scripts`.

## How it works

- **Builder:** apt dev libs (only the needed `libboost-{filesystem,system,locale,date-time}-dev`, not
  `libboost-all-dev`) → `git clone --branch ${ES_VERSION} --recurse-submodules` ES →
  `cmake -DGL=ON` + `make` + `strip`. Clones the Carbon theme (`.git` stripped). Builds `fceumm` (NES), `fbneo`
  (arcade), `pcsx_rearmed` (PSX, with submodules) and `mupen64plus_next` (N64; needs nasm) into `/src/cores/`, then `strip --strip-unneeded` on them.
- **Runtime:** apt `retroarch` + `libretro-{snes9x,gambatte,mgba,genesisplusgx,beetle-pce-fast}` (snes9x and genesisplusgx come from multiverse),
  `tini gosu wmctrl`. `libvlc5`/`libvlccore9` are installed because ES links them, but not `vlc-plugin-base`
  (no theme video playback). It copies the ES binary to `/usr/local/bin/emulationstation`
  and its resources to `/usr/local/share/emulationstation/resources`, with a symlink next to the binary.
- `/usr/lib/libretro` → symlink to `/usr/lib/*-linux-gnu/libretro` (amd64/arm64). Built cores are moved there.
- Baked paths: `/etc/emulationstation/es_systems.cfg`, `/etc/emulationstation/defaults/{es_input,es_settings,retroarch}.cfg`,
  `/etc/emulationstation/themes/`, `/etc/emulationstation/retroarch-forzado.cfg`, `/etc/retroarch/autoconfig/`, `/etc/retroarch/remaps/`, `/usr/local/bin/{es-rom-summary,es-retroarch}`,
  `/opt/es-tools/`, `/usr/local/bin/entrypoint.sh`.
- Declared volumes: `/roms`, `/home/es/.emulationstation`, `/home/es/.config/retroarch`. No exposed ports.
- `ENTRYPOINT tini -- entrypoint.sh`, `CMD emulationstation`. See [entrypoint](entrypoint.md).

## Gotchas & constraints

- Runtime `libboost-*1.83.0`, `libcurl4t64`, `libasound2t64` and `libvlccore9` package names are tied to **Ubuntu 24.04**. Changing
  `UBUNTU_VERSION` means renaming those packages.
- ES expects `resources/` beside its binary, which is why the symlink exists. Don't remove it.
- Core `.so` names differ from package names (`libretro-beetle-pce-fast` → `mednafen_pce_fast_libretro.so`,
  `genesisplusgx` → `genesis_plus_gx_libretro.so`). `es_systems.cfg` must use the `.so` name.
- The base image user `ubuntu` (UID 1000) is deleted so `es` gets UID 1000.
- Why 24.04: Ubuntu 22.04 ships RetroArch 1.7.3, which freezes under GNOME Wayland (GLX_OML_sync_control
  vsync under Xwayland, forced on in its menu), and the libretro PPA no longer builds for 22.04.
- FCEUmm, FBNeo, PCSX ReARMed, Mupen64Plus-Next and the theme track upstream HEAD, so builds are not reproducible. FBNeo dominates build time.
- Anything `COPY`'d must survive `.dockerignore`; `*.md` files and `scripts/` are excluded.
- No BuildKit-only syntax (`RUN --mount`): Portainer may build with the legacy builder.
- New cores built from source should also be stripped (the `strip /src/cores/*.so` step covers `/src/cores`).

## Related

- [systems](systems.md), [entrypoint](entrypoint.md), [recipes](../recipes.md#add-a-system)
