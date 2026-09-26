# EmulationStation en Docker

Imagen Docker con **EmulationStation** (fork de RetroPie, compilado desde el código fuente), **RetroArch** y un conjunto de núcleos libretro, lista para usar desde el navegador (noVNC) o como ventana nativa en un escritorio Linux (X11).

## Estructura

```
emulationstation-docker/
├── Dockerfile           # multi-etapa: compila ES → imagen de ejecución con RetroArch
├── docker-compose.yml   # servicios "emulationstation" (noVNC) y "es-x11" (X11 del host)
├── entrypoint.sh        # arranca Xvfb/VNC o usa X11, prepara la config y lanza ES
├── config/
│   ├── es_systems.cfg   # sistemas y comando de lanzamiento de cada uno
│   ├── es_input.cfg     # mapeo de teclado por defecto
│   └── retroarch.cfg    # configuración base de RetroArch
└── roms/                # tus ROMs (montado en /roms)
```

## Sistemas incluidos

| Carpeta en `roms/` | Sistema              | Núcleo libretro   |
|--------------------|----------------------|-------------------|
| `nes`              | NES                  | FCEUmm            |
| `snes`             | Super Nintendo       | Snes9x            |
| `gb`, `gbc`        | Game Boy / Color     | Gambatte          |
| `gba`              | Game Boy Advance     | mGBA              |
| `megadrive`        | Mega Drive / Genesis | Genesis Plus GX   |
| `mastersystem`     | Master System        | Genesis Plus GX   |
| `n64`              | Nintendo 64          | Mupen64Plus       |
| `psx`              | PlayStation          | Beetle PSX        |
| `pcengine`         | PC Engine            | Beetle PCE Fast   |

Las BIOS (por ejemplo, las de PlayStation) van en `roms/bios/`.

## Uso rápido: en el navegador (cualquier sistema operativo)

```bash
cd emulationstation-docker
# copia tus ROMs, p. ej.: roms/nes/juego.nes, roms/snes/juego.sfc
docker compose up -d --build
```

Abre <http://localhost:6080/vnc.html> y pulsa **Connect**. También puedes conectar un cliente VNC a `localhost:5900`.

> EmulationStation solo muestra los sistemas que tienen al menos un juego. Si `roms/` está vacío, verás un aviso de que no hay sistemas: añade ROMs y reinicia con `docker compose restart`.

Variables opcionales (en un archivo `.env` o en la línea de comandos):

| Variable            | Por defecto    | Descripción                                   |
|---------------------|----------------|-----------------------------------------------|
| `SCREEN_RESOLUTION` | `1280x720x24`  | Resolución de la pantalla virtual             |
| `VNC_PASSWORD`      | *(vacío)*      | Contraseña VNC; sin ella el acceso es libre   |
| `NOVNC_PORT`        | `6080`         | Puerto del host para noVNC                    |
| `VNC_PORT`          | `5900`         | Puerto del host para VNC                      |
| `PUID` / `PGID`     | `1000`         | UID/GID con el que se escriben los volúmenes  |

El modo navegador usa renderizado por software (Mesa llvmpipe): va bien para sistemas de 8/16 bits y GBA; N64 y PSX pueden ir lentos. Como Xvfb no tiene sincronía vertical, EmulationStation puede usar bastante CPU mientras está en pantalla.

## Ventana nativa con GPU (Linux + X11)

```bash
xhost +local:docker                       # permite que el contenedor use tu pantalla
docker compose --profile x11 up --build es-x11
```

Monta `/tmp/.X11-unix`, `/dev/dri` (aceleración GPU Intel/AMD), `/dev/input` (mandos) y el socket de PulseAudio para el sonido. Para NVIDIA, usa el NVIDIA Container Toolkit y añade `gpus: all` al servicio.

## Controles por defecto (teclado)

**EmulationStation:** flechas para moverse · `Enter` aceptar · `Backspace` volver · `Espacio` menú (Start) · `Shift der.` Select · `RePág/AvPág` saltar páginas.

**RetroArch (en juego):** flechas · `X`=A · `Z`=B · `S`=X · `A`=Y · `Q`/`W`=L/R · `Enter`=Start · `Shift der.`=Select · `F1` menú de RetroArch · `Esc` salir y volver a EmulationStation.

Los mandos se pueden configurar desde el menú de EmulationStation (*Configure input*) y en RetroArch con `F1`.

## Personalización

La primera vez que arranca, el contenedor copia `config/*` a los volúmenes `es-config` y `retroarch-config`. A partir de entonces se usan las copias de los volúmenes, así que los cambios hechos desde los menús se conservan.

- **Añadir un sistema:** agrega un bloque `<system>` a `es_systems.cfg` y, si hace falta, el paquete `libretro-*` correspondiente en el `Dockerfile`. Para aplicar el nuevo archivo a una instalación existente: `docker compose down -v` (borra la config guardada) o edítalo dentro del volumen.
- **Otro tema:** clona cualquier tema de EmulationStation en `/etc/emulationstation/themes/` (argumento de build `THEME_REPO`) y elígelo en *UI Settings → Theme Set*.
- **Otra versión de ES:** `docker compose build --build-arg ES_VERSION=v2.11.2`.

## Comandos útiles

```bash
docker compose logs -f                         # ver logs
docker compose exec emulationstation bash      # entrar al contenedor
docker compose down                            # parar
docker compose down -v                         # parar y borrar la configuración guardada
```

## Aviso legal

La imagen no incluye ROMs ni BIOS. Usa solo copias de juegos y BIOS que poseas legalmente.
