---
tags: [arte, personagem, modelo-base, revisao, pendente]
atualizado: 2026-11-13
---
# Revisão do Modelo Base

Pedido do Italo (2026-11-13): olhar o modelo como um todo e apontar o que melhorar, lembrando que **todos os personagens derivam da mesma base**. Haverá **um corpo masculino e um corpo feminino**. Todos os homens usam o mesmo corpo e todas as mulheres o mesmo corpo. Entre personagens mudam cor e poucos detalhes.

Revisão feita sobre o Kael rascunho 14 (`Testes\2.5D\src\kael.js`). **Escolha do Italo (2026-11-13):** itens 5, 6, 7, 8 e 10 desta nota (mãos, pés, juntas, sombra e contorno, cabelo) feitos no rascunho 15. Depois ele preferiu **voltar mãos e pés (itens 5 e 6) ao formato simples anterior** (rascunho 16). Item 9 (macacão) **descartado**: o macacão fica liso de propósito, é o modelo "nu". Os demais seguem em aberto. #pendente

## Estrutura (o que vale para todos os personagens)
1. **Separar "corpo base" de "personagem".** Hoje tudo está numa função só, escrita para o Kael. Proposta: um corpo base (masculino e feminino) e uma ficha por personagem com cabelo, rosto, paleta e arma de madeira. Criar Lyra, Oren e Brann vira preencher uma ficha.
2. **Corpo feminino.** Mesmo esqueleto e mesmas animações do masculino, mudando só a silhueta do tronco: ombros mais estreitos, cintura mais marcada, quadril um pouco mais largo, mãos e pés um pouco menores. Mesmo macacão liso, discreto.
3. **Caminho até o Godot.** O modelo é montado em código no navegador. Para o jogo ele precisa virar um arquivo 3D com esqueleto (glTF). Dá para exportar daqui e testar numa cópia do projeto Godot, sem mexer no jogo atual.
4. **Lista final de espaços de equipamento.** Hoje: armadura, manto, arma, escudo. Faltam decidir capacete, luvas, botas e acessório.

## Visual
5. **Mãos.** São bolas com um polegar. Faltam dedos (pelo menos em bloco, estilo luva) e um punho que segure a arma de verdade.
6. **Pés e tornozelos.** O pé é uma bolha e a canela alarga até ele. Falta tornozelo, calcanhar e peito do pé.
7. **Juntas.** Cotovelos e joelhos mostram a emenda entre os cilindros, com linha de contorno no meio do braço. Há também uma mancha marrom no antebraço do escudo (a alça do escudo atravessando o braço).
8. **Sombreado e contorno.** A pele estoura para o branco e quase não tem sombra. Falta sombra do cabelo na testa, do queixo no pescoço e do macacão. O contorno é grosso no corpo e fino na cabeça.
9. **Macacão.** Está liso demais até para um base: sem costura, sem barra na manga e no short, sem volume de tecido. Dois ou três detalhes discretos resolvem sem perder o ar de manequim.
10. **Cabelo.** A franja ainda é reta, tipo capacete, e a parte de trás é uma cortina lisa. Mais camadas e pontas soltas dariam vida. O cabelo também deveria balançar ao correr.

## Animação e expressão
11. **Animações que faltam:** pulo, queda, levar dano, defender com o escudo, técnica especial e derrota. As atuais (parado, correr, combo) estão um pouco duras.
12. **Expressões:** hoje só pisca. Trocar boca e sobrancelhas (bravo, dor, sorriso) pela mesma técnica de trocar a pintura do rosto.

## Ordem recomendada
Primeiro 5, 6, 7 e 8 (acabamento do corpo, porque todo personagem herda). Depois 1 e 2 (corpo base e versão feminina). Depois 3 (teste no Godot). O resto entra conforme cada personagem for criado.

Ver também: [[Kael - Guardião]] · [[Equipamentos]] · [[Personagens em 2.5D]] · [[Direção de Arte]]
