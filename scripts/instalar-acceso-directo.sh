#!/usr/bin/env bash
# Crea el acceso directo "EmulationStation" en el menú de aplicaciones de Ubuntu.
# El contenedor lo gestiona Portainer: el acceso directo solo lo (re)arranca,
# así que no hace falta tener el repositorio clonado en el equipo.
#
# Instalación (una vez, en el equipo con escritorio):
#   curl -fsSL https://raw.githubusercontent.com/belta1/emulationstation/main/scripts/instalar-acceso-directo.sh | bash
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
LAUNCHER="${BIN_DIR}/lanzar-emulationstation"
APPLICATIONS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
DESKTOP_FILE="${APPLICATIONS_DIR}/emulationstation.desktop"

mkdir -p "${BIN_DIR}" "${APPLICATIONS_DIR}"

cat > "${LAUNCHER}" <<'EOF'
#!/usr/bin/env bash
# Arranca (o reinicia) el contenedor de EmulationStation desplegado en Portainer.
CONTAINER=emulationstation

aviso() { notify-send -i applications-games "EmulationStation" "$1" 2>/dev/null || echo "$1"; }

if ! docker info >/dev/null 2>&1; then
  aviso "Sin acceso a Docker. Ejecuta: sudo usermod -aG docker \$USER y vuelve a iniciar sesión."
  exit 1
fi
if ! docker container inspect "${CONTAINER}" >/dev/null 2>&1; then
  aviso "No existe el contenedor '${CONTAINER}'. Despliega el stack en Portainer."
  exit 1
fi

# Reiniciar también recoge la cookie de X de la sesión actual (cambia en cada inicio de sesión)
if docker restart "${CONTAINER}" >/dev/null 2>&1; then
  aviso "Iniciando EmulationStation..."
else
  aviso "No se pudo arrancar '${CONTAINER}'. Revisa los logs en Portainer."
  exit 1
fi
EOF
chmod +x "${LAUNCHER}"

cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=EmulationStation
Comment=Iniciar EmulationStation (contenedor de Portainer)
Exec=${LAUNCHER}
Icon=applications-games
Terminal=false
Categories=Game;Emulator;
EOF
chmod +x "${DESKTOP_FILE}"

command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "${APPLICATIONS_DIR}" >/dev/null 2>&1 || true

echo ">> Acceso directo instalado en ${DESKTOP_FILE}"
echo ">> Búscalo como \"EmulationStation\" en Actividades (puedes anclarlo al dock)."
