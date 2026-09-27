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
  (arcade) and `pcsx_rearmed` (PSX, with submodules) into `/src/cores/`, then `strip --strip-unneeded` on them.
- **Runtime:** apt `retroarch` + `libretro-{snes9x,gambatte,mgba,genesisplusgx,mupen64plus,beetle-pce-fast}`,
  `tini gosu`. `libvlc5`/`libvlccore9` are installed because ES links them, but not `vlc-plugin-base`
  (no theme video playback). It copies the ES binary to `/usr/local/bin/emulationstation`
  and its resources to `/usr/local/share/emulationstation/resources`, with a symlink next to the binary.
- `/usr/lib/libretro` → symlink to `/usr/lib/*-linux-gnu/libretro` (amd64/arm64). Built cores are moved there.
- Baked paths: `/etc/emulationstation/es_systems.cfg`, `/etc/emulationstation/defaults/{es_input,es_settings,retroarch}.cfg`,
  `/etc/emulationstation/themes/`, `/etc/retroarch/autoconfig/`, `/usr/local/bin/es-rom-summary`,
  `/opt/es-tools/`, `/usr/local/bin/entrypoint.sh`.
- Declared volumes: `/roms`, `/home/es/.emulationstation`, `/home/es/.config/retroarch`. No exposed ports.
- `ENTRYPOINT tini -- entrypoint.sh`, `CMD emulationstation`. See [entrypoint](entrypoint.md).

## Gotchas & constraints

- Runtime `libboost-*1.74.0` and `libvlccore9` package names are tied to **Ubuntu 22.04**. Changing
  `UBUNTU_VERSION` means renaming those packages.
- ES expects `resources/` beside its binary, which is why the symlink exists. Don't remove it.
- Core `.so` names differ from package names (`libretro-beetle-pce-fast` → `mednafen_pce_fast_libretro.so`,
  `genesisplusgx` → `genesis_plus_gx_libretro.so`). `es_systems.cfg` must use the `.so` name.
- FCEUmm, FBNeo, PCSX ReARMed and the theme track upstream HEAD, so builds are not reproducible. FBNeo dominates build time.
- Anything `COPY`'d must survive `.dockerignore`; `*.md` files and `scripts/` are excluded.
- No BuildKit-only syntax (`RUN --mount`): Portainer may build with the legacy builder.
- New cores built from source should also be stripped (the `strip /src/cores/*.so` step covers `/src/cores`).

## Related

- [systems](systems.md), [entrypoint](entrypoint.md), [recipes](../recipes.md#add-a-system)
