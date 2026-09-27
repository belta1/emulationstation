---
updated: 2026-09-27
covers: [glossary, domain]
status: current
---

# Glossary

- **ES / EmulationStation**: the game-browsing frontend (RetroPie fork, built from source). Binary
  at `/usr/local/bin/emulationstation`; resources are symlinked next to it. See [image-build](modules/image-build.md).
- **RetroArch**: the emulator host ES launches per game. Config in `config/retroarch.cfg`.
- **Core (libretro core)**: `*_libretro.so` emulator plugin in `/usr/lib/libretro` (a symlink to the
  arch-specific dir). It comes from apt `libretro-*` packages or is compiled in the builder stage (fceumm, fbneo).
- **System**: a `<system>` block in `config/es_systems.cfg`: name, ROM folder, extensions, launch
  command. See [systems](modules/systems.md).
- **Herramientas** ("Tools"): a pseudo-system at `/opt/es-tools` that always has one entry, so ES
  always starts. See [herramientas](modules/herramientas.md).
- **Recargar lista de juegos** ("Reload game list"): the Herramientas entry. It kills ES and the
  entrypoint loop restarts it, which rescans the ROMs.
- **gamelist.xml**: ES per-system metadata. The Herramientas one is regenerated on each ES start at
  `~/.emulationstation/gamelists/herramientas/gamelist.xml`.
- **es-rom-summary**: `tools/es-rom-summary`, the per-system ROM count (log table or `--gamelist` XML).
- **ROMs dir**: host folder mounted at `/roms` (default `~/docker_compose/config/emulationstation`,
  env `ROMS_DIR`). It has one subfolder per system, plus `bios/` (RetroArch `system_directory`).
- **ROMS_HOST_DIR**: env var that only exists so logs and messages show the *host* path to the user.
- **Romset (FBNeo)**: arcade ROMs must match the current FinalBurn Neo set. Neo Geo needs `neogeo.zip`
  and clones need the parent zip.
- **PowerSaverMode**: ES setting (`es_settings.cfg`) that makes ES sleep between input events instead of redrawing continuously; shipped as `default`.
- **PUID / PGID**: host UID/GID that the `es` user is remapped to, for volume permissions.
- **Carbon**: the default ES theme, cloned into `/etc/emulationstation/themes/carbon`.
