---
tags: [interface, sistema]
versao: 0.6
---
# Interface e Menus

Estilo: gótico elegante. Painéis escuros com filete dourado e losangos nos cantos, títulos em fonte serifada (Cinzel), texto em Alegreya Sans. Tudo desenhado por código em `scripts/ui.gd`.

Decisão do Italo (2026-11-14): o lobby é em **menu, com o herói em destaque** (não é cidade andável).

## Fluxo
Título → Lobby → (Personagens | Fases | Golpes | Opções) → Fase → Resultado → Lobby

## Telas
- **Título:** nome do jogo, os três heróis, "Aperte Z para começar".
- **Lobby:** lista à esquerda (Jogar, Personagens, Golpes, Opções; Equipamentos, Habilidades e Loja aparecem como "em breve"), herói escolhido grande num pedestal, nível e experiência dele, ouro no topo.
- **Personagens:** um cartão por herói (o escolhido demonstra os golpes), Brann aparece travado; painel com descrição, atributos em losangos e as 3 habilidades com ícone.
- **Fases:** mapa do reino com as 5 fases do primeiro mundo (só a 1 está pronta), dificuldade, chefe e melhor rank.
- **Golpes:** lista de comandos e as habilidades do herói.
- **Opções:** volume da música e dos efeitos, tremor da tela, tela cheia.
- **Pausa (na fase):** continuar, volumes, tremor, reiniciar, voltar ao lobby, com a lista de golpes ao lado.
- **Resultado:** rank em emblema, tempo, maior combo, dano, inimigos, ouro e experiência subindo, barra de nível.

## HUD da fase
- Retrato do herói ao vivo num losango, com o nível.
- Vida com rastro de dano, mana em 3 níveis (a carga aparece por cima, na cor da habilidade), barra fina de experiência.
- 3 ícones de habilidade embaixo à esquerda, com os níveis de mana que custam.
- Tempo e ouro em cima à direita; contador de combo com rank.
- Progresso da fase no topo; vira a barra do chefe em 3 camadas quando ele aparece.

## Navegação
Setas escolhem, Z ou Enter confirma, C ou Esc volta.

## Pendente #pendente
Mouse nos menus, suporte a controle, remapear teclas, inventário, árvore de habilidades, loja, tutorial.

## Novidades da v0.7
- **Fúria:** losango ao lado das três habilidades, enche de baixo para cima. Cheio, pulsa e mostra a tecla A. Desperto, mostra os segundos que faltam.
- **Corte de cena da Fúria:** faixa inclinada na cor da classe, com o herói de perto (o mesmo boneco 3D, renderizado em resolução maior só nesse momento), riscos de velocidade e o nome do golpe.
- **Apresentação do chefe:** faixas de cinema em cima e embaixo, título e nome no alto, HUD escondida enquanto dura.
- **Postura do chefe:** barra amarela fina embaixo da vida. Mostra "ATORDOADO" quando quebra.
- Lista de golpes e dicas do começo da fase ganharam Fúria, defesa e teleporte.
