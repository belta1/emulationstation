#!/usr/bin/env bash
# Arranca EmulationStation (Docker Compose) desde el acceso directo del escritorio.
set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}" || exit 1

# Si algo falla, deja la terminal abierta para poder leer el error
fallo() {
  echo
  echo "!! $1"
  read -rp "Pulsa Enter para cerrar..." _
  exit 1
}

command -v docker >/dev/null 2>&1 || fallo "Docker no está instalado."
docker info >/dev/null 2>&1 \
  || fallo "Sin acceso a Docker. Ejecuta: sudo usermod -aG docker \$USER y vuelve a iniciar sesión."

echo ">> Iniciando EmulationStation desde ${REPO_DIR}..."
docker compose up -d --build || fallo "docker compose falló (revisa el mensaje de arriba)."

echo ">> Listo. EmulationStation se abrirá en pantalla completa."
sleep 3
