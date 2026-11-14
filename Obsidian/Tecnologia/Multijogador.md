---
tags: [multijogador, tecnologia, pendente]
---
# Multijogador (plano)

Pedido do Italo: começar com 1 jogador, mas planejar o multijogador desde o início.

## Etapas
1. **Cooperativo local (2 jogadores no mesmo PC):** segundo jogador no controle ou em outras teclas. A partida já aceita uma lista de classes, por exemplo `[0, 2]`. Falta: ações `p2_*`, HUD do segundo jogador, tela para os dois escolherem.
2. **Cooperativo online até 4:** um jogador é o anfitrião e decide o que acontece (inimigos, dano, itens); os outros mandam só os comandos e recebem o estado. Sala com código para convidar.
3. **Lobby online:** salas, prontidão, líder escolhe fase e dificuldade, chat.
4. **Arena contra jogadores** (1 contra 1 e 2 contra 2), depois do combate equilibrado.

## Regras que o código já segue
- Lógica em passos fixos de 60 por segundo, separada do desenho.
- Cada herói lê comandos de um `PlayerInput`; a rede entra como outra fonte de comandos.
- Inimigos miram o jogador vivo mais próximo; a câmera enquadra o grupo.
- Experiência vai para todos os jogadores vivos; ouro é da partida.

## A decidir mais tarde #decisao
Rede ponto a ponto com anfitrião (mais simples, sem custo) ou servidor dedicado (mais estável, tem custo).
