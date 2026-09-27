# EmulationStation en Docker

Imagen Docker con **EmulationStation** (fork de RetroPie, compilado desde el código fuente), **RetroArch** y un conjunto de núcleos libretro, que se muestra a pantalla completa en el escritorio del equipo (Linux + X11), con aceleración por GPU, sonido y mandos del host.

## Estructura

```
emulationstation/
├── Dockerfile           # multi-etapa: compila ES → imagen de ejecución con RetroArch
├── docker-compose.yml   # servicio "emulationstation" en el X11 del host
├── entrypoint.sh        # prepara la config y lanza ES en la pantalla del host
├── config/
│   ├── es_systems.cfg   # sistemas y comando de lanzamiento de cada uno
│   ├── es_input.cfg     # mapeos por defecto: teclado, Xbox 360/One/Series y PlayStation Classic
│   ├── es_settings.cfg  # ajustes de ES para gastar menos CPU/GPU (ahorro de energía)
│   ├── retroarch.cfg    # configuración base de RetroArch (2 jugadores)
│   └── retroarch-autoconfig/  # perfiles de RetroArch por mando (Xbox 360/One/Series, PS Classic)
├── tools/               # lanzador de juegos (es-retroarch), sistema "Herramientas" y resumen de ROMs
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
| `n64`              | Nintendo 64          | Mupen64Plus-Next  |
| `psx`              | PlayStation          | PCSX ReARMed      |
| `pcengine`         | PC Engine            | Beetle PCE Fast   |
| `arcade`           | Arcade (CPS1/2/3, Neo Geo, System 16, Toaplan, Konami…) | FinalBurn Neo |

Las BIOS van en la subcarpeta `bios/`. **PlayStation:** vale cualquier BIOS original con su nombre de siempre (`SCPH1001.BIN`, `scph5501.bin`, `scph7001.bin`…, en mayúsculas o minúsculas); sin BIOS, PCSX ReARMed usa una emulada (HLE), con la que algunos juegos fallan. Los juegos van en `psx/` como `.cue` + `.bin` (el `.cue` tiene que nombrar el `.bin` exactamente), `.chd`, `.pbp` o `.m3u` para los de varios discos.

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

La carpeta y sus subcarpetas se crean solas la primera vez que arranca el contenedor. Si quieres crearlas antes para ir copiando juegos:

```bash
./scripts/crear-carpetas-roms.sh                                      # Linux / macOS
powershell -ExecutionPolicy Bypass -File scripts\crear-carpetas-roms.ps1   # Windows
```

Para usar otra carpeta, crea un archivo `.env` junto a `docker-compose.yml` con `ROMS_DIR=/ruta/a/tus/roms`. Los scripts aceptan la ruta como argumento (`-Destino` en PowerShell).

## Desplegar con Portainer (stack desde repositorio Git)

1. **Stacks → Add stack → Repository**. URL del repositorio, referencia `refs/heads/main`, *Compose path* `docker-compose.yml` y, si el repositorio es privado, activa *Authentication* con tus credenciales de GitHub.
2. En **Environment variables** añade `ROMS_DIR` con la **ruta absoluta** de la carpeta de ROMs en el equipo, por ejemplo `/home/tu_usuario/docker_compose/config/emulationstation`. Con Portainer no uses `~`: Compose se ejecuta dentro del contenedor de Portainer y `~` no apunta al home de tu usuario. Si la pantalla no es `:0` añade `DISPLAY`, y si tu usuario no tiene UID 1000 añade `XDG_RUNTIME_DIR` (`/run/user/<tu UID>`, para el sonido) junto con `PUID`/`PGID`.
   El equipo tiene que tener la sesión gráfica abierta y haber ejecutado `xhost +local:docker` en ella (por ejemplo, desde el inicio automático del escritorio). Si el contenedor arranca antes que el escritorio, espera al servidor X.
3. **Deploy the stack**. La primera vez compila la imagen (tarda un rato, sobre todo FinalBurn Neo).
4. Para actualizar: **Pull and redeploy**. `docker-compose.yml` tiene `pull_policy: build`, así que la imagen se reconstruye en cada despliegue con los últimos cambios (con caché, solo lo que cambió).

Para comprobar que corre la versión actual, mira los logs del contenedor en Portainer: al arrancar deben mostrar `>> ROMs detectadas:` con la tabla de carpetas. Si no aparece, se está usando una imagen antigua: borra la imagen `emulationstation:latest` en **Images** y vuelve a desplegar.

## Uso rápido (Linux + X11)

```bash
git clone https://github.com/belta1/emulationstation.git && cd emulationstation
xhost +local:docker                       # permite que el contenedor use tu pantalla
docker compose up -d --build
# copia tus ROMs, p. ej.: ~/docker_compose/config/emulationstation/nes/juego.nes, ~/docker_compose/config/emulationstation/snes/juego.sfc
```

EmulationStation se abre a pantalla completa en el escritorio. El contenedor monta `/tmp/.X11-unix`, `/dev/dri` (aceleración GPU Intel/AMD), `/dev/input` + `/run/udev` (mandos, con conexión en caliente) y el socket de PulseAudio para el sonido. Para NVIDIA, usa el NVIDIA Container Toolkit y añade `gpus: all` al servicio.

EmulationStation solo muestra los sistemas que tienen al menos un juego. Si todavía no hay ROMs, verás únicamente el sistema **Herramientas**. En él, la opción **Recargar lista de juegos** muestra en su descripción cada subcarpeta de ROMs, las extensiones que acepta y cuántos juegos se detectaron. Después de copiar juegos nuevos, elígela: EmulationStation vuelve a buscar ROMs sin reiniciar el contenedor.

El mismo resumen aparece en los logs al arrancar (`docker compose logs emulationstation`). Si un sistema marca 0 juegos, revisa que la ROM esté en su subcarpeta (por ejemplo `~/docker_compose/config/emulationstation/snes/`, no directamente en `~/docker_compose/config/emulationstation/`) y que tenga una de las extensiones de la lista.

Variables opcionales (en un archivo `.env` o en la línea de comandos):

| Variable            | Por defecto    | Descripción                                   |
|---------------------|----------------|-----------------------------------------------|
| `ROMS_DIR`          | `~/docker_compose/config/emulationstation` | Carpeta del host con las ROMs |
| `DISPLAY`           | `:0`           | Pantalla X11 del host                         |
| `XDG_RUNTIME_DIR`   | `/run/user/1000` | Carpeta con el socket de PulseAudio del usuario |
| `PUID` / `PGID`     | `1000`         | UID/GID con el que se escriben los volúmenes  |

### Rendimiento

- ES usa el **modo de ahorro de energía** (`PowerSaverMode`), sincronía vertical y transiciones instantáneas: en reposo apenas consume CPU. Se cambia en *Other Settings → Power Saver Modes* (se guarda en `es_settings.cfg`).
- RetroArch va a pantalla completa real (el lanzador `es-retroarch` se la pide a GNOME), con vsync y sin shaders, rebobinado ni *run-ahead*. Los ajustes imprescindibles están en `config/retroarch-forzado.cfg` y se aplican en cada partida, aunque tu `retroarch.cfg` sea de una versión anterior.
- Estos ajustes se copian solo en el primer arranque. Si ya tenías los volúmenes de una versión anterior, bórralos con `docker compose down -v` (pierdes la configuración y las partidas guardadas en ellos) o copia los ajustes de `config/es_settings.cfg` y `config/retroarch.cfg` a mano.
- La imagen no incluye los plugins de VLC: los temas con vídeos (el tema por defecto, carbon, no los usa) no los reproducirán.

## Mandos (2 jugadores, sin configurar nada)

Vienen preconfigurados, tanto en EmulationStation como en RetroArch:

- **Xbox 360**: cableado y con receptor inalámbrico USB.
- **Xbox One / Series por USB** (cable).
- **Xbox One S por Bluetooth** (modelos `045e:02fd` y `045e:02e0`, los que muestra `bluetoothctl info` como *Xbox Wireless Controller*).
- **Mando de PlayStation Classic** (USB).

El primer mando conectado es el jugador 1 y el segundo, el jugador 2.

| Xbox                | PlayStation Classic | EmulationStation | En el juego (RetroArch)                  |
|---------------------|---------------------|------------------|------------------------------------------|
| Cruceta / stick izq.| Cruceta             | moverse          | cruceta / stick                          |
| A                   | Cruz                | aceptar          | botón inferior (B de SNES)               |
| B                   | Círculo             | volver           | botón derecho (A de SNES)                |
| X / Y               | Cuadrado / Triángulo| —                | botón izquierdo / superior               |
| LB / RB             | L1 / R1             | saltar página    | L / R                                    |
| LT / RT             | L2 / R2             | —                | L2 / R2                                  |
| Start / Back        | Start / Select      | menú / Select    | Start / Select                           |
| **Guide (logo de Xbox)** | **Select + Start** | —           | **salir y volver a EmulationStation**    |
| **L3 + R3**         | **Select + Triángulo** | —             | **menú de RetroArch** (guardar/cargar estado, opciones) |

Los atajos de salir y abrir el menú funcionan con el mando del jugador 1. En los juegos también se puede salir con `Esc` (teclado) o desde el menú de RetroArch: **L3 + R3 → Quit RetroArch**. En el menú de RetroArch, **A acepta y B vuelve**.

**En todos los juegos el stick izquierdo mueve igual que la cruceta** (salvo en los que usan el stick analógico, como los de N64, donde sigue siendo analógico).

**NES:** **A** de Xbox = botón A de NES y **X** de Xbox = botón B de NES (la posición del mando original). Está en `config/retroarch-remaps/FCEUmm/FCEUmm.rmp`.

**Xbox One S por Bluetooth (`02fd`, firmware antiguo):** **View** y **Guide** llegan como teclas de teclado. RetroArch los reconoce igualmente (Select y salir), pero GNOME puede abrir el navegador al pulsar Guide.

Requisitos:

- **Host Linux.** El contenedor lee los mandos del host a través de `/dev/input`. Los mandos USB los expone el driver `xpad` del kernel y los Bluetooth, `hid-microsoft`: se emparejan en el escritorio del host (Configuración → Bluetooth) y el contenedor los ve igual que uno con cable. En macOS/Windows Docker no puede acceder a los mandos.
- `docker-compose.yml` ya monta todo lo necesario (`/dev/input`, `/run/udev`).
- Se pueden conectar y desconectar mandos en caliente.

Si tienes otro mando (por ejemplo un Xbox Series por Bluetooth o un clon que no se reconozca), EmulationStation mostrará su asistente de configuración: sigue las instrucciones en pantalla (o *Start → Configure Input*). En RetroArch se configura desde *Settings → Input* (`F1` o L3+R3).

> Si ya habías arrancado una versión anterior de esta imagen, la configuración guardada en los volúmenes no incluye los mandos nuevos: ejecuta `docker compose down -v` para regenerarla (borra también las partidas guardadas en los volúmenes).

## Controles por defecto (teclado)

**EmulationStation:** flechas para moverse · `Enter` aceptar · `Backspace` volver · `Espacio` menú (Start) · `Shift der.` Select · `RePág/AvPág` saltar páginas.

**RetroArch (en juego):** flechas · `X`=A · `Z`=B · `S`=X · `A`=Y · `Q`/`W`=L/R · `Enter`=Start · `Shift der.`=Select · `F1` menú de RetroArch · `Esc` salir y volver a EmulationStation.


## Personalización

La primera vez que arranca, el contenedor copia `es_input.cfg`, `es_settings.cfg` y `retroarch.cfg` a los volúmenes `es-config` y `retroarch-config`. A partir de entonces se usan las copias de los volúmenes, así que los cambios hechos desde los menús se conservan.

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
