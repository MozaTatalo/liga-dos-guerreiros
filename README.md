# Liga dos Guerreiros

Jogo de ação e plataforma 2D com rolagem lateral, para PC, com personagens em 2.5D (modelos 3D em cel shading num plano lateral) e tom gótico. Cada personagem tem classe, arma, golpes e habilidades próprias, e as fases têm inimigos variados, começo e fim claros. Começa com um jogador, já pensado para multijogador.

Todos os personagens, nomes e artes são originais.

## Pastas

| Pasta | O que tem |
|---|---|
| `Godot/` | Projeto do jogo em Godot 4 (classes, combos, habilidades, inimigos, chefe, fase 1) |
| `Prototipo/` | Protótipo v0.1 jogável no navegador |
| `Testes/2.5D/` | Testes de arte 2.5D: vitrine do Kael, arena gótica e comparações de estilo |
| `Obsidian/` | Cofre do Obsidian com todas as especificações, decisões e o registro de mudanças |

## Como abrir o projeto Godot

1. Instale o **Godot 4.5** (versão padrão, não a .NET): https://godotengine.org/download
2. No Godot, clique em **Importar** e escolha `Godot/project.godot`.
3. Aperte **F5** para jogar.

Controles e organização do código estão em [`Godot/LEIA-ME.md`](Godot/LEIA-ME.md).

## Como abrir as páginas de teste

Basta abrir os arquivos `.html` no navegador (Chrome ou Edge), sem instalar nada:

- `Prototipo/index.html`: protótipo jogável (Kael, Lyra, Oren e o chefe).
- `Testes/2.5D/kael.html`: vitrine do Kael (girar, trocar equipamentos, mostrar ou esconder o cabelo).
- `Testes/2.5D/arena.html`: arena gótica com o Kael jogável.
- `Testes/2.5D/index.html` e `Testes/2.5D/gotico.html`: testes anteriores de estilo.

O modelo do Kael fica em `Testes/2.5D/src/kael.js`. As páginas `kael.html` e `arena.html` são montadas colando esse arquivo no lugar de `/*KAEL_LIB*/` em `src/vitrine.html` e `src/arena.html`.

## Cofre do Obsidian

No Obsidian, use **Abrir pasta como cofre** e escolha a pasta `Obsidian/`. Comece pela nota `00 - Início`. Toda mudança e todo pedido ficam registrados em `Registro/`.
