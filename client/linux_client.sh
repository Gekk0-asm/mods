#!/bin/bash

# --- Configuración fija ---
SIDE="client"
MODS_DIR="./mods"
PYTHON_BIN="./python/bin/python3"
PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260414/cpython-3.10.20%2B20260414-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz"
MAIN_PY_URL="https://raw.githubusercontent.com/Gekk0-asm/mods/refs/heads/main/assets/main.py" 
MAIN_PY="main.py"

echo "--- Iniciando Sistema (cliente fijo) ---"

# 1. Verificar / descargar Python portable
if [ ! -f "$PYTHON_BIN" ]; then
    echo "[+] Python portable no encontrado. Descargando..."
    curl -L -o python_portable.tar.gz "$PYTHON_URL"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo descargar Python portable"
        exit 1
    fi
    echo "[+] Extrayendo..."
    tar -xzf python_portable.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo extraer el archivo"
        exit 1
    fi
    rm python_portable.tar.gz
    echo "[✓] Python portable instalado en ./python"
fi

# 2. Instalar requests (siempre verificar que esté)
echo "[+] Verificando/instalando 'requests'..."
$PYTHON_BIN -m ensurepip --upgrade
if ! $PYTHON_BIN -m pip show requests; then
    echo "Instalando requests..."
    $PYTHON_BIN -m pip install --no-cache-dir requests
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo instalar requests"
        exit 1
    fi
else
    echo "requests ya está instalado"
fi
echo "[✓] 'requests' listo"

# 3. Descargar main.py (siempre la última versión)
echo "[+] Descargando última versión de $MAIN_PY ..."
curl -L -o "$MAIN_PY" "$MAIN_PY_URL"
if [ $? -ne 0 ] || [ ! -f "$MAIN_PY" ]; then
    echo "Error: No se pudo descargar $MAIN_PY"
    exit 1
fi
echo "[✓] $MAIN_PY descargado correctamente"

# 4. Ejecutar main.py con argumentos fijos (client y ./mods)
echo "--- Sincronizando mods ---"
$PYTHON_BIN "$MAIN_PY" --side "$SIDE" --path "$MODS_DIR"
if [ $? -ne 0 ]; then
    echo "Error durante la sincronización. Abortando."
    exit 1
fi

echo "--- Proceso completado ---"
