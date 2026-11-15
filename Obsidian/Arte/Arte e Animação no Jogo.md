---
tags: [arte, animacao, combate, godot, tecnologia, mapa]
atualizado: 2026-11-15
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

## 7. Efeitos de golpes e poderes (2026-11-15) #combate #arte
Pedido do Italo: "está na hora dos efeitos de ataques e poderes terem mais efeitos e serem mais bonitos" ([[Pedidos do Italo]]). Arquivos: `Godot/scripts/efeitos.gd` (novo, todos os efeitos), `Godot/shaders/energia.gdshader` (novo), `fx_layer.gd`, e ganchos em `hero.gd`, `game.gd`, `enemy.gd`. Só visual: dano, alcance e tempo dos golpes não mudaram.

**Como é feito.** Três camadas de efeito por cima do jogo: **luz** (brilhos suaves e riscos, somados à imagem), **energia** (formas com textura de ruído que corre, miolo claro e borda que se desfaz ao sumir, em passos, como efeito desenhado) e **matéria** (fumaça e lascas de pedra, que não brilham). Cada efeito é montado com peças: meia-lua, anel, feixe, bola, fita, relâmpago, círculo de runas, rosácea, brasas, chamas, fumaça, lascas e centelhas.

**Cada classe tem a sua linguagem.**
- **Kael (ouro e aço):** meias-luas douradas na frente de cada corte, estocada com lança de luz, onda no chão no golpe pesado, barreira de energia na investida de escudo, selo da rosácea no contra-ataque.
- **Lyra (vento verde e flecha dourada):** clarão e anel de vento na ponta do arco, flechas com fita de luz, cone de energia e anéis nas flechas fortes, meias-luas verdes nos chutes.
- **Oren (arcano azul, fogo e violeta):** círculo de runas na frente do cajado a cada conjuração, círculo no chão nas magias de área, pilar de energia, orbes com cauda.

**Habilidades.**
- Kael: Investida de Escudo com barreira e rastro; Lâmina Ascendente com coluna e meia-lua subindo; **Tempestade de Aço** com três meias-luas girando em dois andares, rosácea no chão e explosão em casca no final.
- Lyra: **Rajada Tripla** com três flechas de vento; **Flecha Perfurante** como um raio dourado com anéis; **Chuva de Flechas** com riscos verdes caindo e respingo de vento em cada flecha no chão.
- Oren: **Orbe Flamejante** com chama, fumaça e explosão em anéis; **Corrente de Raios** com relâmpago vivo que muda de desenho e estala em cada alvo; **Meteoro** com alvo de runas, cauda de fogo, coluna, onda no chão, lascas e fumaça.

**Fúria.** O despertar agora tem leque de luz, três anéis, coluna e o símbolo da classe: rosácea (Kael), anéis de vento subindo (Lyra), runas do eclipse (Oren). Desperto, o herói fica com línguas de fogo pelos lados, sem cobrir o corpo.

**Outros.** Acerto diferente por tipo de golpe (corte, pancada, flecha, magia). Carga de mana com anel e coluna que estouram a cada nível. Morte dos inimigos com estouro próprio. O aviso de golpe dos inimigos virou um anel branco que se fecha (continua branco, regra do Italo). Explosões grandes crescem em tamanho, não em branco, para não esconder a cena.

## Para testar sem jogar (ferramenta)
`main.gd` aceita duas variáveis de ambiente, só para testes: `LIGA_TESTE=jogo` pula os menus e `LIGA_ROTEIRO=<caminho de um .gd>` carrega um script que joga sozinho e tira capturas. Foi assim que cada animação foi conferida quadro a quadro.

## O que ficou para depois #pendente
- Animação dos inimigos no mesmo nível dos heróis (molas, antecipação).
- Fundo com mais camadas e vida (pássaros, bandeiras distantes), e uma segunda paleta para a fase 2.
- Expressões de rosto (dor, esforço, vitória) trocando a textura dos olhos e da boca.
- Efeitos dos inimigos e do chefe no mesmo nível dos heróis (hoje só o aviso, os projéteis e a morte foram refeitos).
- Roupas e armaduras por cima do corpo base, quando os equipamentos entrarem ([[Equipamentos]]).

Ver também: [[Direção de Arte]] · [[Combate]] · [[Projeto Godot]] · [[Changelog]]
