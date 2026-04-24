#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import requests
from pathlib import Path
import json

JSON_URL = 'https://raw.githubusercontent.com/Gekk0-asm/mods/refs/heads/main/assets/list.json'
METADATA_FILE = '.mods_cache.json'


def download_file(url, dest_folder, custom_name=None):
    dest_folder = Path(dest_folder)
    dest_folder.mkdir(parents=True, exist_ok=True)

    if custom_name:
        file_name = custom_name
    else:
        file_name = url.split('/')[-1]
    
    file_path = dest_folder / file_name

    try:
        print(f'Descargando: {file_name}...')

        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()

        with open(file_path,'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f'Descarga completada: {file_path}')
        return True
    except Exception as error:
        print(f'Error al descargar {file_name}: {error}')
        return False

def fetch_json_data(url):
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as error:
        print('Error de red:', error)
        return None
    except json.JSONDecodeError:
        print('Error: El contenido descargado no es un JSON válido.')
        return None

def load_cache(path):
    cachefile = Path(path) / METADATA_FILE

    if cachefile.exists():
        try:
            with open(cachefile, 'r', encoding='utf-8') as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_cahe(path, metadata):
    cachefile = Path(path) / METADATA_FILE
    with open(cachefile, 'w', encoding='utf-8') as f:
        json.dump(cachefile, f, indent=2, ensure_ascii=False)


def main ():
    parser = argparse.ArgumentParser(description='Sincronizador de Mods')
    parser.add_argument('--side', type=str, choices=['client', 'server'], default='client', help='')
    parser.add_argument('--file', type=str, default='list.json', help='')
    parser.add_argument('--path', type=str, default='./mods', help='')
    parser.add_argument('--autoupdate', type=str, choices=['true', 'false'], default='true', help='')

    args = parser.parse_args()

    try:
        print(f'--- Descargando la versión {args.side} ---')

        data = fetch_json_data(JSON_URL)
        if not data: sys.exit(1)
        
        base_path = Path(args.path)
        base_path.mkdir(parents=True, exist_ok=True)

        cachedata = load_cache(base_path)

        target_mods = []
        for mod in data.get('mods', []):
            if mod['side'] == args.side or mod['side'] == 'both':
                filename = f'{mod['name']}.jar'
                target_mods.append({
                    'name': filename,
                    'url': mod['url'],
                    'version': mod.get('version', '')
                })

                for dep in mod.get('dependencies', []):
                    dep_filename = f'{dep['name']}.jar'
                    target_mods.append({
                        'name': dep_filename,
                        'url': dep['url'],
                        'version': mod.get('version', '')
                    })

        allowed_filenames = {m['name'] for m in target_mods}

        print('--- Verificando archivos ---')
        for existing_file in base_path.glob('*.jar'):
            if existing_file.name not in allowed_filenames:
                print(f'Eliminando mod no listado: {existing_file.name}')
                existing_file.unlink()

        for mod in target_mods:
            mod_path = base_path / mod['name']

            if not mod_path.exists():
                success = download_file(mod['url'], base_path, mod['name'])
                
        print("\n--- Sincronización finalizada. ---")

        # print(target_mods)
    except Exception as error:
        print(error)


if __name__ == '__main__':
    main()