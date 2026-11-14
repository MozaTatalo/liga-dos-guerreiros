// Gera Godot/assets/cenario/catedral.glb e Godot/assets/inimigos/espectro.glb
const { chromium } = require('playwright'); const fs = require('fs');
const PLATS = [
  {x:300,y:186,w:70},{x:640,y:182,w:80},{x:1250,y:184,w:90},{x:1380,y:142,w:70},{x:1600,y:180,w:100},{x:1820,y:150,w:80},
  {x:2090,y:182,w:90},{x:2170,y:138,w:70},{x:2400,y:176,w:60},{x:2620,y:176,w:60}];
const LARG = 3150 / 26;
(async () => {
  const out = process.argv[2] || (__dirname + '/../../../../Godot/assets');
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => console.log('ERR', e.message));
  await p.goto('file://' + __dirname + '/cenario.html');
  fs.mkdirSync(out + '/cenario', { recursive: true }); fs.mkdirSync(out + '/inimigos', { recursive: true });
  fs.writeFileSync(out + '/cenario/catedral.glb', Buffer.from(await p.evaluate(([a, l]) => exportarCena(a, l), [PLATS, LARG]), 'base64'));
  fs.writeFileSync(out + '/inimigos/espectro.glb', Buffer.from(await p.evaluate(() => exportarEspectro()), 'base64'));
  await b.close();
})();
