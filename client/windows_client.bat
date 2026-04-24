@echo off
setlocal enabledelayedexpansion

:: --- Configuración fija ---
set SIDE=client
set MODS_DIR=.\mods
set PYTHON_BIN=.\python\python.exe
set PYTHON_URL=https://github.com/astral-sh/python-build-standalone/releases/download/20260414/cpython-3.10.20%2B20260414-x86_64-pc-windows-msvc-install_only_stripped.tar.gz
set MAIN_PY_URL=https://raw.githubusercontent.com/Gekk0-asm/mods/refs/heads/main/assets/main.py
set MAIN_PY=main.py

echo --- Iniciando Sistema (cliente fijo) ---

:: 1. Verificar / descargar Python portable
if not exist "%PYTHON_BIN%" (
    echo [+] Python portable no encontrado. Descargando...
    :: Usar curl si está disponible, sino bitsadmin
    where curl >nul 2>&1
    if %errorlevel% equ 0 (
        curl -L -o python_portable.tar.gz "%PYTHON_URL%"
    ) else (
        bitsadmin /transfer mydownload /download /priority normal "%PYTHON_URL%" "%cd%\python_portable.tar.gz" >nul
    )
    if errorlevel 1 (
        echo Error: No se pudo descargar Python portable
        exit /b 1
    )
    echo [+] Extrayendo...
    :: Usar tar si está, sino usar PowerShell para extraer
    where tar >nul 2>&1
    if %errorlevel% equ 0 (
        tar -xzf python_portable.tar.gz
    ) else (
        :: Extraer con PowerShell (expandir .tar.gz)
        powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $gz = [System.IO.Compression.ZipFile]::OpenRead('python_portable.tar.gz'); $target = '.\python'; $gz.Entries | Where-Object { $_.Name -ne '' } | ForEach-Object { $out = Join-Path $target $_.FullName; [System.IO.Compression.ZipFile]::ExtractToDirectory($gz, $target) }" 2>nul
        if errorlevel 1 (
            echo Error: No se pudo extraer el archivo. Instala tar (Git Bash) o usa PowerShell manual.
            del python_portable.tar.gz 2>nul
            exit /b 1
        )
    )
    del python_portable.tar.gz 2>nul
    echo [✓] Python portable instalado en .\python
)

:: 2. Instalar requests (si no está)
echo [+] Verificando/instalando 'requests'...
"%PYTHON_BIN%" -m ensurepip --upgrade >nul 2>&1
if errorlevel 1 (
    echo Error: ensurepip fallo
    exit /b 1
)
:: Verificar si requests ya está instalado
"%PYTHON_BIN%" -m pip show requests >nul 2>&1
if errorlevel 1 (
    echo Instalando requests...
    "%PYTHON_BIN%" -m pip install --no-cache-dir requests >nul 2>&1
    if errorlevel 1 (
        echo Error: No se pudo instalar requests
        exit /b 1
    )
)
echo [✓] 'requests' disponible

:: 3. Descargar main.py (siempre la última versión)
echo [+] Descargando ultima version de %MAIN_PY% ...
where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -L -o "%MAIN_PY%" "%MAIN_PY_URL%"
) else (
    bitsadmin /transfer mydownload2 /download /priority normal "%MAIN_PY_URL%" "%cd%\%MAIN_PY%" >nul
)
if errorlevel 1 (
    echo Error: No se pudo descargar %MAIN_PY%
    exit /b 1
)
echo [✓] %MAIN_PY% descargado correctamente

:: 4. Ejecutar main.py con argumentos fijos
echo --- Sincronizando mods ---
"%PYTHON_BIN%" "%MAIN_PY%" --side %SIDE% --path %MODS_DIR%
if errorlevel 1 (
    echo Error durante la sincronizacion. Abortando.
    exit /b 1
)

echo --- Proceso completado ---
endlocal