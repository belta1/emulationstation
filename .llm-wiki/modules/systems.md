---
updated: 2026-09-27
covers: [es_systems, systems, roms]
status: current
---

# Systems (`es_systems.cfg`)

Defines every console ES shows: its ROM folder, accepted extensions and the RetroArch launch command.
Several scripts treat it as the source of truth.

## Key files & entry points

- `config/es_systems.cfg` → baked to `/etc/emulationstation/es_systems.cfg`.
- Optional user override: `~/.emulationstation/es_systems.cfg` in the `es-config` volume.

## How it works

- Current systems: `nes` (fceumm), `snes` (snes9x), `gb`/`gbc` (gambatte), `gba` (mgba),
  `megadrive`/`mastersystem` (genesis_plus_gx), `n64` (mupen64plus_next, built from source), `psx` (pcsx_rearmed, built from source),
  `pcengine` (mednafen_pce_fast), `arcade` (fbneo), plus `herramientas` (`/opt/es-tools`, `bash %ROM%`).
- ES only lists systems that contain at least one matching file, so `herramientas` guarantees one always exists.
- The ROM folder is created and counted automatically for any `<path>` under `/roms/`. See the table of
  readers in [architecture](../architecture.md#who-reads-es_systemscfg).

## Gotchas & constraints

- **Parsers are line-based:** keep `<name>`, `<path>` and `<extension>` each on its own line, one value each.
- Extensions are case-sensitive in ES and in `es-rom-summary` (`find -name "*.ext"`), so list both cases.
  `es-rom-summary` only counts files at most 2 levels deep.
- `<theme>` must match a folder in the Carbon theme, or the system appears unstyled.
- A user override replaces the whole file. It must keep `herramientas`, and it won't receive new systems
  from image updates.
- PSX BIOS goes in `/roms/bios` (RetroArch `system_directory`). PCSX ReARMed tries `scph5500/5501/5502`, `psxonpsp660`, `scph101/7001/1001` `.bin`, then scans every file in the folder, so any genuine BIOS works under any name/case (e.g. `SCPH1001.BIN`); without one it falls back to HLE. It replaced Beetle PSX, which only accepts `scph550x.bin`.

## Related

- [image-build](image-build.md) (cores), [herramientas](herramientas.md), [recipes](../recipes.md#add-a-system)
