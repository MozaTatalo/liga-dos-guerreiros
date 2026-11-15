---
tags: [planejamento, analise, projeto, pendente]
criado: 2026-11-14
versao_analisada: 0.5
---
# Análise Completa do Jogo

Pedido do Italo em 2026-11-14: analisar **tudo** que o jogo precisa para virar um jogo de ação lateral completo no gênero de Grand Chase e Elsword (só o gênero e as mecânicas, tudo original), e ir construindo. Esta nota é o mapa geral. O andamento fica em [[Roteiro de Versões]].

Legenda: ✅ já existe · 🟡 existe pela metade · ❌ falta · 🔨 entra na versão 0.6

## 1. Onde o jogo está hoje (v0.5)
- ✅ 3 heróis com corpo base 3D aprovado (Kael, Lyra, Oren), cel-shading e contorno
- ✅ 1 fase gótica 3D (Ruínas de Arvália) com 2 áreas, chefe e portal
- ✅ 5 inimigos (Lodo, Espectro, Conjurador, Morcego, Espectro Ancião)
- 🟡 Combate: combo de 3 no chão, esquiva, 3 habilidades por classe. Sem golpes no ar, sem lançar inimigo, sem variação
- 🟡 Interface: painel de vida simples, tela de título que já é a seleção. Sem menus
- ❌ Progressão, equipamentos em jogo, som, salvamento, lobby, multijogador

O que dá a "cara" do gênero e ainda não temos: **combos longos com inimigo no ar**, **fluxo de menus** (título, lobby, seleção de personagem, seleção de fase, resultado com recompensa), **progressão** (nível, equipamento, habilidades) e **som**.

## 2. Combate #combate
O coração do gênero. É o que mais muda a sensação do jogo.

| Item | Estado | O que fazer |
|---|---|---|
| Dois botões de ataque (leve e pesado) | 🔨 | Z leve, X pesado. Combos misturam os dois (ZZZ, ZZX, ZX...) |
| Combo no ar | 🔨 | Golpes durante o pulo, com descida em mergulho (↓ + ataque) |
| Lançador | 🔨 | ↑ + ataque joga o inimigo para cima e abre o combo aéreo |
| Ataque correndo | 🔨 | Golpe próprio saindo da esquiva ou da corrida |
| Inimigo no ar (juggle) | 🔨 | Inimigo lançado fica vulnerável, cai, quica e levanta |
| Derrubada e levantar | 🔨 | Inimigo derrubado fica um instante no chão; pesa menos a cada golpe para o combo não ser infinito |
| Corrida (toque duplo) | 🔨 | → → corre mais rápido, como no gênero |
| Rank de combo | 🔨 | Palavras que sobem com o combo (Bom, Ótimo, Brutal, Lendário) e bônus de experiência |
| Barra de Fúria (despertar) | ✅ v0.7 | Enche batendo e apanhando; ativa um estado forte por alguns segundos, com visual próprio |
| Defesa e contra-ataque | ✅ v0.7 | Kael defende com o escudo; defesa no tempo certo abre contra-ataque |
| Golpe pelas costas e crítico | 🟡 | Crítico existe. Falta bônus por acertar pelas costas |
| Agarrão, golpe de levantar | ❌ depois | Para variedade e para o modo contra jogadores |
| Super armadura visível | 🟡 | Chefe tem super armadura e, desde a v0.7, quebra de postura. Falta o brilho |
| Elementos e estados (fogo, gelo, veneno, atordoar) | ❌ depois | Entra com equipamentos e inimigos novos |
| Cancelamentos | 🟡 | Golpe em habilidade já cancela. Falta golpe em esquiva e em pulo |

### Movimentos únicos por classe
Cada classe precisa de **moveset próprio**, não só habilidades diferentes:
- **Kael (Guardião):** combos de espada, escudada (X) que empurra, lançador de espada, mergulho com a espada. Depois: defesa.
- **Lyra (Caçadora):** flechas (Z), chute que afasta (X), tiro para cima, tiro diagonal no ar, salto para trás.
- **Oren (Arcanista):** rajadas mágicas (Z), explosão curta (X), pilar que lança, teleporte no lugar da esquiva, levitar no ar.
- **Brann (Berserker):** planejado. Lento e pesado, com super armadura nos golpes fortes.

