---
tags: [arte, animacao, combate, godot, tecnologia, mapa]
atualizado: 2026-11-14
---
# Arte e animação no jogo (passada de beleza e fluidez)

O que foi construído no projeto Godot a partir da [[Pesquisa - Arte e Animação]], a pedido do Italo em 2026-11-14 ([[Pedidos do Italo]]). Vale para os três heróis. **O corpo base aprovado não mudou**: mesmas proporções, mesmo rosto, mesmo macacão liso. Mudou como ele se mexe, como é iluminado e o que acontece na tela quando um golpe acerta.

## 1. Animação dos heróis #animacao
Arquivos: `Godot/scripts/boneco3d.gd` (motor), `Godot/scripts/poses.gd` (todas as poses), `Godot/scripts/hero.gd` (liga o estado do jogo à animação).

- **Molas em cada junta.** Antes o boneco ia de uma pose para a outra em linha reta. Agora cada junta persegue a pose com uma mola (frequência e amortecimento próprios), então o corpo passa um pouco do ponto e assenta. O braço chega antes, o tronco e a cabeça chegam depois (sobreposição), e o cabelo balança como um pêndulo.
- **Golpe em quatro tempos:** antecipação (o corpo recolhe, rápido), balanço (acelera até o quadro do acerto), contato (a pose fica segura por alguns quadros, junto com a pausa de impacto) e recuperação (volta devagar para a guarda). É a receita dos jogos de luta e de ação anime.
- **Quatro cortes diferentes para o Kael:** diagonal de cima, ascendente, estocada e o golpe pesado por cima da cabeça. A Lyra ganhou base de arqueira mais baixa (a flecha sai da altura do arco) e chutes com rastro no pé. O Oren gira o cajado nos dois primeiros golpes.
- **Estica e amassa** (sem mudar o volume): o corpo estica ao sair do chão e amassa ao pousar, mais forte quanto maior a queda.
- **Parado com vida:** respiração, troca de peso entre as pernas, cabeça que acompanha. **Corrida** com inclinação e braços em oposição; correndo de verdade inclina mais.
- **Pulo em fases:** impulso, subida, topo e queda têm poses diferentes, escolhidas pela velocidade vertical.
- **Virada:** ao trocar de lado o corpo passa de frente para a câmera e assenta.
- **Durante a pausa de impacto** o herói congela na pose do contato e o inimigo atingido treme no lugar.
- **Tempestade de Aço (Kael):** o corpo gira de verdade com a lâmina estendida, e termina no golpe pesado.
- **Fúria:** pose nova para o corte de cena, com a arma em diagonal na frente do corpo e o rosto livre.

## 2. Rastro da arma #combate
O arco de luz pintado em 2D saiu. O rastro agora é **medido na lâmina de verdade**: a cada quadro (4 medidas por quadro durante o balanço) o jogo pega a base e a ponta da arma no boneco 3D, leva para o plano do jogo e desenha uma fita suavizada que afina e apaga em 7 quadros. O rastro só existe no balanço, nunca na antecipação. Chutes da Lyra usam o pé. Arquivos: `gfx.gd` (`rastro`), `game.gd` (`rastro`), `fx_layer.gd`.

## 3. Sombreamento anime #arte
Arquivos: `shaders/toon.gdshader`, `contorno.gdshader`, `heroi_sprite.gdshader`.

- **Sombra colorida, não cinza.** A parte na sombra puxa para um tom frio e mais saturado próprio de cada material (pele, tecido, cabelo, madeira), como em anime. A passagem luz/sombra é uma faixa limpa e sem serrilhado.
- **Rosto** quase sem sombra dura, para ficar sempre legível.
- **Cabelo** com a faixa de brilho ("anel de anjo").
- **Contorno tingido:** cada peça tem o contorno na versão escura da sua própria cor, em vez de preto puro.
- **Luz de recorte** na silhueta (lado da lua), feita no sprite, sem borda escura em volta do boneco.
- Regras respeitadas: nada de sombra transparente sobre o rosto, macacão liso.

## 4. Impacto e câmera #combate
Arquivos: `game.gd`, `gfx.gd`, `fx_layer.gd`, `enemy.gd`.

- **Pausa de impacto por peso:** 3 quadros no golpe leve, 7 no pesado, +2 no crítico, 1 nos acertos repetidos, 5 quando o herói apanha.
- **Tremor de câmera por "trauma":** some suave, usa ruído no lugar de sorteio, e tem um empurrão na direção do golpe. Respeita a opção de tremor.
- **Aproximação rápida da câmera** no golpe pesado e na morte do chefe.
- **Câmera lenta** curta ao limpar uma sala e ao derrotar o chefe.
- **Faísca de impacto em camadas:** clarão pequeno em cruz, agulhas na direção do golpe, anel que afina; animada em passos, como efeito desenhado.
- **Faíscas** com arrasto, **poeira** ao pousar, correr e esquivar.
- **Imagens fantasma** na esquiva: cópias do próprio boneco, tiradas na placa de vídeo, que somem em 14 quadros.
- **Números de dano** que saltam e assentam. Herói pisca em vermelho ao apanhar.

## 5. Cenário e imagem final #mapa #arte
Arquivos: `shaders/vitral.gdshader` (novo), `cenario.gdshader`, `raio.gdshader`, `vinheta.gdshader`, `cenario3d.gd`.

- **Vitrais de verdade:** desenhados por shader, com chumbo, losangos, rosácea e medalhões, brilhando por dentro.
- **Pedra** com desgaste e juntas de bloco. **Chão molhado** refletindo os braseiros.
- **Raios de luz** dos vitrais mais suaves, com poeira.
- **Cor final da imagem:** sombras puxadas para o azul violeta, luzes para o quente, curva de contraste e cantos escurecidos, aplicado na tela inteira por baixo da interface.

## 6. Interface
- O retrato no painel de vida agora **segue a cabeça** do boneco (antes saía do quadro quando o herói se mexia).
- O corte de cena da Fúria mostra a arma inteira.

## Para testar sem jogar (ferramenta)
`main.gd` aceita duas variáveis de ambiente, só para testes: `LIGA_TESTE=jogo` pula os menus e `LIGA_ROTEIRO=<caminho de um .gd>` carrega um script que joga sozinho e tira capturas. Foi assim que cada animação foi conferida quadro a quadro.

## O que ficou para depois #pendente
- Animação dos inimigos no mesmo nível dos heróis (molas, antecipação).
- Fundo com mais camadas e vida (pássaros, bandeiras distantes), e uma segunda paleta para a fase 2.
- Expressões de rosto (dor, esforço, vitória) trocando a textura dos olhos e da boca.
- Efeitos próprios por habilidade (cada suprema com seu desenho).
- Roupas e armaduras por cima do corpo base, quando os equipamentos entrarem ([[Equipamentos]]).

Ver também: [[Direção de Arte]] · [[Combate]] · [[Projeto Godot]] · [[Changelog]]
