#!/usr/bin/env bash
# Crea la carpeta de ROMs en el host con una subcarpeta por sistema de
# config/es_systems.cfg (más bios/). El contenedor también las crea al
# arrancar; este script sirve para preparar la biblioteca antes.
#   ./scripts/crear-carpetas-roms.sh [carpeta]   (por defecto ~/docker_compose/config/emulationstation)
set -euo pipefail

dest="${1:-${ROMS_DIR:-$HOME/docker_compose/config/emulationstation}}"
dest="${dest/#\~/$HOME}"
cfg="$(cd "$(dirname "$0")/.." && pwd)/config/es_systems.cfg"

mkdir -p "${dest}/bios"
grep -oP '(?<=<path>/roms/)[^<]+' "${cfg}" | while read -r system; do
    mkdir -p "${dest}/${system}"
done
echo "Carpetas de ROMs listas en ${dest}:"
ls -1 "${dest}"
