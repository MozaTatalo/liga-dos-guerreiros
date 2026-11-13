---
tags: [arte, tecnologia, decisao]
atualizado: 2026-11-13
---
# Personagens em 2.5D

**Pedido (2026-11-13):** o Italo não está convencido da pixel art feita no PixelLab e quer avaliar criar os personagens em 2.5D. Esta nota reúne os caminhos possíveis e a recomendação. **Escolha do Italo (2026-11-13): caminho A, 3D em tempo real**, com tom gótico e sério. Ver [[Direção de Arte]]. O projeto Godot ainda não foi alterado.

**Teste jogável:** `Testes\2.5D\index.html` (abrir no navegador, precisa de internet) ou https://claude.ai/artifact/9ZC1YW8KiXrXTRaund4op6. Teclas 1, 2 e 3 trocam o estilo, C gira a câmera. O boneco é de blocos, feito só para comparar os estilos, não é a arte final.

## O que já ajuda
No [[Projeto Godot]] a lógica (movimento, combo, golpes, IA) é separada do desenho (`gfx.gd`). Trocar o visual dos personagens não mexe no combate nem na base de multijogador, porque a rede só sincroniza comandos e posições.

## Caminho A: modelo 3D em tempo real num plano 2D (recomendado)
Personagens são modelos 3D com esqueleto, com cel shading e contorno, e o jogo continua lateral. É como Grand Chase e Elsword funcionam.
- **Visual:** anime/cartum 3D, animação lisa, giro de corpo, câmera pode aproximar em golpes especiais.
- **Ferramentas:** Blender (gratuito) para ajustes. Geração por IA a partir de uma arte conceitual: Meshy, Tripo, Rodin ou Hunyuan3D (este roda no próprio PC). Esqueleto automático: Mixamo ou AccuRig (gratuitos).
- **Animação:** uma animação serve para vários personagens (mesmo esqueleto). Biblioteca do Mixamo para base, Cascadeur ou Blender para os golpes. É o caminho com menos trabalho por animação nova.
- **Armas por classe:** a arma é uma peça presa na mão. Trocar arma ou visual não exige redesenhar nada.
- **Combate:** animação 3D pode parecer "mole". Resolve com poses fortes, pausa no impacto e tempos curtos, que o código já controla.
- **Projeto atual:** a lógica fica. Troca-se a camada de desenho por uma cena 3D e a resolução sobe de 480×270 para HD.
- **Risco:** modelos de IA pedem limpeza (malha, pesos do esqueleto) e todos precisam seguir o mesmo estilo.

## Caminho B: modelo 3D exibido como pixel art
O mesmo modelo 3D do caminho A, mostrado em baixa resolução e com animação a 12 quadros por segundo (ao vivo ou pré-renderizado em spritesheets, como Dead Cells).
- **Visual:** cara de pixel art, com consistência perfeita entre quadros.
- **Vantagem:** aproveita a resolução atual do jogo (480×270) e mantém o clima retrô. Animações novas saem do modelo.
- **Limite:** pixel art "de render" é menos charmosa que a desenhada à mão, e rostos pequenos perdem detalhe.

## Caminho C: sprites 2D em cenário 3D (estilo HD-2D)
Personagens continuam sprites (PixelLab ou renders), mas o cenário é 3D com profundidade, luz e sombra.
- **Visual:** muito bonito em cenário e iluminação.
- **Limite:** não resolve a dúvida sobre os personagens, que continuam sendo sprites quadro a quadro. Cada golpe novo ainda é desenhado.

## Caminho D: boneco 2D articulado (cut-out)
Personagem desenhado em partes (cabeça, tronco, braços) e animado com ossos 2D no próprio Godot, como MapleStory faz com equipamentos.
- **Visual:** 2D ilustrado em alta resolução. Troca de equipamento fácil.
- **Limite:** não tem giro nem profundidade de verdade. Golpes muito dinâmicos ficam duros.

## Recomendação
**Caminho A**, com o B como variação de estilo: os dois usam o mesmo modelo 3D, então dá para decidir o acabamento (liso ou pixelado) depois, sem refazer personagens. Primeiro passo proposto: fazer o Kael em 3D (conceito, geração do modelo, esqueleto, 5 ou 6 animações) e colocá-lo numa cópia de teste do projeto Godot, sem tocar no jogo atual.

Ver também: [[Pipeline de Arte]] · [[Classes e Armas]] · [[Engine e Plataforma]]
