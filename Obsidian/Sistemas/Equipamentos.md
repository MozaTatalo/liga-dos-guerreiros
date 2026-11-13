---
tags: [sistema, equipamento, personagem, decisao]
atualizado: 2026-11-13
---
# Equipamentos

**Decisão do Italo (2026-11-13):** todo personagem jogável nasce só com o **modelo base**, e tudo o mais é equipamento vestido por cima.

## Modelo base (vale para todos os personagens)
- **Roupa:** apenas um **macacão liso**, de uma cor só, justo, de **manga curta e short**. Sem zíper, emblema, cinto, bolsos, luvas ou botas (ajuste do Italo em 2026-11-13, a partir de uma referência de estilo).
- **Corpo:** braços, pernas, mãos e pés à mostra, com sombreado suave. O base é um manequim limpo, pensado para receber as peças por cima. Luvas, botas e cinto passam a ser equipamento.
- A cor do macacão vem da paleta do personagem.
- **Arma:** a versão básica da arma da classe, de **madeira**. Para o Kael, espada de madeira e escudo de madeira.
- Rosto, cabeça, cabelo e proporções do corpo pertencem ao modelo base e não mudam com equipamento.

## Dois corpos base (2026-11-13)
- **Masculino** e **feminino**, com o mesmo esqueleto e as mesmas animações. Todo personagem usa um dos dois.
- Corpo estreito: ombros quase na largura da cabeça, tronco fino, pernas juntas.
- O feminino muda só a silhueta: ombros um pouco mais estreitos, cintura mais marcada, quadril um pouco mais largo, mãos e pés 10% menores. Mesmo macacão liso.
- **Ajuste de 2026-11-13 (rascunho 19):** o masculino tem ombros para fora, braços afastados e fica parado com as pernas abertas. O feminino tem ombros para dentro, braços junto ao corpo e fica parada com as pernas juntas. A roupa base feminina é um **top sem manga e short**, com a barriga à mostra e busto discreto. O masculino segue de macacão.
- No teste: `Kael.criar()` (masculino) e `Kael.criar({ corpo: "f" })` (feminino).

## Peças de equipamento (camadas separadas)
| Espaço | Exemplo no Kael |
|---|---|
| Armadura | Couraça com a rosácea, ombreiras, escarcelas, manoplas, grevas, tabardo, corrente com gema |
| Manto | Manto de penas de corvo com a capa bordada |
| Arma | Espada rúnica (substitui a espada de madeira) |
| Escudo / mão secundária | Escudo da Ordem (substitui o escudo de madeira) |

O visual completo de armadura do Kael passa a ser **um conjunto equipado**, não o personagem em si.

## Como está no teste
No modelo (`Testes\2.5D\src\kael.js`) cada peça pertence a um espaço e pode ser ligada ou desligada (`Kael.equipar`). Na vitrine há botões por peça. Na arena, a tecla **E** troca entre base e equipado.

## Pendências #pendente
- Definir a lista final de espaços (capacete? acessório? botas e luvas separadas?).
- Macacão e arma de madeira de cada classe: [[Lyra - Caçadora]] (arco de madeira), [[Oren - Arcanista]] (cajado de madeira), [[Brann - Berserker]].
- Como o jogador ganha e troca equipamentos (ver [[Progressão]]).

Ver também: [[Kael - Guardião]] · [[Classes e Armas]] · [[Direção de Arte]]
