# Converte as camadas renderizadas (PNG em _bruto/) para WebP leve e copia o camadas.json para o Godot.
import json, os, shutil
from PIL import Image
AQUI = os.path.dirname(os.path.abspath(__file__))
FASE = os.path.normpath(os.path.join(AQUI, "..", "..", "assets", "cenario", "fase1"))
BRUTO = os.path.join(FASE, "_bruto")
meta = json.load(open(os.path.join(BRUTO, "camadas.json")))
def tiles(m):
    for k, v in m.items():
        if k == "plat":
            for p in v: yield from p["tiles"]
        elif isinstance(v, dict):
            yield from v["tiles"]
for t in tiles(meta):
    im = Image.open(os.path.join(BRUTO, t["arq"]))
    dest = os.path.join(FASE, os.path.splitext(t["arq"])[0] + ".webp")
    im.save(dest, "WEBP", quality=88, method=6)
    print(dest, im.size, os.path.getsize(dest) // 1024, "KB")
json.dump(meta, open(os.path.join(FASE, "camadas.json"), "w"), indent=1)
