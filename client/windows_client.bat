@echo off
setlocal enabledelayedexpansion

:: --- Configuración ---
set SIDE=client
set MODS_DIR=%APPDATA%\.minecraft\mods
set PYTHON_DIR=.\python_vanilla
set PYTHON_BIN=%PYTHON_DIR%\python.exe
set "PYTHON_URL=https://github.com/astral-sh/python-build-standalone/releases/download/20250106/cpython-3.10.16+20250106-x86_64-pc-windows-msvc-shared-install_only.tar.gz"
set "MAIN_PY_URL=https://raw.githubusercontent.com/Gekk0-asm/mods/refs/heads/main/assets/main.py"
set MAIN_PY=main.py

echo --- Iniciando Sistema ---

:: 1. Verificar / descargar Python portable
if not exist "%PYTHON_BIN%" (
    echo [+] Python portable no encontrado. Descargando...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'python_portable.tar.gz'"
    if not exist "python_portable.tar.gz" (
        echo Error: No se pudo descargar el archivo.
        pause & exit /b 1
    )
    echo [+] Extrayendo...
    if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
    tar -xzf python_portable.tar.gz -C "%PYTHON_DIR%" --strip-components=1
    del python_portable.tar.gz 2>nul
    echo [✓] Python portable listo.
)

:: 2. Instalar requests
if not exist "%PYTHON_DIR%\.requests_installed" (
    echo [+] Configurando entorno Python e instalando 'requests'...
    "%PYTHON_BIN%" -m ensurepip --upgrade >nul
    "%PYTHON_BIN%" -m pip install --no-cache-dir requests >nul
    if %errorlevel% equ 0 (
        echo Done > "%PYTHON_DIR%\.requests_installed"
        echo [✓] 'requests' instalado.
    ) else (
        echo Error instalando dependencias.
        pause & exit /b 1
    )
)

:: 3. Descargar main.py
echo [+] Actualizando %MAIN_PY%...
powershell -Command "Invoke-WebRequest -Uri '%MAIN_PY_URL%' -OutFile '%MAIN_PY%'"
if errorlevel 1 (
    echo Error: No se pudo descargar el script principal.
    pause & exit /b 1
)

:: 4. Ejecutar main.py
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"
echo --- Sincronizando mods para el cliente original ---
"%PYTHON_BIN%" "%MAIN_PY%" --side %SIDE% --path "%MODS_DIR%"
if errorlevel 1 (
    echo [!] Error durante la sincronización.
    echo Revisa los mensajes anteriores.
    pause
    exit /b 1
) else (
    echo [✓] Mods sincronizados correctamente.
)

:: 5. Buscar el lanzador en varias ubicaciones conocidas
echo.
echo Buscando el ejecutable del Launcher de Minecraft...
set "LAUNCHER_FOUND="

for %%F in (
    "%ProgramFiles(x86)%\Minecraft\MinecraftLauncher.exe"
    "%ProgramFiles(x86)%\Minecraft Launcher\MinecraftLauncher.exe"
    "%ProgramFiles(x86)%\Mojang\minecraft launcher\Minecraft Launcher.exe"
    "%APPDATA%\.minecraft\launcher.exe"
) do (
    if not defined LAUNCHER_FOUND (
        if exist %%F (
            set "LAUNCHER_FOUND=%%~F"
            echo [+] Encontrado en: %%~F
        )
    )
)

:: 6. Lanzar el launcher (o intentar protocolo minecraft:)
if defined LAUNCHER_FOUND (
    echo Abriendo %LAUNCHER_FOUND%...
    start "" "%LAUNCHER_FOUND%"
) else (
    echo [!] No se encontro el ejecutable en las rutas tipicas.
    echo Intentando abrir con el protocolo minecraft: ...
    start minecraft:
    if errorlevel 1 (
        echo [X] Error al intentar abrir el launcher mediante el protocolo.
    ) else (
        echo [✓] Launcher abierto correctamente via protocolo minecraft:.
    )
)

endlocal
pause
exit
