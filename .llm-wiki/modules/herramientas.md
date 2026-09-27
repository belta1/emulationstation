---
updated: 2026-09-27
covers: [herramientas, es-rom-summary, reload]
status: current
---

# Herramientas & ROM summary

A pseudo-system that keeps ES from dead-ending with "We can't find any systems". It also shows the
user where to put ROMs and how many were found.

## Key files & entry points

- `tools/es-rom-summary` → `/usr/local/bin/es-rom-summary`
  - no args: aligned table for the logs (`SISTEMA JUEGOS CARPETA (extensiones)`) + status line on stdout.
  - `--gamelist FILE`: same table on stdout, **and** writes `gamelist.xml` for `herramientas` to FILE
    (creating its dir). Its single `<game>` description holds the per-folder counts.
  - Counting does one `find -maxdepth 2` per system with all extensions OR-ed (`\( -name … -o … \)`).
- `tools/Recargar lista de juegos.sh` → `/opt/es-tools/`: `pkill -TERM -f '^emulationstation( |$)'`.
- Caller: `entrypoint.sh`, once before every ES start (one scan feeds both the logs and the gamelist).

## How it works

1. The entrypoint runs `es-rom-summary --gamelist ~/.emulationstation/gamelists/herramientas/gamelist.xml`.
2. The user picks **Recargar lista de juegos** → ES gets killed → the entrypoint loop regenerates the
   gamelist and restarts ES, which rescans the ROM folders.
3. Paths shown to the user use `ROMS_HOST_DIR` (the host path) instead of `/roms`.

## Gotchas & constraints

- The gamelist `<path>` is `./Recargar lista de juegos.sh`. It must match the filename exactly (spaces included).
- The `<image>` points into the Carbon theme (`…/carbon/retropie/art/controller.svg`). Changing the theme breaks it.
- The status text differs between the two modes (log vs in-ES wording). Both are Spanish, so edit both branches.
- Description text is XML-escaped via `xml_escape`. Keep using it for any new dynamic text.
- The reload depends on the entrypoint restart loop. With `ES_RESTART=false` it just quits ES.

## Related

- [entrypoint](entrypoint.md), [systems](systems.md), [recipes](../recipes.md#add-a-herramientas-tool)