## 3. Habilidades #combate #classe
- 🟡 3 habilidades por classe com mana e recarga
- ✅ (v0.7) 4º espaço para a **habilidade suprema** (gasta a barra de Fúria, com corte de cena e tela escurecida)
- ❌ Árvore de habilidades: desbloquear e melhorar com pontos ao subir de nível
- ❌ Escolher quais habilidades levar para a fase (espaços A, S, D, F)
- 🔨 Ícones desenhados para cada habilidade, no lugar dos quadrados coloridos
- ❌ Passivas de classe

## 4. Personagens e classes #personagem #classe
- ✅ Corpo base masculino e feminino aprovados (não mexer)
- 🟡 Lyra usa a cabeça do Kael como provisória. **Falta rosto e cabelo próprios para Lyra e Oren**
- ❌ Roupas e armaduras de cada personagem em jogo (hoje todos de macacão base)
- ❌ Armas de verdade no lugar das de madeira
- ❌ Mais personagens: Brann e pelo menos mais 2 (sugestão: uma lutadora ágil de adagas e um suporte que cura)
- ❌ Evolução de classe (cada classe abre 2 caminhos no nível 15)
- ❌ Animações: mais golpes, vitória, derrota, entrada na fase, parado com personalidade, expressões do rosto
- ❌ Vozes curtas de golpe

## 5. Progressão #sistema
- 🔨 Experiência e nível por personagem, com atributos subindo
- 🔨 Ouro ganho nas fases
- 🔨 Jogo salvo (progresso guardado no computador)
- ❌ Equipamentos que caem dos inimigos e do chefe, com raridade (comum, raro, épico, lendário)
- ❌ Inventário e tela de equipar (os espaços já existem no modelo: arma, armadura, manto)
- ❌ Loja, melhoria de equipamento
- ❌ Missões diárias e conquistas
- ❌ Títulos e visuais (roupas só de aparência)

## 6. Interface e menus #interface
| Tela | Estado | Notas |
|---|---|---|
| Tela de título | 🔨 | Logo, "aperte para começar", fundo vivo |
| Menu principal / lobby | 🔨 | Jogar, Personagens, Opções. O herói escolhido aparece grande |
| Seleção de personagem | 🔨 | Modelo grande girando, atributos em barras, habilidades, nível |
| Seleção de fase | 🔨 | Mapa do mundo com pontos, dificuldade, melhor rank |
| HUD da fase | 🔨 | Molduras góticas, retrato, vida, mana, experiência, ícones de habilidade, combo com rank, barra de chefe em camadas |
| Tela de resultado | 🔨 | Rank, experiência subindo, ouro, nível novo |
| Pausa | 🔨 | Continuar, reiniciar, lista de golpes, sair |
| Opções | 🟡 🔨 | Volume primeiro. Depois: teclas, tela cheia, controle |
| Inventário e equipamento | ❌ v0.8 | |
| Árvore de habilidades | ❌ v0.8 | |
| Loja | ❌ depois | |
| Tutorial | ❌ v0.7 | Fase curta de treino com as teclas na tela |
| Lista de golpes | 🔨 | Dentro da pausa |
| Chat, amigos, salas | ❌ com o multijogador | |

Estilo da interface: gótico elegante. Molduras escuras com filete dourado, vitrais como tema de cor, fonte serifada de título. Nada infantil.

