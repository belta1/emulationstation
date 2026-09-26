# EmulationStation en Docker

Imagen Docker con **EmulationStation** (fork de RetroPie, compilado desde el código fuente), **RetroArch** y un conjunto de núcleos libretro, lista para usar desde el navegador (noVNC) o como ventana nativa en un escritorio Linux (X11).

## Estructura

```
emulationstation/
├── Dockerfile           # multi-etapa: compila ES → imagen de ejecución con RetroArch
├── docker-compose.yml   # servicios "emulationstation" (noVNC) y "es-x11" (X11 del host)
├── entrypoint.sh        # arranca Xvfb/VNC o usa X11, prepara la config y lanza ES
├── config/
│   ├── es_systems.cfg   # sistemas y comando de lanzamiento de cada uno
│   ├── es_input.cfg     # mapeos por defecto: teclado y mandos Xbox 360
│   ├── retroarch.cfg    # configuración base de RetroArch (2 jugadores)
│   └── retroarch-autoconfig/  # perfiles de RetroArch para Xbox 360 (cableado e inalámbrico)
├── tools/               # sistema "Herramientas" y resumen de ROMs (es-rom-summary)
└── scripts/             # crean la carpeta de ROMs en el host (bash y PowerShell)
```

## Sistemas incluidos

| Subcarpeta         | Sistema              | Núcleo libretro   |
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
| `arcade`           | Arcade (CPS1/2/3, Neo Geo, System 16, Toaplan, Konami…) | FinalBurn Neo |

Las BIOS (por ejemplo, las de PlayStation) van en la subcarpeta `bios/`.

**Arcade:** las ROMs se dejan comprimidas tal cual (`arcade/sf2.zip`, `arcade/mslug.zip`…) y deben ser del romset de **FinalBurn Neo** (versión actual). Los juegos de Neo Geo necesitan además `neogeo.zip` en la misma carpeta `arcade/`. Los juegos con ROMs "hijas" (clones) también necesitan el zip del juego "padre" en la misma carpeta.

## Carpeta de ROMs

Las ROMs se guardan en el host, fuera del repositorio, en **`~/docker_compose/config/emulationstation`**, con una subcarpeta por sistema:

```
~/docker_compose/config/emulationstation/
├── arcade/
├── bios/
├── gb/
├── gba/
├── gbc/
├── mastersystem/
├── megadrive/
├── n64/
├── nes/
├── pcengine/
├── psx/
└── snes/
```

En Windows es `%USERPROFILE%\docker_compose\config\emulationstation` (por ejemplo `C:\Users\tu_usuario\docker_compose\config\emulationstation`).

La carpeta y sus subcarpetas se crean solas la primera vez que arranca el contenedor. Si quieres crearlas antes para ir copiando juegos:

```bash
./scripts/crear-carpetas-roms.sh                                      # Linux / macOS
powershell -ExecutionPolicy Bypass -File scripts\crear-carpetas-roms.ps1   # Windows
```

Para usar otra carpeta, crea un archivo `.env` junto a `docker-compose.yml` con `ROMS_DIR=/ruta/a/tus/roms` (en Windows, `ROMS_DIR=D:/Juegos/roms`). Los scripts aceptan la ruta como argumento (`-Destino` en PowerShell).

## Uso rápido: en el navegador (cualquier sistema operativo)

```bash
git clone https://github.com/belta1/emulationstation.git && cd emulationstation
docker compose up -d --build
# copia tus ROMs, p. ej.: ~/docker_compose/config/emulationstation/nes/juego.nes, ~/docker_compose/config/emulationstation/snes/juego.sfc
```

Abre <http://localhost:6080/vnc.html> y pulsa **Connect**. También puedes conectar un cliente VNC a `localhost:5900`.

EmulationStation solo muestra los sistemas que tienen al menos un juego. Si todavía no hay ROMs, verás únicamente el sistema **Herramientas**. En él, la opción **Recargar lista de juegos** muestra en su descripción cada subcarpeta de ROMs, las extensiones que acepta y cuántos juegos se detectaron. Después de copiar juegos nuevos, elígela: EmulationStation vuelve a buscar ROMs sin reiniciar el contenedor.

El mismo resumen aparece en los logs al arrancar (`docker compose logs emulationstation`). Si un sistema marca 0 juegos, revisa que la ROM esté en su subcarpeta (por ejemplo `~/docker_compose/config/emulationstation/snes/`, no directamente en `~/docker_compose/config/emulationstation/`) y que tenga una de las extensiones de la lista.

Variables opcionales (en un archivo `.env` o en la línea de comandos):

| Variable            | Por defecto    | Descripción                                   |
|---------------------|----------------|-----------------------------------------------|
| `SCREEN_RESOLUTION` | `1280x720x24`  | Resolución de la pantalla virtual             |
| `VNC_PASSWORD`      | *(vacío)*      | Contraseña VNC; sin ella el acceso es libre   |
| `NOVNC_PORT`        | `6080`         | Puerto del host para noVNC                    |
| `VNC_PORT`          | `5900`         | Puerto del host para VNC                      |
| `ROMS_DIR`          | `~/docker_compose/config/emulationstation` | Carpeta del host con las ROMs |
| `PUID` / `PGID`     | `1000`         | UID/GID con el que se escriben los volúmenes  |

