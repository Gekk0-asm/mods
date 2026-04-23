#!/bin/bash

# --- Configuración ---
INPUT_SIDE=${1:-client}
MODS_DIR=${2:-mods}
PYTHON_BIN="./python/bin/python3"
PYTHON_URL="https://github.com/indygreg/python-build-standalone/releases/download/20240107/cpython-3.10.13+20240107-x86_64-unknown-linux-gnu-install_only.tar.gz"
MAIN_PY_URL="https://raw.githubusercontent.com/Gekk0-asm/mods/refs/heads/main/assets/main.py" 
MAIN_PY="main.py"

# Normalizar argumentos (client/server)
case "$INPUT_SIDE" in
    client)
        INPUT_SIDE="client"
        ;;
    server)
        INPUT_SIDE="server"
        ;;
    *)
        echo "Modo inválido: $INPUT_SIDE. Usa 'client' o 'server'"
        exit 1
        ;;
esac

echo "--- Iniciando Sistema ($INPUT_SIDE) ---"

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

# 2. Descargar main.py (siempre la última versión)
echo "[+] Descargando $MAIN_PY desde $MAIN_PY_URL ..."
curl -L -o "$MAIN_PY" "$MAIN_PY_URL"
if [ $? -ne 0 ] || [ ! -f "$MAIN_PY" ]; then
    echo "Error: No se pudo descargar $MAIN_PY"
    exit 1
fi
echo "[✓] $MAIN_PY descargado correctamente"

# 3. Ejecutar main.py
echo "--- Sincronizando mods ---"
$PYTHON_BIN "$MAIN_PY" "$INPUT_SIDE" "$MODS_DIR"
if [ $? -ne 0 ]; then
    echo "Error durante la sincronización. Abortando."
    exit 1
fi

echo "--- Proceso completado ---"