## 7. Mapas #mapa
- ✅ Fase 1 com início, meio, chefe e fim
- ❌ Estrutura de masmorra do gênero: **salas ligadas por portais**, com caminho principal e salas opcionais
- ❌ Mais fases. Sugestão de primeiro mundo, 5 fases góticas: Ruínas de Arvália (pronta), Cripta dos Sussurros, Floresta Morta, Torre do Relógio, Catedral Afundada (chefe do mundo)
- ❌ Perigos de cenário: espinhos, plataformas que caem, fogo, vento
- ❌ Objetos quebráveis com ouro e itens
- ❌ Dificuldades (normal, difícil, pesadelo) com recompensa melhor
- ✅ (v0.7) Introdução do chefe com faixas de cinema e nome na tela
- ❌ Cidade/lobby andável (ver decisão abaixo)

## 8. Inimigos e chefes #inimigo #chefe
- ✅ 4 comuns e 1 chefe em 3D
- 🔨 Reações novas: lançado no ar, derrubado, levantando
- ❌ Variedade: esqueleto com escudo (obriga golpe pesado), gárgula que mergulha, necromante que invoca, cão espectral rápido, armadura viva lenta
- ❌ Elites (versão brilhante, mais forte, com um poder extra)
- ❌ Mini chefe no meio da fase
- 🟡 (v0.7) Golpes avisados no chão (área vermelha) e quebra de postura prontos no Espectro Ancião. Falta chefe com fases de verdade
- ❌ Um chefe por fase

## 9. Áudio #audio
- ❌ Hoje o jogo é mudo
- 🔨 Efeitos: golpe, acerto, crítico, pulo, esquiva, habilidade, dano, moeda, menu, vitória
- 🔨 Música de fundo simples para menu e fase (provisória, feita por código)
- ❌ Trilha de verdade (orquestra gótica com coro, mais agitada no chefe)
- ❌ Vozes

## 10. Visual e polimento #arte
- ✅ Mapa gótico 3D, luzes, névoa, brilho
- 🔨 Fonte própria (serifada gótica) no lugar da fonte padrão
- 🔨 Efeitos de golpe por classe (rastro da espada, flecha com luz, runas)
- ❌ Rastro da arma em 3D, poeira ao correr e cair
- ✅ (v0.7) Corte de cena na habilidade suprema (Fúria)
- ❌ Zoom e câmera lenta no golpe final do chefe
- ❌ Retratos desenhados para diálogos
- ❌ Ícone e nome final do jogo, tela de carregamento

## 11. Multijogador #multijogador
Planejado desde o começo: o jogo já trabalha com lista de jogadores e cada herói lê comandos de uma fonte separada.
1. **Cooperativo local** (2 jogadores no mesmo PC, teclado + controle). Mais simples, entra primeiro.
2. **Cooperativo online até 4** com um jogador como anfitrião (ele decide o que acontece, os outros mandam comandos). Sala com código para convidar.
3. **Lobby online**: salas, chat, prontidão, escolha de fase pelo líder.
4. **Arena contra jogadores** (1v1 e 2v2) depois que o combate estiver equilibrado.

Regras que já seguimos para não ter retrabalho: lógica em passos fixos (60 por segundo), nada de regra de jogo dentro do desenho, inimigos miram "o jogador mais próximo", comandos passam pelo `PlayerInput`.

## 12. Tecnologia #tecnologia
- 🔨 Jogo salvo em arquivo
- 🔨 Organizar dados em arquivos por assunto (classes, fases, inimigos)
- ❌ Suporte a controle
- ❌ Remapear teclas
- ❌ Versão Windows para baixar (hoje: navegador e abrir no Godot)
- ❌ Mais idiomas

## 13. Decisões do Italo #decisao
1. **Esquema de combate (decidido 2026-11-14):** um botão de ataque com variações por direção, e habilidades carregadas segurando o botão até a barra encher no nível 1, 2 ou 3. A tabela da seção 2 foi escrita antes da escolha; o que vale está em [[Combate]].
2. **Lobby (decidido 2026-11-14):** menu com o herói em destaque. Sem cidade andável.
3. Em aberto #pendente: próximos personagens, nome do mundo e história, estilo dos rostos de Lyra e Oren.

## 14. Ordem de construção
Ver [[Roteiro de Versões]].
