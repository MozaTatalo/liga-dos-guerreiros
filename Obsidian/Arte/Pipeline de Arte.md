---
tags: [arte, decisao]
---
# Pipeline de Arte

**Recomendação:** PixelLab para gerar a base + Aseprite para acabamento.

- **PixelLab:** gera personagens em pixel art com várias direções e animações (andar, atacar), tilesets e objetos, mantendo estilo consistente a partir de uma referência. Ótimo para volume e velocidade.
- **Aseprite (pago, barato):** padrão da indústria para pixel art. Usar para limpar pixels, ajustar paleta, refinar quadros de ataque e montar spritesheets. IA sozinha costuma errar em animações de combate rápidas.
- **Alternativas:** Retro Diffusion (bom para cenários e itens), LibreSprite (versão gratuita do Aseprite), ou contratar um pixel artist para os personagens principais quando o jogo estiver mais maduro.

## Padrões sugeridos #pendente
- Personagens com cerca de 48–64 px de altura, cenário com tiles de 16 ou 32 px.
- Paleta única do jogo (ex.: 32 a 48 cores) para tudo combinar.
- Animações mínimas por personagem: parado, correr, pular, cair, 3 golpes do combo, 3 habilidades, dano, morte.

## Alternativa em avaliação (2026-11-13)
**Substituído.** O Italo escolheu personagens em 3D em tempo real com tom gótico. O pipeline novo está em [[Direção de Arte]] e [[Personagens em 2.5D]]. O texto acima sobre pixel art fica só como histórico.

## Pipeline atual: Blender (2026-11-15) #arte #decisao
Para tirar a cara de protótipo, cenários e inimigos passam a ser **modelados no Blender** em vez de montados com formas prontas no código. Plano completo em [[Plano de Acabamento Visual]].

O Blender roda na nuvem como módulo Python (`pip install bpy`, versão 5.3), então tudo é feito por scripts guardados no projeto e pode ser refeito a qualquer hora:

- **`Godot/ferramentas/blender/catedral.py`** — a nave da catedral da Fase 1. Modela pilares compostos com base e capitel, arcos ogivais moldados, parede de vitrais com óculos, a rosácea gigante atrás da arena, bancos tombados, entulho, braseiros, plataformas presas por correntes e as silhuetas da cidade ao longe. Renderiza com o Cycles (luz da lua atravessando os vitrais, oclusão, névoa com raios de luz) em **camadas por profundidade**: longe, meio (vitrais), perto (arcada), chão (visto de cima), borda da frente e plataformas. `python catedral.py previa 30 97` faz prévias na câmera do jogo; `python catedral.py camadas` gera as camadas e `python finalizar.py` converte para WebP em `assets/cenario/fase1/`.
- **`Godot/ferramentas/blender/espectro.py`** — o Espectro (monge caído). Malha única com esqueleto de 18 ossos, textura pintada assada (degradê, dobras, faixa bordada, oclusão) e 6 animações feitas à mão (parado, andar, preparo, golpe, dor, morte). `python espectro.py previa preparo 8` mostra uma pose; `python espectro.py exportar` grava `assets/inimigos/espectro_novo.glb` e a textura (`TIPO=atirador` gera a do Conjurador).
- **No Godot:** cada camada é um retrato posto na profundidade certa, então a câmera do jogo dá o parallax sozinha (`cenario3d.gd`, `shaders/camada.gdshader`). O inimigo usa o mesmo shader anime dos heróis, com contorno (`espectro_novo.gd`).
- **Tecla V** alterna entre o visual antigo e o novo durante o jogo, para comparar.
