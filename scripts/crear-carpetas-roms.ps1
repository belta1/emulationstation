# Crea la carpeta de ROMs en Windows con una subcarpeta por sistema de
# config\es_systems.cfg (más bios\). El contenedor también las crea al
# arrancar; este script sirve para preparar la biblioteca antes.
#   powershell -ExecutionPolicy Bypass -File scripts\crear-carpetas-roms.ps1 [-Destino C:\ruta]
param(
    [string]$Destino = (Join-Path $HOME "docker_compose\config\emulationstation")
)
$ErrorActionPreference = "Stop"

$cfg = Join-Path $PSScriptRoot "..\config\es_systems.cfg"
[xml]$systems = Get-Content -Raw -Encoding UTF8 $cfg

New-Item -ItemType Directory -Force -Path (Join-Path $Destino "bios") | Out-Null
foreach ($path in $systems.systemList.system.path) {
    if ($path -like "/roms/*") {
        $name = $path.Substring("/roms/".Length)
        New-Item -ItemType Directory -Force -Path (Join-Path $Destino $name) | Out-Null
    }
}
Write-Host "Carpetas de ROMs listas en ${Destino}:"
Get-ChildItem -Directory $Destino | ForEach-Object { Write-Host "  $($_.Name)" }
