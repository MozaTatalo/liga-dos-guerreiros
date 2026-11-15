---
tags: [arte, planejamento, cenario, inimigo, interface, pedido]
criado: 2026-11-15
---
# Plano de Acabamento Visual (tirar a cara de protótipo)

**Pedido do Italo (2026-11-15):** o jogo está caminhando, mas ainda tem cara de protótipo: "quadradão", amador, efeitos fracos. Quer entender como os jogos do gênero (Grand Chase, Elsword) chegam naquele visual, só como inspiração. Não usamos arquivos nem arte de outros jogos: os arquivos do Grand Chase vêm empacotados e a arte é deles. Referência boa = prints e vídeos de gameplay que o Italo mandar.

## 1. Diagnóstico: por que parece protótipo
Olhando capturas da v0.8.1 lado a lado:

1. **Tudo é forma pronta montada em código.** Altar é uma caixa, mãos do espectro são cubos, morcego são duas bolas, paredes são planos enormes com tijolo repetido. É isso que o olho lê como "quadrado".
2. **Luz chapada e uma cor só.** Quase tudo é roxo-azulado na mesma intensidade. Falta sombra de contato, oclusão nos cantos, luz quente contra fria e partes realmente escuras para o herói se destacar.
3. **Escala.** O herói ocupa cerca de 13% da altura da tela. Nos jogos do gênero fica entre 18% e 25%. A tela parece grande e vazia e os personagens viram detalhe.
4. **Chão sem corpo.** O chão é um plano fino; plataformas são caixas. Nos jogos do gênero o chão é uma faixa grossa com borda trabalhada (pedra quebrada, raízes, musgo) e a parte da frente aparece.
5. **Silhuetas retas.** Nada quebra as linhas: sem entulho, sem estátuas partidas, sem pedras soltas, sem vegetação pendurada.
6. **Inimigos sem animação de verdade.** São peças rígidas girando por código. Não têm esqueleto, nem poses exageradas de antecipação e golpe.
7. **Efeitos geométricos.** Arcos e bolas desenhados por código, sem textura pintada (fumaça, faísca, fogo com forma).
8. **Interface em cima do jogo.** A barra de teclas fica sobre o chão, várias caixinhas soltas, molduras sem unidade.

## 2. Como os jogos do gênero chegam lá
- **Fundos pintados em camadas** (longe, meio, perto, frente) com parallax. A luz está "pintada" no próprio fundo.
- **Chão como faixa decorada** com borda grossa, e plataformas com forma própria (não retângulos).
- **Modelos com poucos polígonos mas silhueta trabalhada** e textura pintada à mão (a sombra e o brilho já vêm na textura).
- **Animação feita à mão (keyframe)** com antecipação forte, pose de impacto segurada e recuperação.
- **Efeitos em sprites pintados** (sequências de quadros) somados a malhas com textura de energia.
- **Interface agrupada nos cantos** com molduras ornamentadas de um mesmo estilo.

## 3. O caminho novo (pipeline)
| Área | Antes | Agora |
|---|---|---|
| Cenário | Formas 3D simples feitas em código, luz em tempo real | Modelado no **Blender** com detalhe de verdade, renderizado com luz realista (oclusão, névoa, raios de luz) em **camadas por profundidade** que viram fundos com parallax. O chão jogável é uma malha de verdade com borda. Opcional: **Fooocus** no PC do Italo repinta as camadas para dar cara de pintura à mão. |
| Inimigos | Peças primitivas giradas por código | Modelados no Blender como **uma malha contínua com esqueleto**, animações feitas à mão (parado, flutuar, preparo, golpe, dano, morte) exportadas em glTF. Mesmo shader anime do jogo. |
| Heróis | Corpo base aprovado (não muda) | Fase posterior: armadura, capa e armas modeladas no Blender como camadas de equipamento. Corpo, rosto e macacão continuam intocados. |
| Efeitos | Desenho por código (v0.8.1) | Somar **sequências de quadros renderizadas** (fumaça, fogo, faísca, cortes) ao sistema atual. |
| Interface | Peças soltas | Molduras de um estilo só, tutorial fora da área de jogo. |
| Câmera | Herói pequeno | Decisão do Italo: aproximar a câmera para os personagens ficarem maiores. #pendente |

O Blender roda direto na nuvem (versão 5.3 como módulo Python), então os modelos e renders são feitos sem depender do PC.

## 4. Etapas
1. **Prova (agora):** a nave da catedral (início da Fase 1) refeita no pipeline novo e o **Espectro** refeito com esqueleto e animações. Comparação antes e depois no mesmo lugar do jogo.
2. Fase 1 inteira no pipeline novo, com os outros inimigos (Lodo, Morcego, Conjurador) e o chefe refeitos.
3. Interface e menus repaginados.
4. Efeitos em sequência de quadros.
5. Equipamentos dos heróis (armadura, capa, armas melhores).
6. Próximas fases do mundo 1 (Cripta dos Sussurros, Floresta Morta, Torre do Relógio, Catedral Afundada).

## 5. Referências
O Italo pode mandar prints ou vídeos de gameplay que curte (Grand Chase, Elsword ou outros). Analisamos proporção, cor, camadas, efeitos e interface. Só como pegada, nada copiado.

Ver também: [[Direção de Arte]] · [[Arte e Animação no Jogo]] · [[Pesquisa - Arte e Animação]] · [[Roteiro de Versões]]
