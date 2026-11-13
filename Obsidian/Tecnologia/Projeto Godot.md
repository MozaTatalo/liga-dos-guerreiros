---
tags: [tecnologia, godot, multijogador]
versao: 0.2
---
# Projeto Godot

- **Pasta:** `B:\Antigravity\Liga Dos Guerreiros\Godot` (abrir `project.godot` no Godot 4.5, F5 para jogar)
- **Versão:** 0.2 (2026-11-13), migração completa do [[Protótipo]] HTML5
- **Conteúdo:** [[Kael - Guardião]], [[Lyra - Caçadora]], [[Oren - Arcanista]] · [[Fase 1 - Ruínas de Arvália]] · [[Bestiário]] · controles em [[Combate]]
- **Resolução:** 480×270 ampliada (pixel art nítida), janela 1440×810, 60 passos fixos por segundo.

## Scripts
- `game_data.gd`: todos os números (classes, habilidades, inimigos, fase). Balanceamento é aqui.
- `hero.gd`: personagem, combo e habilidades. `enemy.gd`: inimigos e chefe.
- `game.gd`: partida, lista de jogadores, golpes, projéteis, câmera, barreiras, portal.
- `player_input.gd`: comandos por jogador (`p1_`, `p2_`...).
- `gfx.gd`: arte provisória em código, será trocada pelos sprites do [[Pipeline de Arte]].

## Multijogador #multijogador
Estrutura pronta: lista de jogadores, IA mira o mais próximo, câmera segue o grupo, entrada separada por jogador. Ver [[Engine e Plataforma]].

## Próximos passos #pendente
- Trocar arte provisória por sprites (PixelLab + Aseprite)
- Cooperativo local para 2 jogadores
- Sons e música
- 4º personagem: [[Brann - Berserker]]
