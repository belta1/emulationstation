---
updated: 2026-09-27
covers: [conventions, patterns]
status: current
---

# Conventions

## Naming & structure

- Image-baked config → `config/`. In-container helper scripts → `tools/`. Host-side helper scripts → `scripts/`
  (always paired: `.sh` for Linux/macOS and `.ps1` for Windows, same behavior).
- Script names and user-facing strings are **Spanish** (`crear-carpetas-roms`, `Recargar lista de
  juegos.sh`, log lines `>> …`). Keep new UI/log text in Spanish, and keep README in sync.
- Commit messages are English, imperative ("Store ROMs in …", "Always rebuild the image on deploy").

## Tooling & config locations

- No package manager, linter, formatter or tests. Shell style is `set -euo pipefail` (`set -uo` in
  `es-rom-summary`, where `find` can fail harmlessly), `[[ ]]`, quoted `"${VAR}"`, and `${VAR:-default}` for env.
- Dockerfile args: `UBUNTU_VERSION`, `ES_REPO`, `ES_VERSION`, `THEME_REPO`, `FCEUMM_REPO`, `FBNEO_REPO`.

## Patterns to reuse

- **Derive from `es_systems.cfg`, never hard-code system lists.** The entrypoint, es-rom-summary and
  both scripts all read it (see [architecture](architecture.md#who-reads-es_systemscfg)).
- **Run as `es` via `gosu`** with `env HOME="${ES_HOME}"`. Only the entrypoint runs as root.
- **First-run copy idiom:** `[[ -f dest ]] || cp "${DEFAULTS}/x" dest`. It never overwrites user config.
- Env knobs are defined in the Dockerfile `ENV` block and in `docker-compose.yml` `environment`,
  with the default repeated in scripts via `${VAR:-…}`.

## Error handling

- Log lines prefixed `>> ` (Spanish). Warnings `>> AVISO: …`. Fatal config errors print to stderr and `exit 1`.
- Non-critical ops are tolerated with `|| true` / `2>/dev/null` (e.g. `chown /roms/*`).

## Testing

- Nothing automated. Verify manually: build, start, read logs, check the host screen. See
  [recipes](recipes.md#verify-a-change).

## Do / don't

- ✅ Keep `es_systems.cfg` one-tag-per-line; the grep/awk parsers depend on it.
- ✅ Keep the `herramientas` system; without it ES shows "We can't find any systems" when there are no ROMs.
- ✅ Use JSON-form `COPY [...]` for paths with spaces (`tools/Recargar lista de juegos.sh`).
- ❌ Don't copy `es_systems.cfg` into the volume from the entrypoint. That was removed on purpose.
- ❌ Don't hard-code `~` for `ROMS_DIR` in Portainer docs/config; it needs an absolute path.
- ⚠️ **Line endings:** this Windows checkout has `core.autocrlf=true` and no `.gitattributes`, so
  `*.sh`/`entrypoint.sh` are **CRLF in the working tree**. A `docker build` from this checkout can bake
  CRLF scripts into the image (`bash\r` / `$'\r'` errors). Git-based builds (Portainer) get LF.
