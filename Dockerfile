# syntax=docker/dockerfile:1
# EmulationStation (fork de RetroPie) + RetroArch en Docker.
# Etapa 1: compila EmulationStation desde el código fuente.
# Etapa 2: imagen de ejecución con RetroArch, núcleos libretro y un
#          escritorio virtual opcional (Xvfb + x11vnc + noVNC).

ARG UBUNTU_VERSION=22.04

############################
# Etapa 1: build
############################
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG ES_REPO=https://github.com/RetroPie/EmulationStation.git
ARG ES_VERSION=v2.11.2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates pkg-config \
        libsdl2-dev libfreeimage-dev libfreetype6-dev libcurl4-openssl-dev \
        rapidjson-dev libasound2-dev libgl1-mesa-dev libboost-all-dev \
        libvlc-dev libvlccore-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${ES_VERSION}" --recurse-submodules \
        "${ES_REPO}" /src/EmulationStation

# Tema por defecto (sin tema ES solo muestra texto plano)
ARG THEME_REPO=https://github.com/RetroPie/es-theme-carbon.git
RUN git clone --depth 1 "${THEME_REPO}" /src/themes/carbon \
    && rm -rf /src/themes/carbon/.git

WORKDIR /src/EmulationStation/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DGL=ON .. \
    && make -j"$(nproc)"

# Ubuntu no empaqueta un núcleo de NES: se compila FCEUmm desde el código fuente
ARG FCEUMM_REPO=https://github.com/libretro/libretro-fceumm.git
RUN git clone --depth 1 "${FCEUMM_REPO}" /src/fceumm \
    && make -C /src/fceumm -f Makefile.libretro -j"$(nproc)"

############################
# Etapa 2: runtime
############################
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    ES_USER=es \
    ES_HOME=/home/es \
    DISPLAY_MODE=vnc \
    SCREEN_RESOLUTION=1280x720x24 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080

RUN apt-get update && apt-get install -y --no-install-recommends \
        # Librerías que necesita EmulationStation
        libsdl2-2.0-0 libfreeimage3 libfreetype6 libcurl4 libasound2 \
        libgl1 libgl1-mesa-dri libglu1-mesa libvlc5 libvlccore9 vlc-plugin-base \
        libboost-filesystem1.74.0 libboost-system1.74.0 libboost-locale1.74.0 \
        libboost-date-time1.74.0 fonts-droid-fallback fonts-dejavu-core \
        # Emulador + núcleos libretro
        retroarch \
        libretro-snes9x libretro-gambatte libretro-mgba \
        libretro-genesisplusgx libretro-mupen64plus libretro-beetle-psx \
        libretro-beetle-pce-fast \
        # Escritorio virtual para el modo navegador
        xvfb x11vnc novnc websockify \
        # Audio y utilidades
        pulseaudio-utils alsa-utils ca-certificates tini gosu unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/EmulationStation/emulationstation /usr/local/bin/emulationstation
COPY --from=builder /src/EmulationStation/resources /usr/local/share/emulationstation/resources

COPY --from=builder /src/themes /etc/emulationstation/themes
COPY --from=builder /src/fceumm/fceumm_libretro.so /tmp/fceumm_libretro.so

# EmulationStation busca "resources/" junto al binario.
# /usr/lib/libretro apunta a la carpeta de núcleos de la arquitectura (amd64/arm64).
RUN ln -s /usr/local/share/emulationstation/resources /usr/local/bin/resources \
    && ln -s "$(ls -d /usr/lib/*-linux-gnu/libretro)" /usr/lib/libretro \
    && mv /tmp/fceumm_libretro.so /usr/lib/libretro/

RUN useradd -m -d "${ES_HOME}" -s /bin/bash -G audio,video "${ES_USER}" \
    && mkdir -p /roms /etc/emulationstation/defaults \
    && chown -R "${ES_USER}:${ES_USER}" /roms

COPY config/ /etc/emulationstation/defaults/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/roms", "/home/es/.emulationstation", "/home/es/.config/retroarch"]
EXPOSE 5900 6080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["emulationstation"]
