#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Optional


def load_json(file_path: str) -> dict:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error leyendo {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

def load_json_from_url(url: str) -> dict:
    """Descarga el JSON desde la URL remota en lugar de leerlo localmente."""
    print(f"📦 Descargando lista de mods desde {url}...", file=sys.stderr)
    try:
        result = subprocess.run(
            ['curl', '-L', '-s', url],
            capture_output=True,  # Captura stdout y stderr
            text=True,
            check=True
        )
        return json.loads(result.stdout) # Carga el contenido descargado
    except subprocess.CalledProcessError as e:
        print(f"❌ Error al descargar el JSON. Código: {e.returncode}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ El contenido descargado no es un JSON válido: {e}", file=sys.stderr)
        sys.exit(1)


def download_file(url: str, dest_path: Path) -> bool:
    try:
        subprocess.run(
            ['curl', '-L', '-s', '-o', str(dest_path), url],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        return False

def load_cache(cache_file: Path) -> Dict[str, Optional[str]]:
    if cache_file.exists():
        try:
            with open(cache_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except:
            return {}
    return {}



def save_cache(cache_file: Path, cache: Dict[str, Optional[str]]):
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(cache, f, indent=2)



def sync_mods(mode: str, target_dir: str):
    json_file = "mods.json"
    if not os.path.isfile(json_file):
        print(f"❌ No se encuentra {json_file}", file=sys.stderr)
        sys.exit(1)

    data = load_json_from_url(json_file)
    if "mods" not in data:
        print("❌ El JSON debe contener una clave 'mods'", file=sys.stderr)
        sys.exit(1)

    if mode == "server":
        valid_sides = {"server", "both"}
    elif mode == "client":
        valid_sides = {"client", "both"}
    else:
        print(f"❌ Modo inválido: {mode}", file=sys.stderr)
        sys.exit(1)

    target_path = Path(target_dir)
    target_path.mkdir(parents=True, exist_ok=True)

    # Recolectar mods y dependencias
    items_map: Dict[str, dict] = {}
    for mod in data["mods"]:
        if mod.get("side") not in valid_sides:
            continue

        name = mod["name"]
        url = mod["url"]
        version = mod.get("version")
        if name not in items_map:
            items_map[name] = {"url": url, "version": version}

        for dep in mod.get("dependencies", []):
            dep_name = dep["name"]
            dep_url = dep["url"]
            dep_version = dep.get("version")
            if dep_name not in items_map:
                items_map[dep_name] = {"url": dep_url, "version": dep_version}

    cache_file = target_path / f".mods_cache_{mode}.json"
    cache = load_cache(cache_file)

    updated_cache = {}
    for name, info in items_map.items():
        jar_file = target_path / f"{name}.jar"
        cached_version = cache.get(name)
        current_version = info.get("version")
        need_download = False

        if not jar_file.exists():
            need_download = True
            print(f"[+] Nuevo: {name}", file=sys.stderr)
        elif current_version is not None and cached_version != current_version:
            need_download = True
            print(f"[↻] Versión cambiada: {name} ({cached_version} -> {current_version})", file=sys.stderr)

        if need_download:
            print(f"    Descargando {name} desde {info['url']} ...", file=sys.stderr)
            if download_file(info["url"], jar_file):
                print(f"    ✅ {name} descargado", file=sys.stderr)
                updated_cache[name] = current_version
            else:
                print(f"    ❌ Error en {name}", file=sys.stderr)
                updated_cache[name] = cached_version
        else:
            updated_cache[name] = cached_version if cached_version is not None else current_version

    # Limpiar obsoletos
    current_names = set(items_map.keys())
    for cached_name in list(cache.keys()):
        if cached_name not in current_names:
            jar_path = target_path / f"{cached_name}.jar"
            if jar_path.exists():
                print(f"[-] Eliminando obsoleto: {cached_name}", file=sys.stderr)
                jar_path.unlink()

    save_cache(cache_file, updated_cache)
    print(f"✅ Sincronización completada en {target_dir}", file=sys.stderr)

    # --- Imprimir la lista de mods actuales por STDOUT ---
    for name in sorted(current_names):
        print(name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["server", "client"])
    parser.add_argument("target_dir", nargs="?", default="./mods")
    args = parser.parse_args()
    sync_mods(args.mode, args.target_dir)