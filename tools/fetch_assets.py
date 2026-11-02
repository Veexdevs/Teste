#!/usr/bin/env python3
"""Baixa os modelos 3D prontos (glTF/GLB) usados pelo SENTINELA.

Os GLB sao guardados com a extensao .bin para o Godot os copiar como bytes
puros para dentro do PCK (o importador do editor nao e usado). Nao e
necessario Git LFS: usamos a API de blobs do GitHub, que devolve o conteudo
em base64.

Utilizacao:
    python3 tools/fetch_assets.py            # busca e valida tudo
    python3 tools/fetch_assets.py --check    # apenas valida o que existe
"""
import argparse
import base64
import json
import os
import shutil
import struct
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = os.path.join(ROOT, "game", "assets", "models")
WEAPONS = os.path.join(MODELS, "weapons")
LICENSES = os.path.join(ROOT, "game", "assets", "licenses")
TOOLKIT_MODELS = os.path.join(ROOT, ".toolkit", "models")

# (ficheiro de saida, repositorio, ref, caminho no repositorio, licenca)
SOURCES = [
    ("soldier.bin", "mrdoob/three.js", "dev",
     "examples/models/gltf/Soldier.glb", "Adobe Mixamo / three.js (CC0 rig)"),
    ("helmet.bin", "KhronosGroup/glTF-Sample-Assets", "main",
     "Models/DamagedHelmet/glTF-Binary/DamagedHelmet.glb", "CC BY 4.0 - theblueturtle"),
    ("sniper_rifle.bin", "GodotVR/godot-xr-tools", "master",
     "assets/3dmodelscc0/models/sniper_rifle/sniper_rifle.glb", "CC0 - 3dmodelscc0"),
]

WEAPON_BINS = [
    "ak47.bin", "ak47_low.bin", "arms_m4a1.bin",
    "assault_rifle.bin", "m4a1.bin", "vm_mp5.bin",
]


def token():
    try:
        out = subprocess.check_output(["gh", "auth", "token"], stderr=subprocess.DEVNULL)
        return out.decode().strip()
    except Exception:
        return os.environ.get("GITHUB_TOKEN", "")


def api(url):
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "sentinela-asset-fetch")
    tok = token()
    if tok:
        req.add_header("Authorization", "Bearer " + tok)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def valid_glb(data):
    if len(data) < 20 or data[:4] != b"glTF":
        return False, "magic invalido"
    version, length = struct.unpack_from("<II", data, 4)
    if version != 2:
        return False, "versao glTF %d" % version
    if length != len(data):
        return False, "comprimento %d != %d" % (length, len(data))
    return True, "glTF 2.0, %d bytes" % len(data)


def fetch_glb(name, repo, ref, path, _license=""):
    dest = os.path.join(MODELS, name)
    if os.path.isfile(dest):
        with open(dest, "rb") as f:
            ok, info = valid_glb(f.read())
        if ok:
            print("OK (cache) %-22s %s" % (name, info))
            return True
        print("AVISO: %s corrompido, vou buscar de novo" % name)
    meta = api("https://api.github.com/repos/%s/contents/%s?ref=%s" % (repo, path, ref))
    sha = meta["sha"]
    blob = api("https://api.github.com/repos/%s/git/blobs/%s" % (repo, sha))
    data = base64.b64decode("".join(blob["content"].split()))
    ok, info = valid_glb(data)
    if not ok:
        print("ERRO %s: %s" % (name, info))
        return False
    with open(dest, "wb") as f:
        f.write(data)
    print("OK (download) %-20s %-32s %s" % (name, repo, info))
    return True


def copy_weapons():
    ok = True
    for name in WEAPON_BINS:
        src = os.path.join(TOOLKIT_MODELS, name)
        dst = os.path.join(WEAPONS, name)
        if os.path.isfile(dst):
            with open(dst, "rb") as f:
                good, info = valid_glb(f.read())
            if good:
                print("OK (cache) weapons/%-18s %s" % (name, info))
                continue
        if not os.path.isfile(src):
            print("ERRO: falta %s (corre a workflow fetch-models no CI)" % src)
            ok = False
            continue
        with open(src, "rb") as f:
            data = f.read()
        good, info = valid_glb(data)
        if not good:
            print("ERRO weapons/%s: %s" % (name, info))
            ok = False
            continue
        shutil.copyfile(src, dst)
        print("OK (copia)   weapons/%-18s %s" % (name, info))
    return ok


