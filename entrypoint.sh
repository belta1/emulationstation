#!/usr/bin/env bash
# Prepara la configuración y arranca EmulationStation en el servidor X11 del
# host (monta /tmp/.X11-unix y pasa DISPLAY; ver docker-compose.yml).
set -euo pipefail

ES_USER="${ES_USER:-es}"
ES_HOME="${ES_HOME:-/home/es}"
DEFAULTS=/etc/emulationstation/defaults

: "${DISPLAY:?falta DISPLAY: monta /tmp/.X11-unix y pasa DISPLAY (p. ej. :0); en el host ejecuta antes xhost +local:docker}"

# Permite alinear UID/GID con el usuario del host (evita problemas de permisos en volúmenes)
if [[ -n "${PUID:-}" && "${PUID}" != "$(id -u "${ES_USER}")" ]]; then
    usermod -o -u "${PUID}" "${ES_USER}"
fi
if [[ -n "${PGID:-}" && "${PGID}" != "$(id -g "${ES_USER}")" ]]; then
    groupmod -o -g "${PGID}" "${ES_USER}"
fi

# Configuración inicial (solo si no existe, para no pisar cambios del usuario)
mkdir -p "${ES_HOME}/.emulationstation" "${ES_HOME}/.config/retroarch"

# es_systems.cfg vive en /etc (se actualiza con la imagen). Las versiones
# anteriores lo copiaban al volumen; si esa copia no se modificó, se borra
# para que se use la de /etc. Una copia personalizada se respeta.
USER_SYSTEMS="${ES_HOME}/.emulationstation/es_systems.cfg"
if [[ -f "${USER_SYSTEMS}" ]]; then
    case "$(sha256sum "${USER_SYSTEMS}" | cut -d' ' -f1)" in
        7b22e3545ee125bebeb923464be4bf2bccfabe0ef887d06987c6c9d7a05fec70|\
        17edea11164c3bd8d4317c636a82d8e7f0add30c2688b67889f6bcd20e74665c)
            rm -f "${USER_SYSTEMS}"
            echo ">> es_systems.cfg antiguo sin cambios: se usará el de la imagen"
            ;;
        *)
            echo ">> Usando es_systems.cfg personalizado: ${USER_SYSTEMS}"
            grep -q '/opt/es-tools' "${USER_SYSTEMS}" || echo ">> AVISO: no incluye el sistema \"herramientas\"; si no hay ROMs, EmulationStation no mostrará ningún sistema"
            ;;
    esac
fi
SYSTEMS_CFG="${USER_SYSTEMS}"
[[ -f "${SYSTEMS_CFG}" ]] || SYSTEMS_CFG=/etc/emulationstation/es_systems.cfg

[[ -f "${ES_HOME}/.emulationstation/es_input.cfg" ]] \
    || cp "${DEFAULTS}/es_input.cfg" "${ES_HOME}/.emulationstation/es_input.cfg"
[[ -f "${ES_HOME}/.emulationstation/es_settings.cfg" ]] \
    || cp "${DEFAULTS}/es_settings.cfg" "${ES_HOME}/.emulationstation/es_settings.cfg"
[[ -f "${ES_HOME}/.config/retroarch/retroarch.cfg" ]] \
    || cp "${DEFAULTS}/retroarch.cfg" "${ES_HOME}/.config/retroarch/retroarch.cfg"

# Crea una carpeta por sistema definido en es_systems.cfg
grep -oP '(?<=<path>)[^<]+' "${SYSTEMS_CFG}" \
    | while read -r dir; do if [[ "${dir}" == /roms/* ]]; then mkdir -p "${dir}"; fi; done
mkdir -p /roms/bios   # BIOS para RetroArch (system_directory)

# Mandos y GPU: añade el usuario a los grupos dueños de /dev/input y /dev/dri
# (sus GID vienen del host y no existen dentro de la imagen).
for dev in /dev/input/event* /dev/input/js* /dev/dri/*; do
    [[ -e "${dev}" ]] || continue
    gid="$(stat -c %g "${dev}")"
    [[ "${gid}" == 0 ]] && continue
    group="$(getent group "${gid}" | cut -d: -f1 || true)"
    if [[ -z "${group}" ]]; then
        group="host${gid}"
        groupadd -g "${gid}" "${group}"
    fi
    id -nG "${ES_USER}" | grep -qw "${group}" || usermod -aG "${group}" "${ES_USER}"
done

# Solo cambia el dueño de lo que no es ya del usuario (partidas y estados
# guardados crecen; un chown -R completo en cada arranque es I/O inútil)
find "${ES_HOME}" \( ! -user "${ES_USER}" -o ! -group "${ES_USER}" \) \
    -exec chown -h "${ES_USER}:${ES_USER}" {} +
chown "${ES_USER}:${ES_USER}" /roms /roms/* 2>/dev/null || true

if [[ "${1:-}" == "emulationstation" ]]; then
    shift
    # Al arrancar el equipo el contenedor puede empezar antes que el escritorio:
    # espera al socket del servidor X en vez de relanzar ES en bucle.
    X_SOCKET="/tmp/.X11-unix/X$(sed -E 's/^[^:]*:([0-9]+).*/\1/' <<<"${DISPLAY}")"
    if [[ "${DISPLAY}" == :* && ! -S "${X_SOCKET}" ]]; then
        echo ">> Esperando al servidor X (${X_SOCKET})..."
        until [[ -S "${X_SOCKET}" ]]; do sleep 2; done
    fi
    # Reinicia EmulationStation si se cierra (p. ej. "Quit" desde el menú),
    # salvo que se haya pedido detener el contenedor.
    TOOLS_GAMELIST="${ES_HOME}/.emulationstation/gamelists/herramientas/gamelist.xml"
    while true; do
        # Resumen de ROMs en los logs (docker compose logs) y ayuda de
        # Herramientas con el recuento actual, en un solo recorrido
        echo ">> ROMs detectadas:"
        gosu "${ES_USER}" env HOME="${ES_HOME}" es-rom-summary --gamelist "${TOOLS_GAMELIST}" | sed 's/^/   /'
        gosu "${ES_USER}" env HOME="${ES_HOME}" emulationstation --no-splash "$@" || true
        [[ "${ES_RESTART:-true}" == "true" ]] || break
        sleep 1
    done
else
    exec gosu "${ES_USER}" env HOME="${ES_HOME}" "$@"
fi