El modo navegador usa renderizado por software (Mesa llvmpipe): va bien para sistemas de 8/16 bits y GBA; N64 y PSX pueden ir lentos. Como Xvfb no tiene sincronía vertical, EmulationStation puede usar bastante CPU mientras está en pantalla.

## Ventana nativa con GPU (Linux + X11)

```bash
xhost +local:docker                       # permite que el contenedor use tu pantalla
docker compose --profile x11 up --build es-x11
```

Monta `/tmp/.X11-unix`, `/dev/dri` (aceleración GPU Intel/AMD), `/dev/input` + `/run/udev` (mandos, con conexión en caliente) y el socket de PulseAudio para el sonido. Para NVIDIA, usa el NVIDIA Container Toolkit y añade `gpus: all` al servicio.

## Mandos Xbox 360 (2 jugadores, sin configurar nada)

Vienen preconfigurados los mandos **Xbox 360 cableados** y los **inalámbricos con receptor USB**, tanto en EmulationStation como en RetroArch. El primer mando conectado es el jugador 1 y el segundo, el jugador 2.

| Mando Xbox 360      | EmulationStation         | En el juego (RetroArch)                  |
|---------------------|--------------------------|------------------------------------------|
| Cruceta / stick izq.| moverse                  | cruceta / stick                          |
| A                   | aceptar                  | botón inferior (B de SNES)               |
| B                   | volver                   | botón derecho (A de SNES)                |
| X / Y               | —                        | botón izquierdo / superior               |
| LB / RB             | saltar página            | L / R                                    |
| LT / RT             | —                        | L2 / R2                                  |
| Start / Back        | menú / Select            | Start / Select                           |
| **Guide (logo de Xbox)** | —                        | **salir y volver a EmulationStation**    |
| **L3 + R3**         | —                        | **menú de RetroArch** (guardar/cargar estado, opciones) |

Requisitos:

- **Host Linux.** El contenedor lee los mandos del host a través de `/dev/input`; el driver `xpad` del kernel (incluido en todas las distribuciones) los expone. En macOS/Windows Docker no puede acceder a los mandos USB.
- **Modo X11** (`es-x11`): ya monta todo lo necesario.
- **Modo navegador:** noVNC no reenvía los mandos del navegador. Si el host es Linux, descomenta las líneas de `/dev/input`, `/run/udev` y `device_cgroup_rules` del servicio `emulationstation` en `docker-compose.yml` y conecta los mandos al host.
- Se pueden conectar y desconectar mandos en caliente. En el modo navegador, conéctalos antes de arrancar el contenedor.

Si tienes otro mando (o un clon de Xbox 360 que no se reconozca), EmulationStation mostrará su asistente de configuración la primera vez: sigue las instrucciones en pantalla. En RetroArch se configura desde *Settings → Input* (`F1` o L3+R3).

> Si ya habías arrancado una versión anterior de esta imagen, la configuración guardada en los volúmenes no incluye los mandos: ejecuta `docker compose down -v` para regenerarla.

## Controles por defecto (teclado)

**EmulationStation:** flechas para moverse · `Enter` aceptar · `Backspace` volver · `Espacio` menú (Start) · `Shift der.` Select · `RePág/AvPág` saltar páginas.

**RetroArch (en juego):** flechas · `X`=A · `Z`=B · `S`=X · `A`=Y · `Q`/`W`=L/R · `Enter`=Start · `Shift der.`=Select · `F1` menú de RetroArch · `Esc` salir y volver a EmulationStation.


## Personalización

La primera vez que arranca, el contenedor copia `es_input.cfg` y `retroarch.cfg` a los volúmenes `es-config` y `retroarch-config`. A partir de entonces se usan las copias de los volúmenes, así que los cambios hechos desde los menús se conservan.

`es_systems.cfg` no se copia: se usa el de la imagen (`/etc/emulationstation/es_systems.cfg`), así que los sistemas nuevos llegan al reconstruir la imagen. Si una versión anterior había dejado una copia sin modificar en el volumen, el contenedor la borra al arrancar.

- **Añadir un sistema:** agrega un bloque `<system>` a `config/es_systems.cfg` y, si hace falta, el paquete `libretro-*` correspondiente en el `Dockerfile`, y reconstruye con `docker compose up -d --build`. Si prefieres no reconstruir, copia el archivo a `~/.emulationstation/es_systems.cfg` dentro del volumen `es-config`: EmulationStation usará esa copia en lugar de la de la imagen. Mantén en ella el sistema `herramientas`; sin él, EmulationStation vuelve a mostrar "We can't find any systems" cuando no hay ROMs.
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
