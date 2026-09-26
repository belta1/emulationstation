#!/usr/bin/env bash
# Reinicia EmulationStation para que vuelva a buscar ROMs (el entrypoint lo
# relanza automáticamente). Útil después de copiar juegos nuevos.
pkill -TERM -f '^emulationstation( |$)'
