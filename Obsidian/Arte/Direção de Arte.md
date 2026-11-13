---
tags: [arte, decisao, personagem]
atualizado: 2026-11-13
---
# Direção de Arte

**Decidido pelo Italo (2026-11-13):** personagens em **3D em tempo real** (caminho A de [[Personagens em 2.5D]]) com uma pegada **gótica, séria e bonita**. O primeiro teste estava "infantilizado e quadrado", então nada de bonecos de blocos, cabeças grandes ou cores de desenho infantil.

## Pilares
- **Tom:** fantasia sombria gótica. Sério, melancólico, elegante. Sem humor visual, sem formas fofas.
- **Proporções:** adultas e esguias, cerca de 7,5 a 8 cabeças de altura. Silhueta forte e legível de lado.
- **Formas:** curvas e pontas (arcos ogivais, lâminas longas, capas rasgadas). Evitar caixas e ângulos retos.
- **Materiais:** aço escurecido com frisos em prata ou ouro velho, couro, tecido pesado. Detalhe fino nas bordas.
- **Cores:** base escura e dessaturada (azul-noite, cinza-ardósia, preto) com **um** acento forte por personagem (carmesim no Kael).
- **Luz:** noite e crepúsculo. Lua fria por trás recortando a silhueta, fogo quente de braseiros e velas como contraste, névoa baixa.
- **Cenários:** ruínas de catedral, arcadas, vitrais, cemitérios, árvores mortas, torres ao longe.
- **Acabamento:** cel shading com 4 tons e contorno fino escuro. Brilhos pontuais (olhos de inimigos, runas da lâmina, chamas).
- **Inimigos:** espectros encapuzados, armaduras vazias, gárgulas. O [[Bestiário]] atual (golem etc.) precisa ser revisto nesse tom. #pendente

## Kael, o Guardião (rascunho 2)
Cavaleiro de armadura de placas escura com frisos, cabelo claro comprido, capa carmesim rasgada, espada longa com brilho frio no sulco e escudo em gota com emblema. Três paletas no teste: **Aço negro e carmesim**, **Prata e azul-noite**, **Bronze e osso**. Paleta final: aguardando Italo. #pendente

**Teste jogável:** `Testes\2.5D\gotico.html` ou https://claude.ai/artifact/AgwgyzWsgdr5rCHazXsa46 (1, 2, 3 trocam a paleta, V aproxima, C gira a câmera). As formas são montadas em código, então o rosto e os detalhes são simples. O modelo final será esculpido.

## Como chegar ao modelo final
1. Arte conceitual do personagem em pose neutra (frente e lado), no tom acima.
2. Gerar o modelo 3D a partir do conceito (Meshy, Tripo, Rodin ou Hunyuan3D local) e limpar no Blender.
3. Esqueleto (Mixamo ou AccuRig) e animações: parado, correr, pular, cair, 3 golpes, 3 habilidades, dano, morte.
4. Importar no Godot numa cópia de teste do projeto, com o mesmo shader de cel shading e contorno.

### Prompt base para o conceito (inglês, para geradores de imagem)
`full body character concept art, gothic dark fantasy knight guardian, tall slender adult proportions, blackened steel plate armor with silver filigree trim, long ashen white hair, tattered crimson cape, longsword and kite shield, serious melancholic expression, T-pose, front view and side view turnaround, plain grey background, clean cel shaded anime style, sharp linework, muted desaturated palette with crimson accent`

Ver também: [[Kael - Guardião]] · [[Pipeline de Arte]] · [[Fase 1 - Ruínas de Arvália]]

## Referência de pegada (2026-11-13)
O Italo gostou do Kael mais humanoide e mandou uma captura de tela de um jogo de ação lateral do gênero como referência de **pegada**. Usamos só a sensação e a legibilidade, nada é copiado (personagens, arte e interface continuam originais). O que tiramos dela:
- **Personagem estilo anime de ação:** cabeça um pouco maior (cerca de 5,5 cabeças de altura), cabelo com silhueta marcante, arma grande, contorno grosso.
- **Fase em andares:** vários níveis de plataforma empilhados na mesma tela, com descida por baixo (↓ + pulo).
- **Cenário rico em camadas e cor:** vegetação, cascatas luminosas, musgo, muita profundidade. No jogo final os fundos serão **pinturas 2D em camadas**, o jeito padrão desse visual.
- **Interface de jogo:** retrato/brasão, barras de vida e mana, técnicas com tecla e recarga, cronômetro da fase, contador de golpes, barra de vida nos inimigos.

Leitura atual: **combinar** essa pegada anime de ação com o tom gótico e sério, não trocar um pelo outro. Aguardando o Italo confirmar. #pendente

**Teste jogável (rascunho 3):** `Testes\2.5D\arena.html` ou https://claude.ai/artifact/LboBuz7rpNM4qau1n2QAFC. Novidades: três andares de plataformas com musgo, cascatas, folhagem, vaga-lumes, interface completa e a técnica **Investida** (tecla A, 25 MP, recarga de 3 s).

## Kael rascunho 4 (2026-11-13)
Identidade visual detalhada em [[Kael - Guardião]]. A rosácea de oito pontas passa a ser o emblema da Ordem e pode se repetir em cenários e interface.

## Proporção dos personagens (2026-11-13)
Decisão do Italo: personagens pequenos, cerca de 3 cabeças de altura, cabeça grande, mãos e pés grandes. Substitui a proporção adulta e esguia dos pilares acima. O tom gótico e sério continua, agora vindo do figurino, das cores e da expressão. Detalhes em [[Kael - Guardião]].
