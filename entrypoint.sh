#!/usr/bin/env bash
# Prepara la configuración y arranca EmulationStation.
#
# DISPLAY_MODE:
#   vnc  -> Xvfb + x11vnc + noVNC (abre http://localhost:6080 en el navegador)
#   x11  -> usa el servidor X del host (monta /tmp/.X11-unix y pasa DISPLAY)
set -euo pipefail

ES_USER="${ES_USER:-es}"
ES_HOME="${ES_HOME:-/home/es}"
DEFAULTS=/etc/emulationstation/defaults

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

chown -R "${ES_USER}:${ES_USER}" "${ES_HOME}"
chown "${ES_USER}:${ES_USER}" /roms /roms/* 2>/dev/null || true

# Resumen de ROMs en los logs (docker compose logs)
echo ">> ROMs detectadas:"
gosu "${ES_USER}" env HOME="${ES_HOME}" es-rom-summary | sed 's/^/   /'

case "${DISPLAY_MODE:-vnc}" in
    vnc)
        export DISPLAY=:99
        rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
        mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
        gosu "${ES_USER}" Xvfb :99 -screen 0 "${SCREEN_RESOLUTION:-1280x720x24}" -nolisten tcp &
        for _ in $(seq 1 50); do [[ -e /tmp/.X11-unix/X99 ]] && break; sleep 0.1; done

        VNC_ARGS=(-display :99 -forever -shared -rfbport "${VNC_PORT:-5900}" -quiet)
        if [[ -n "${VNC_PASSWORD:-}" ]]; then
            gosu "${ES_USER}" x11vnc -storepasswd "${VNC_PASSWORD}" "${ES_HOME}/.vncpass" >/dev/null
            VNC_ARGS+=(-rfbauth "${ES_HOME}/.vncpass")
        else
            VNC_ARGS+=(-nopw)
        fi
        gosu "${ES_USER}" x11vnc "${VNC_ARGS[@]}" &
        websockify --web /usr/share/novnc "${NOVNC_PORT:-6080}" "localhost:${VNC_PORT:-5900}" >/dev/null 2>&1 &
        echo ">> noVNC disponible en http://localhost:${NOVNC_PORT:-6080}/vnc.html"
        ;;
    x11)
        : "${DISPLAY:?DISPLAY_MODE=x11 requiere la variable DISPLAY}"
        ;;
    *)
        echo "DISPLAY_MODE desconocido: ${DISPLAY_MODE}" >&2
        exit 1
        ;;
esac

if [[ "${1:-}" == "emulationstation" ]]; then
    shift
    # En modo vnc la pantalla es virtual: ventana a tamaño completo del Xvfb
    ES_ARGS=(--no-splash)
    if [[ "${DISPLAY_MODE:-vnc}" == "vnc" ]]; then
        IFS=x read -r W H _ <<<"${SCREEN_RESOLUTION:-1280x720x24}"
        ES_ARGS+=(--resolution "${W}" "${H}" --windowed)
    fi
    # Reinicia EmulationStation si se cierra (p. ej. "Quit" desde el menú),
    # salvo que se haya pedido detener el contenedor.
    TOOLS_GAMELIST="${ES_HOME}/.emulationstation/gamelists/herramientas/gamelist.xml"
    while true; do
        # Regenera la ayuda de Herramientas con el recuento de ROMs actual
        gosu "${ES_USER}" mkdir -p "$(dirname "${TOOLS_GAMELIST}")"
        gosu "${ES_USER}" env HOME="${ES_HOME}" es-rom-summary --gamelist > "${TOOLS_GAMELIST}"
        chown "${ES_USER}:${ES_USER}" "${TOOLS_GAMELIST}"
        gosu "${ES_USER}" env HOME="${ES_HOME}" emulationstation "${ES_ARGS[@]}" "$@" || true
        [[ "${ES_RESTART:-true}" == "true" ]] || break
        sleep 1
    done
else
    exec gosu "${ES_USER}" env HOME="${ES_HOME}" "$@"
fi
