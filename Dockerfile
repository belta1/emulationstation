# syntax=docker/dockerfile:1
# EmulationStation (fork de RetroPie) + RetroArch en Docker.
# Etapa 1: compila EmulationStation desde el código fuente.
# Etapa 2: imagen de ejecución con RetroArch y núcleos libretro. Se muestra
#          en el servidor X11 del host (con GPU), sin escritorio virtual.

# 24.04: su RetroArch (1.18) funciona con GNOME en Wayland; el 1.7.3 de 22.04
# se congelaba (vsync con GLX_OML_sync_control bajo Xwayland).
ARG UBUNTU_VERSION=24.04

############################
# Etapa 1: build
############################
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG ES_REPO=https://github.com/RetroPie/EmulationStation.git
ARG ES_VERSION=v2.11.2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates pkg-config \
        libsdl2-dev libfreeimage-dev libfreetype-dev libcurl4-openssl-dev \
        rapidjson-dev libasound2-dev libgl-dev libglu1-mesa-dev \
        libboost-filesystem-dev libboost-system-dev libboost-locale-dev \
        libboost-date-time-dev \
        libvlc-dev libvlccore-dev \
        # Mupen64Plus-Next (N64)
        nasm zlib1g-dev libpng-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${ES_VERSION}" --recurse-submodules \
        "${ES_REPO}" /src/EmulationStation

# Tema por defecto (sin tema ES solo muestra texto plano)
ARG THEME_REPO=https://github.com/RetroPie/es-theme-carbon.git
RUN git clone --depth 1 "${THEME_REPO}" /src/themes/carbon \
    && rm -rf /src/themes/carbon/.git

WORKDIR /src/EmulationStation/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DGL=ON .. \
    && make -j"$(nproc)" \
    && strip --strip-unneeded ../emulationstation

# Núcleos que Ubuntu no empaqueta; se compilan desde el código fuente y se
# dejan en /src/cores.
RUN mkdir -p /src/cores

# NES: FCEUmm
ARG FCEUMM_REPO=https://github.com/libretro/libretro-fceumm.git
RUN git clone --depth 1 "${FCEUMM_REPO}" /src/fceumm \
    && make -C /src/fceumm -f Makefile.libretro -j"$(nproc)" \
    && cp /src/fceumm/fceumm_libretro.so /src/cores/

# Arcade (CPS1/2/3, Neo Geo, Sega System 16, Toaplan, Konami...): FinalBurn Neo
ARG FBNEO_REPO=https://github.com/libretro/FBNeo.git
RUN git clone --depth 1 "${FBNEO_REPO}" /src/fbneo \
    && make -C /src/fbneo/src/burner/libretro -j"$(nproc)" \
    && cp /src/fbneo/src/burner/libretro/fbneo_libretro.so /src/cores/

# PlayStation: PCSX ReARMed. Mucho más ligero que Beetle PSX y acepta
# cualquier BIOS de la carpeta bios/ (scph1001.bin, scph5501.bin...), con
# BIOS emulada (HLE) si no hay ninguna.
ARG PCSX_REPO=https://github.com/libretro/pcsx_rearmed.git
RUN git clone --depth 1 --recurse-submodules "${PCSX_REPO}" /src/pcsx \
    && make -C /src/pcsx -f Makefile.libretro -j"$(nproc)" \
    && cp /src/pcsx/pcsx_rearmed_libretro.so /src/cores/

# Nintendo 64: Mupen64Plus-Next (Ubuntu 24.04 ya no empaqueta libretro-mupen64plus)
ARG MUPEN_REPO=https://github.com/libretro/mupen64plus-libretro-nx.git
RUN git clone --depth 1 "${MUPEN_REPO}" /src/mupen \
    && make -C /src/mupen -j"$(nproc)" \
    && cp /src/mupen/mupen64plus_next_libretro.so /src/cores/

# Sin símbolos de depuración: imagen más pequeña y carga más rápida
RUN strip --strip-unneeded /src/cores/*.so

############################
# Etapa 2: runtime
############################
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    ES_USER=es \
    ES_HOME=/home/es

RUN apt-get update && apt-get install -y --no-install-recommends \
        # Librerías que necesita EmulationStation (libvlc se enlaza, pero sin
        # plugins de VLC: el tema carbon no reproduce vídeos)
        libsdl2-2.0-0 libfreeimage3 libfreetype6 libcurl4t64 libasound2t64 \
        libgl1 libgl1-mesa-dri libglu1-mesa libvlc5 libvlccore9 \
        libboost-filesystem1.83.0 libboost-system1.83.0 libboost-locale1.83.0 \
        libboost-date-time1.83.0 fonts-droid-fallback fonts-dejavu-core \
        # Emulador + núcleos libretro (snes9x y genesisplusgx están en multiverse)
        retroarch \
        libretro-snes9x libretro-gambatte libretro-mgba \
        libretro-genesisplusgx \
        libretro-beetle-pce-fast \
        # Audio y utilidades
        pulseaudio-utils alsa-utils ca-certificates tini gosu procps \
        # Pantalla completa real de RetroArch en GNOME (ver tools/es-retroarch)
        wmctrl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/EmulationStation/emulationstation /usr/local/bin/emulationstation
COPY --from=builder /src/EmulationStation/resources /usr/local/share/emulationstation/resources

COPY --from=builder /src/themes /etc/emulationstation/themes
COPY --from=builder /src/cores/ /tmp/cores/

# EmulationStation busca "resources/" junto al binario.
# /usr/lib/libretro apunta a la carpeta de núcleos de la arquitectura (amd64/arm64).
RUN ln -s /usr/local/share/emulationstation/resources /usr/local/bin/resources \
    && ln -s "$(ls -d /usr/lib/*-linux-gnu/libretro)" /usr/lib/libretro \
    && mv /tmp/cores/*.so /usr/lib/libretro/ && rmdir /tmp/cores

# La imagen de 24.04 trae el usuario "ubuntu" con UID 1000: se borra para que
# "es" tenga el 1000, el habitual del usuario del host.
RUN userdel -r ubuntu 2>/dev/null; \
    useradd -m -u 1000 -d "${ES_HOME}" -s /bin/bash -G audio,video "${ES_USER}" \
    && mkdir -p /roms /etc/emulationstation/defaults \
    && chown -R "${ES_USER}:${ES_USER}" /roms

COPY config/es_systems.cfg /etc/emulationstation/es_systems.cfg
COPY config/es_input.cfg config/es_settings.cfg config/retroarch.cfg /etc/emulationstation/defaults/
COPY config/retroarch-forzado.cfg /etc/emulationstation/retroarch-forzado.cfg
COPY tools/es-rom-summary tools/es-retroarch /usr/local/bin/
COPY ["tools/Recargar lista de juegos.sh", "/opt/es-tools/"]
COPY config/retroarch-autoconfig/ /etc/retroarch/autoconfig/
COPY config/retroarch-remaps/ /etc/retroarch/remaps/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/es-rom-summary /usr/local/bin/es-retroarch /opt/es-tools/*.sh

VOLUME ["/roms", "/home/es/.emulationstation", "/home/es/.config/retroarch"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["emulationstation"]
