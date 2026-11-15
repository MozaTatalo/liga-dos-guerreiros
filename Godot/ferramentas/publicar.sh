#!/bin/bash
# Gera a versão web e prepara a pasta para publicar como artifact.
# Uso: publicar.sh <godot> <pasta do projeto> <pasta de saída>
# O artifact recusa arquivos .pck e acima de 20 MiB, então: o motor (index.wasm) vai em gzip como
# motor.gz.wasm e é descompactado no navegador; o pacote do jogo vai como jogo.pck.wasm.
set -e
GODOT="$1"; PROJ="$2"; OUT="$3"
TMP="$PROJ/export/web"; mkdir -p "$TMP" "$OUT"; rm -f "$OUT"/*
cp "$PROJ/project.godot" /tmp/project.godot.bak
sed -i '/^Shot=/d' "$PROJ/project.godot"          # o ajudante de testes não vai para o jogo publicado
"$GODOT" --headless --path "$PROJ" --export-release Web "$TMP/index.html" > /tmp/export.log 2>&1 || { cp /tmp/project.godot.bak "$PROJ/project.godot"; tail -20 /tmp/export.log; exit 1; }
cp /tmp/project.godot.bak "$PROJ/project.godot"
cp "$TMP"/index.js "$TMP"/index.png "$TMP"/index.icon.png "$TMP"/index.apple-touch-icon.png "$TMP"/index.audio.worklet.js "$TMP"/index.audio.position.worklet.js "$OUT"/
gzip -9 -c "$TMP/index.wasm" > "$OUT/motor.gz.wasm"
cp "$TMP/index.pck" "$OUT/jogo.pck.wasm"
python3 - "$TMP/index.html" "$OUT/index.html" "$(stat -c %s "$TMP/index.pck")" <<'PY'
import sys, re
src, dst, pck = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src, encoding="utf-8").read()
ponte = """<script>
// O motor (index.wasm) vai comprimido em gzip para caber no limite de arquivo do artifact; aqui ele é descompactado no navegador.
(function () {
  var f0 = window.fetch.bind(window);
  window.fetch = async function (url, opt) {
    var u = typeof url === 'string' ? url : (url && url.url) || '';
    if (/index\\.wasm(\\?|$)/.test(u)) {
      var r = await f0(u.replace('index.wasm', 'motor.gz.wasm'), opt);
      var buf = new Uint8Array(await r.arrayBuffer());
      var bytes = buf;
      if (buf[0] === 0x1f && buf[1] === 0x8b) {
        var ds = new Response(new Blob([buf]).stream().pipeThrough(new DecompressionStream('gzip')));
        bytes = new Uint8Array(await ds.arrayBuffer());
      }
      return new Response(bytes, { status: 200, headers: { 'Content-Type': 'application/wasm', 'Content-Length': String(bytes.length) } });
    }
    return f0(url, opt);
  };
})();
</script>
"""
s = s.replace('<script src="index.js"></script>', ponte + '\t\t<script src="index.js"></script>')
s = s.replace('"executable":"index"', '"executable":"index","mainPack":"jogo.pck.wasm"')
s = re.sub(r'"index\.pck":\d+', '"jogo.pck.wasm":' + pck, s)
s = re.sub(r"<title>.*?</title>", "<title>Liga dos Guerreiros</title>", s)
assert "mainPack" in s and "motor.gz.wasm" in s
open(dst, "w", encoding="utf-8").write(s)
PY
ls -la "$OUT"
