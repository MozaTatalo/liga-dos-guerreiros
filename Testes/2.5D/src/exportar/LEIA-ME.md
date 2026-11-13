# Exportar os bonecos para o Godot

Gera `kael.glb`, `lyra.glb`, `oren.glb` e as texturas de olhos fechados em `Godot/assets/personagens/`
a partir do `../kael.js` (fonte da verdade do modelo).

```
cd Testes/2.5D/src/exportar
npm install three@0.128.0 playwright
npx playwright install chromium
node exportar.js
```

Só a base (macacão, cabelo e armas de madeira) é exportada. O contorno de cada peça vai como malha `ct_<espessura x 10000>`.

## Mapa gótico e espectro
`node cenario.js` gera `Godot/assets/cenario/catedral.glb` (ruínas da catedral do `gotico.html`, estendidas ao comprimento da fase,
com as plataformas nas mesmas posições das plataformas de colisão) e `Godot/assets/inimigos/espectro.glb`.
Escala: 1 unidade = 26 px do jogo; plano de jogo em z = 0 e chão em y = 0. Se mudar `PLATS` no `game_data.gd`, mude também no `cenario.js`.
