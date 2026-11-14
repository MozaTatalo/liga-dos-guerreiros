---
tags: [combate, sistema]
versao: 0.7
---
# Combate

Decisão do Italo (2026-11-14): **um botão de ataque** com variações por situação e direção, e **habilidades carregadas** segurando o botão até a barra de mana encher no nível 1, 2 ou 3. Ver [[Decisões]].

## Controles (teclado)
| Tecla | Ação |
|---|---|
| ← → | andar |
| → → (toque duplo) | correr |
| X, Espaço ou ↑ | pular (duas vezes) |
| ↓ + X | descer da plataforma |
| Z | atacar |
| segurar Z | carregar a mana, soltar para usar a habilidade |
| C | esquiva (atravessa golpes). Oren: teleporte |
| A | Fúria, com a barra cheia |
| ↓ (segurar) | Kael: defender |
| P ou Esc | pausa (com lista de golpes e opções) |

## Golpes (iguais na forma para todas as classes, diferentes no efeito)
| Comando | Golpe |
|---|---|
| Z Z Z Z | combo de 4 no chão; o último é pesado |
| ↓ + Z | **lançador**: joga o inimigo para o alto |
| correndo + Z (ou esquiva + Z) | **golpe de corrida** |
| no ar: Z Z Z | **combo aéreo** de 3; cada golpe segura a queda |
| no ar: ↓ + Z | **mergulho** |

Cancelamentos: depois do acerto, qualquer golpe pode virar esquiva ou pulo. Apertar Z de novo durante o golpe enfileira o próximo.

## Mana e habilidades
- A barra de mana tem **3 níveis**. Começa a fase com 1.
- Enche acertando golpes (golpe pesado enche mais), apanhando, com o tempo (devagar) e com gemas azuis.
- **Segurar Z** começa a carregar depois de um instante. Cada nível leva 0,4 s. Soltar usa a habilidade do nível alcançado e gasta esse tanto de níveis.
- Nível 1, 2 e 3 = habilidade 1, 2 e 3 da classe. A de nível 3 é a **máxima**: o tempo para um instante, a tela escurece e o nome atravessa a tela. A **suprema** agora é a Fúria (abaixo).
- As habilidades 2 e 3 liberam quando o personagem chega ao nível 2 e 3.
- Levar dano cancela a carga. Dá para sair da carga com a esquiva.

## Inimigos reagem
- **Atordoado:** golpe leve empurra e interrompe.
- **Lançado:** golpes com lançamento jogam o inimigo para o ar. No ar ele pode ser golpeado de novo (cada golpe levanta um pouco menos, para o combo não ser infinito).
- **Cravado:** o 3º golpe aéreo e o mergulho jogam para baixo; o inimigo quica no chão.
- **Caído:** fica um instante no chão (dano reduzido, pode ser relançado uma vez) e levanta com um momento de invulnerabilidade.
- **Chefes** têm super armadura: não são lançados. Em vez disso têm **postura** (abaixo).
- **Pelas costas:** +25% de dano. **Crítico:** 12% de chance, dano ×1,5.
- Só machucam ao encostar os inimigos que atacam com o corpo (Lodo no pulo, Morcego, chefe). Os espectros só ferem com o golpe.

## Combo
- Contador na tela com barra de tempo (2,5 s para continuar).
- Ranks: 10 BOM · 25 ÓTIMO · 45 BRUTAL · 70 IMPLACÁVEL · 100 LENDÁRIO.
- Combo alto rende mais experiência por inimigo (até +40%).

## Fúria (v0.7) #furia
- Barra em losango ao lado das habilidades. Enche batendo (golpe pesado enche mais; habilidade enche pouco), apanhando e defendendo. Cerca de 60 a 70 golpes para encher.
- Cheia, a tecla **A** solta a **habilidade suprema**: corte de cena com o herói de perto e o nome do golpe, o tempo para, e um golpe acerta e lança tudo que está na tela (55 de dano base, gasta muita postura do chefe).
- Depois o herói fica **desperto por 10 s**: +30% de dano, +15% de velocidade, mana enchendo 4 vezes mais rápido, aura de chamas e rastro colorido. A barra vai esvaziando e mostra os segundos.
- Nome e cor por classe: Kael **Juramento da Rosácea** (dourado), Lyra **Olho da Tempestade** (verde), Oren **Eclipse Arcano** (violeta). O golpe em si é igual para os três por enquanto. #pendente dar um golpe próprio para cada um.

## Defesa do Kael (v0.7)
- Segurar **↓** no chão levanta o escudo. Só defende golpes que vêm da frente.
- **Defesa comum:** leva 20% do dano, não é interrompido, nunca morre defendendo (fica com 1 de vida).
- **Defesa perfeita:** se o golpe chega até 10 passos (0,17 s) depois de levantar o escudo, não leva dano, o inimigo comum fica atordoado, o chefe perde 30 de postura, e ganha mana e Fúria.
- Depois da defesa perfeita, **Z** em até 0,75 s solta o **contra-ataque**: golpe forte que lança (34 de dano, 3 vezes mais dano de postura).
- ↓ + Z continua sendo o lançador quando não há contra-ataque disponível.

## Teleporte do Oren (v0.7)
No lugar da esquiva, C faz o Oren sumir e reaparecer cerca de 80 px à frente, atravessando inimigos (não atravessa as barreiras da fase). Funciona no ar. Recarga um pouco maior que a esquiva.

## Postura do chefe (v0.7)
- Barra amarela fina embaixo da vida do chefe (100 pontos). Golpe leve tira 2,2; pesado tira 7; contra-ataque e Fúria tiram mais. Recupera devagar.
- Em zero: **POSTURA QUEBRADA**. O chefe fica atordoado 3,5 s, não machuca ao encostar e leva +40% de dano.

## Pendente #pendente
Golpe de Fúria próprio por classe, agarrão, elementos e estados. Ver [[Análise Completa do Jogo]].
