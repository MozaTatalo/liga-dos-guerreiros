const { chromium } = require('playwright'); const fs = require('fs');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('console', m => console.log('LOG', m.text().slice(0,200)));
  await p.goto('file://' + __dirname + '/exportar.html');
  const src = fs.readFileSync(__dirname + '/../kael.js', 'utf8');
  const out = __dirname + '/../../../../Godot/assets/personagens/'; fs.mkdirSync(out, { recursive: true });
  for (const [nome, corpo, pal] of [['kael', 'm', 0], ['lyra', 'f', 2], ['oren', 'm', 1]]) {
    const r = await p.evaluate(([s, c, pl]) => exportar(s, c, pl), [src, corpo, pal]);
    fs.writeFileSync(out + nome + '.glb', Buffer.from(r.glb, 'base64'));
    fs.writeFileSync(out + nome + '_olhos_fechados.png', Buffer.from(r.fechado.split(',')[1], 'base64'));
    console.log(nome, r.malhas);
  }
  await b.close();
})();
