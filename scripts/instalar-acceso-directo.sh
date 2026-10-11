#!/usr/bin/env bash
# Crea el acceso directo "EmulationStation" en el menú de aplicaciones de Ubuntu.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${REPO_DIR}/scripts/lanzar-emulationstation.sh"
APPLICATIONS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
DESKTOP_FILE="${APPLICATIONS_DIR}/emulationstation.desktop"

mkdir -p "${APPLICATIONS_DIR}"
chmod +x "${LAUNCHER}"

cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=EmulationStation
Comment=Iniciar EmulationStation en Docker
Exec=bash "${LAUNCHER}"
Path=${REPO_DIR}
Icon=applications-games
Terminal=true
Categories=Game;Emulator;
EOF
chmod +x "${DESKTOP_FILE}"

command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "${APPLICATIONS_DIR}" >/dev/null 2>&1 || true

echo ">> Acceso directo instalado en ${DESKTOP_FILE}"
echo ">> Búscalo como \"EmulationStation\" en Actividades (puedes anclarlo al dock)."