def write_licenses():
    os.makedirs(LICENSES, exist_ok=True)
    entries = {
        "README.md": """# Creditos dos modelos 3D

O SENTINELA usa modelos 3D prontos, em formato glTF 2.0 binario (GLB),
carregados em runtime. Nenhum destes ficheiros e um produto de uma fabricante
de armas; tratam-se de reconstrucoes artisticas de dominio publico/licencas
abertas usadas apenas como adereco visual numa simulacao ficcional.

| Ficheiro | Origem | Licenca |
| --- | --- | --- |
| `soldier.bin` | `mrdoob/three.js` - `examples/models/gltf/Soldier.glb` | Rig Adobe Mixamo "Vanguard" redistribuido no repositorio three.js |
| `helmet.bin` | `KhronosGroup/glTF-Sample-Assets` - DamagedHelmet | CC BY 4.0, autoria "theblueturtle" |
| `sniper_rifle.bin` | `GodotVR/godot-xr-tools` - `3dmodelscc0` | CC0 1.0 |
| `weapons/*.bin` | modelos glTF de arma de repositorios publicos de demonstracao | Consultar `THIRD_PARTY_WEAPONS.md` |

Todo o codigo, materiais, texturas procedurais e sons sao gerados neste
projecto (sem ficheiros de imagem ou audio externos).
""",
        "THIRD_PARTY_WEAPONS.md": """# Modelos de terceiros (armas)

Os seis GLB em `game/assets/models/weapons/` foram obtidos pela workflow de CI
`.github/workflows/fetch-models.yml` a partir de repositorios publicos de
demonstracao de jogos/visores glTF. Sao usados apenas como malha de viewmodel
e de arma em terceira pessoa, sem qualquer associacao comercial.

| Ficheiro | Repositorio de origem | Ficheiro de origem |
| --- | --- | --- |
| `m4a1.bin` | `JoseRamonRenteroJimenez/DVI_G8` | `assets/glb/M4A1.glb` |
| `ak47.bin` | `loingtan/fps-threejs-game` | `src/assets/guns/ak47/ak47.glb` |
| `vm_mp5.bin` | `shadow-kernel/Vortex-Engine-Horror-Template` | `Assets/Models/Viewmodel/vm_mp5.glb` |
| `arms_m4a1.bin` | `skyelynwaddell/vector0-godot` | `blender/arms_m4a1.glb` |
| `assault_rifle.bin` | `habibmukhlis/3D-shooter-game` | `public/assets/models/assault_rifle.glb` |
| `ak47_low.bin` | `aminere/powerplay-threejs` | `game/public/models/resources/ak47.glb` |

Os repositorios de origem nao acompanham uma declaracao de licenca explicita
para estas malhas de demonstracao. Se e autor de algum destes modelos e
pretender a sua remocao ou um credito especifico, abra uma issue no
repositorio do projecto. O jogo funciona na integra sem estes ficheiros:
`game/core/models.gd` gera armas procedurais como fallback automatico.
""",
    }
    for name, text in entries.items():
        with open(os.path.join(LICENSES, name), "w", encoding="utf-8") as f:
            f.write(text)
    print("OK (creditos) %s" % LICENSES)


def check_only():
    ok = True
    for name, *_ in SOURCES:
        p = os.path.join(MODELS, name)
        if not os.path.isfile(p):
            print("FALTA %s" % name)
            ok = False
            continue
        with open(p, "rb") as f:
            good, info = valid_glb(f.read())
        print("%-22s %s" % (name, info))
        ok = ok and good
    for name in WEAPON_BINS:
        p = os.path.join(WEAPONS, name)
        if not os.path.isfile(p):
            print("FALTA weapons/%s (opcional, existe fallback)" % name)
            continue
        with open(p, "rb") as f:
            good, info = valid_glb(f.read())
        print("weapons/%-18s %s" % (name, info))
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--no-download", action="store_true",
                    help="apenas copia armas e escreve creditos")
    args = ap.parse_args()
    os.makedirs(MODELS, exist_ok=True)
    os.makedirs(WEAPONS, exist_ok=True)
    if args.check:
        return 0 if check_only() else 1
    ok = True
    if not args.no_download:
        for row in SOURCES:
            try:
                ok = fetch_glb(*row) and ok
            except (urllib.error.URLError, KeyError, OSError) as e:
                print("ERRO ao obter %s: %s" % (row[0], e))
                ok = False
    ok = copy_weapons() and ok
    write_licenses()
    print("RESULTADO: %s" % ("OK" if ok else "INCOMPLETO (fallbacks procedurais activos)"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
