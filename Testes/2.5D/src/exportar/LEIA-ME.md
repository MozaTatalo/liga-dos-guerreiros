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
