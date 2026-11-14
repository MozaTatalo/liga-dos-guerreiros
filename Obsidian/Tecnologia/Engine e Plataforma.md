---
tags: [tecnologia, decisao]
---
# Engine e Plataforma

**Decidido (2026-11-13): Godot 4** (gratuito, excelente para 2D e pixel art, exporta para PC, navegador e celular, suporte a multijogador).

Outras opções: Unity (mais pesado para 2D), Phaser (só navegador).

**Protótipo atual:** HTML5 + JavaScript puro no navegador, só para validar sensação de combate, classes e fluxo de fase. A lógica e os números migram para a engine escolhida.

Próximo passo: migrar o protótipo para um projeto Godot 4 em `B:\Antigravity\Liga Dos Guerreiros\Godot`.

**Plataforma:** PC (decidido 2026-11-13).

## Multijogador #multijogador
Começa com 1 jogador, mas a estrutura já nasce preparada para vários jogadores:
- Entrada separada do personagem: cada herói lê os comandos de um "controlador" próprio (teclado, controle ou, no futuro, a rede).
- O jogo trabalha com uma **lista de jogadores**, não com "o jogador": inimigos miram o mais próximo, a câmera enquadra todos.
- A lógica de combate roda em passos fixos de 60 por segundo, o que facilita sincronizar pela rede depois.
- Próximos passos possíveis: cooperativo local (2 jogadores no mesmo PC) e depois online com o sistema de rede do Godot.

Plano completo em [[Multijogador]].
