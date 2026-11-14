---
tags: [arte, animacao, pesquisa, tecnologia, godot, combate]
atualizado: 2026-11-14
---
# Pesquisa: como deixar o jogo lindo e fluido

Pesquisa feita na internet em 2026-11-14, a pedido do Italo ([[Pedidos do Italo]]), em quatro frentes: sombreamento anime dos personagens, animação de ação, efeitos e sensação de impacto, e cenário, luz e imagem final. O que já virou jogo está em [[Arte e Animação no Jogo]].

**Como ler:** *(fonte)* quer dizer que o dado veio de uma fonte lida. *(sugestão)* é um valor de partida nosso, para ajustar no olho. A lista de fontes fica no fim.

**Limite técnico que guia tudo:** o jogo roda no renderizador **Compatibility** do Godot 4.5 (o único que funciona no navegador). Ele tem brilho (glow), névoa, ajuste de cor e MSAA no 3D, mas **não** tem HDR de verdade, oclusão de ambiente, reflexos, névoa volumétrica, desfoque de profundidade nem decalques. Por isso quase todo o visual é feito nos nossos próprios shaders.

---

## 1. Personagens: sombreamento anime #arte

O que os jogos de referência técnica fazem (Guilty Gear Xrd, da Arc System Works, é a principal fonte pública) e o que cabe no nosso boneco, que é feito de peças de cor lisa.

| # | Técnica | Por quê | Custo |
|---|---|---|---|
| 1 | **Sombra tingida, não escurecida.** A parte na sombra é a cor base multiplicada por uma cor de tinta *(fonte: Xrd)*. Partida *(sugestão)*: puxar 10 a 20 graus para o violeta, saturação +10 a 20%, valor x0,6 a 0,75; pele puxando para o vermelho-violeta. | Sombra cinza deixa o boneco sujo e chapado. Sombra colorida é o que dá cara de anime. | Mínimo |
| 2 | **Faixa de sombra suave e nítida.** Trocar o corte seco por uma transição de 1 pixel (`smoothstep` com `fwidth`). | O corte seco serrilha quando o boneco está pequeno. | Mínimo |
| 3 | **Contorno tingido e de largura constante.** Linha na cor da peça, escurecida, em vez de preto puro; largura controlada em pixels *(fonte: ASW "Toon Line Control" e recriações)*. | Preto puro pesa e "suja" o personagem pequeno. | Baixo |
| 4 | **Luz de contorno pela silhueta.** Em vez de brilho de borda por ângulo (que acende partes internas), usar a própria silhueta do boneco *(fonte: Colorful Palette)*. Fazemos no sprite 2D: borda acesa só do lado da lua, na cor da luz do cenário. | Destaca o herói do fundo escuro e amarra o boneco à luz da fase. | Baixo |
| 5 | **Rosto com menos sombra.** Jogos anime editam as normais do rosto ou reduzem o sombreado nele *(fonte: Xrd, Honkai 3rd)*. | Sombra dura no rosto estraga a expressão. | Baixo |
| 6 | **Brilho em degrau no cabelo** ("anel de anjo"): faixa de luz que fica parada vista da câmera *(fonte: Unity Toon Shader)*. | Dá volume e acabamento ao cabelo. | Baixo |
| 7 | **Luz própria do personagem.** No Xrd cada lutador tem a sua direção de luz, fixa, e a fase só muda a **cor** *(fonte)*. | O boneco fica sempre bem iluminado; a integração vem pela cor. | Já temos |
| 8 | Animação "limitada" (poses seguradas, sem interpolar) *(fonte: Xrd)*. | Cara de desenho feito à mão. | Ver seção 2 |

Descartado: contorno por detecção de bordas na tela (o Compatibility não tem o buffer de normais).

**Armadilha conhecida:** o boneco é renderizado numa janela transparente e depois desenhado como sprite. A borda sai pré-multiplicada e cria uma franja escura. Correção: desenhar o sprite no modo de mistura pré-multiplicado *(fonte: fórum do Godot)*.

---

## 2. Animação de ação #animacao #combate

### Golpes: poses com tempo marcado
Só "perseguir" a pose alvo com suavização não segura a pose de contato, não antecipa e não passa do ponto. Cada golpe precisa de fases:

| Fase | Golpe leve (combo 1 a 3) | Finalizador ou lançador |
|---|---|---|
| Antecipação | 2 a 3 quadros, recuando 10 a 20% do arco | 6 a 10 quadros |
| Golpe até o contato | 2 a 3 quadros, com borrão (smear) | 3 a 4 quadros |
| Contato | só o hitstop | 2 a 3 quadros + hitstop |
| Passagem (passa do ponto e assenta) | 10 a 15% além, 4 a 6 quadros | 15 a 25%, 8 a 10 quadros |
| Recuperação | 8 a 12 quadros | 16 a 24 quadros |

*(tempos: sugestão; princípios: fonte)*

- Um quadro de antecipação já melhora a leitura, e um quadro passando do alvo e voltando dá força *(fonte: Mariel Cartwright, Skullgirls)*.
- Um soco que chega em 2 quadros parece mais forte que um em 5. "Entra rápido, sai devagar" *(fonte: Game Developer)*.
- O golpe em si não passa de 6 quadros *(fonte: Aztez)*.
- **Ação sobreposta:** quadril e tronco giram primeiro, ombro um quadro depois, cotovelo e pulso depois, cabeça por último. Cabelo e arma atrasam.
- Silhueta e linha de ação valem mais que os quadros intermediários.
- O herói quase não antecipa (resposta imediata); o **inimigo** antecipa bastante para dar tempo de reagir. A reação humana é de uns 16 quadros *(fonte: infil)*, então inimigo comum avisa 24 a 36 quadros e chefe 45 a 70 *(sugestão)*.

### Molas (dinâmica de segunda ordem)
Cada junta segue o alvo com uma mola: frequência (rapidez) e amortecimento (quanto passa do ponto). É o que dá passagem e assentamento de graça *(fonte: t3ssel8r, Daniel Holden)*. Amortecimento 0,7 passa 5% do alvo; 0,6 passa 9%; 0,5 passa 16%.

| Parte | Frequência | Amortecimento |
|---|---|---|
| Braços e arma | 4 a 6 Hz | 0,5 a 0,6 |
| Tronco | 3 a 4 Hz | 0,8 a 1,0 |
| Cabeça | 2,5 a 3,5 Hz | 0,6 |
| Cabelo e capa | 1,5 a 3 Hz | 0,3 a 0,5 |
| Amassar e esticar | 4 a 5 Hz | 0,35 a 0,5 |

### Amassar e esticar (squash e stretch)
Sempre conservando o volume, com o pivô nos pés. É **animação**, não muda a proporção aprovada do corpo. Partida *(sugestão)*: saída do pulo estica 15 a 25% por 3 a 4 quadros; pouso amassa 15 a 25% por 2 a 3 quadros e volta com mola; esquiva estica 15% na direção; inimigo atingido amassa 15% por 2 quadros.

### Corrida, pulo e parado
- Corrida: poses de contato, baixo, impulso e pico *(fonte: AnimSchool)*. Corpo inclinado 12 a 20 graus, braços em contra-balanço, tronco torcendo contra o quadril, sobe e desce duas vezes por ciclo.
- Pulo: estica na saída, encolhe no ápice, braços sobem na queda, amassa no pouso.
- Parado: respiração lenta, troca de peso, piscar a cada 2 a 6 segundos.
- Expressão troca na antecipação do golpe e na dor.

### Hitstop (a pausa no impacto)
- Quem bate e quem apanha param pelo mesmo tempo; golpe forte para mais; existe um teto *(fonte: Sakurai)*.
- O alvo **treme** durante a pausa, forte no começo e sumindo; de lado no chão, para cima e para baixo no ar *(fonte: Sakurai)*.
- Em jogo com muitos inimigos a pausa é curta *(fonte: Sakurai)*. Partida *(sugestão)*: toque de golpe múltiplo 1 a 2 quadros, leve 2 a 3, médio 4 a 6, pesado 7 a 10, finalizador ou morte de chefe 12 a 18.

---

## 3. Efeitos e sensação de impacto #combate

| # | Técnica | Detalhe |
|---|---|---|
| 1 | **Tremor de tela por "trauma"** *(fonte: Squirrel Eiserloh, GDC)* | Cada evento soma trauma (0 a 1); o tremor é o trauma ao quadrado vezes ruído suave, e decai sozinho. Partida *(sugestão)* para a nossa tela: no máximo 6 x 4 px; leve 0,15, médio 0,3, pesado 0,5, finalizador 0,8. Mais um empurrão de 2 a 4 px na direção do golpe. |
| 2 | **Faísca de impacto em 3 camadas** | Clarão quase branco por 1 a 2 quadros; 4 a 8 riscos na direção do golpe; anel ou estrela que abre afinando. |
| 3 | **Ritmo dos efeitos** *(fonte: Riot, VFX Apprentice)* | Antecipação, clímax, dissipação. Corte normal: clímax de 2 a 3 quadros e 5 a 8 para sumir **afinando ou corroendo**, não só ficando transparente. Efeito de golpe básico nunca pode parecer suprema. |
| 4 | **Cor** *(fonte: Riot, RealTimeVFX)* | Miolo claro, borda mais escura e saturada. Uma cor dominante por efeito e no máximo um acento. Fundo escuro e dessaturado é o que faz o efeito brilhar. |
| 5 | **Cara de 2D** *(fonte: Arc System Works)* | Efeitos animados "em degraus" (seguram 2 a 3 quadros) enquanto o jogo roda a 60. |
| 6 | **Câmera** *(sugestão)* | Aproximação rápida de 3 a 6% nos golpes pesados; câmera lenta no último inimigo. |
| 7 | **Números de dano** | Nascem grandes e encolhem, sobem em arco; crítico maior e de outra cor. |
| 8 | **Poeira** | 3 a 6 nuvens ao pousar, esquivar e virar. |
| 9 | **Rastro da arma** | Fita de luz que segue a ponta da arma de verdade e some em 4 a 6 quadros. |

Cuidados: clarão de tela cheia só em finalizadores (fotossensibilidade); manter a opção de desligar o tremor.

---

## 4. Cenário, luz e imagem final #mapa #arte

**O que mais pesa, quase de graça:**
1. **Hierarquia de valor.** O plano do jogo (heróis, inimigos, golpes) tem o maior contraste e brilho; o fundo fica numa faixa comprimida e menos saturada *(fonte: Hollow Knight, Dead Cells)*. Teste: a captura em preto e branco ainda tem que destacar os personagens e a borda das plataformas.
2. **Plataformas legíveis:** borda de cima iluminada pela lua, lateral escura *(fonte: Hollow Knight)*.
3. **Perspectiva atmosférica:** quanto mais longe, mais a cor se mistura com a névoa azul-violeta. Partida *(sugestão)*: plano do jogo 0%, fundo próximo 15 a 25%, meio 35 a 50%, longe 60 a 75%, horizonte 80 a 90%.
4. **Roteiro de cor:** cerca de 65% frio (azul-violeta), 25% pedra neutra, 10% ou menos de laranja quente (braseiros, vitrais), nos pontos de foco *(princípio: fonte Dead Cells)*.
5. **Moldura de primeiro plano** em silhueta quase preta, sem cobrir o centro da tela *(fonte: Hollow Knight)*.

**Com pouco custo:**
6. Sombra no chão sob cada personagem e poça de luz quente perto dos braseiros.
7. **Raios de luz falsos:** cartões aditivos com ruído rolando devagar, sumindo antes do chão *(fonte: godotshaders)*.
8. **Fogo tremulando** com ruído em camadas (lento de 1,5 a 3 Hz mais rápido de 8 a 12 Hz), nunca um seno só; a mesma curva comanda a chama, a poça de luz e a luz no herói.
9. **Vida no fundo:** estandartes, correntes balançando, poeira nos raios, brasas, cinzas, pássaros ao longe. Tudo em baixo contraste para não competir com os personagens.

**Imagem final:**
10. Brilho (glow) só no 3D, com limiar abaixo de 1; vitrais, chamas e lua são os únicos elementos perto do branco.
11. Um único passe de cor por cima de tudo: vinheta, sombras frias e luzes quentes. É o único jeito de dar o mesmo tratamento ao fundo e aos personagens.
12. Evitar: aberração cromática, nitidez artificial e vários passes de tela (caros no navegador).

**Desempenho no navegador:** juntar malhas estáticas, poucas camadas transparentes grandes (névoa e raios são o maior risco), no máximo 3 leituras de textura por pixel nos shaders do cenário.

---

## Não foi possível verificar
- Dados de quadros de Grand Chase e Elsword (não há fonte pública confiável).
- Detalhes de Genshin, Star Rail e Zenless vêm de recriações da comunidade, não dos estúdios.
- Brilho (glow) em elementos 2D no Compatibility existe, mas tem relatos de defeitos; por isso os golpes usam brilho feito no próprio desenho.

## Fontes principais
**Sombreamento:** [Guilty Gear Xrd, GDC 2015 (Junya Motomura)](https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf) · [ASW Toon Line Control](https://www.docswell.com/s/ASW_Academy/5LVY67-GG-Toonline-Eng) · [Recriação do shader da ASW](https://github.com/Aerthas/UNITY-Arc-system-Works-Shader) · [Honkai 3rd, Unite Tokyo 2018](https://www.docswell.com/s/UnityJapan/KWLQP5-unite-tokyo-20183rd) · [Colorful Palette, luz de contorno](https://media.colorfulpalette.co.jp/n/na124e7072200) · [Unity Toon Shader, Angel Ring](https://docs.unity3d.com/Packages/com.unity.toonshader@0.13/manual/AngelRing.html) · [Hi-Fi Rush](https://80.lv/articles/the-making-of-hi-fi-rush-s-3d-toon-rendering-style) · [Contorno no Godot](https://godotshaders.com/shader/pixel-perfect-outline-shader/) · [Renderizadores do Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html)

**Animação:** [Fluid and Powerful Animation (Cartwright)](https://gdcvault.com/play/1020575/Animation-Bootcamp-Fluid-and-Powerful) · [Resumo no 80.lv](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations) · [12 princípios da animação em jogos](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games) · [Aztez, anatomia de um golpe](https://aztez.com/blog/2014/01/06/anatomy-of-a-successful-attack/) · [Molas (Daniel Holden)](https://theorangeduck.com/page/spring-roll-call) · [t3ssel8r, animação procedural com matemática](https://www.youtube.com/watch?v=KPoeNZZ6H4s) · [Sakurai sobre hitstop](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/) · [Tempo de reação (infil)](https://ki.infil.net/reaction.html) · [Ciclo de corrida (AnimSchool)](https://blog.animschool.edu/?p=634) · [Cancelamentos em God of War](https://www.gamedeveloper.com/game-platforms/combat-canceled-i-god-of-war-i-action-game-design)

**Efeitos e impacto:** [Juicing Your Cameras With Math (Eiserloh, GDC)](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing) · [Guia de estilo de VFX da Riot](https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/) · [VFX Apprentice, tempo nos efeitos](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx) · [RealTimeVFX, cor](https://realtimevfx.com/t/diving-into-color-tips-tricks-i-use-for-using-color/16220) · [Hitstop em jogos de luta](https://sonichurricane.com/?p=1043) · [Art of Screenshake, resumo](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects) · [Glow no Compatibility (PR 87360)](https://github.com/godotengine/godot/pull/87360)

**Cenário e luz:** [A arte de Hollow Knight](https://medium.com/3d-environmental-art/the-art-of-hollow-knight-f4c05dda3882) · [Cores de Dead Cells](https://gamedeveloper.com/production/art-design-deep-dive-giving-back-colors-to-cryptic-worlds-in-i-dead-cells-i-) · [Reduzir confusão visual](https://gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game) · [Lunarium, 2D pintado com 3D](https://80.lv/articles/how-lunarium-blends-hand-painted-2d-art-with-3d-environments) · [Guilty Gear Strive, visual](https://www.unrealengine.com/en-US/developer-interviews/how-guilty-gear--strive--hits-an-ultra-combo-with-groundbreaking-visuals-and-gameplay) · [Raios de luz falsos](https://godotshaders.com/shader/fake-godrays-godot-4-2/) · [Paralaxe (Slynyrd)](https://www.slynyrd.com/blog/2019/11/12/pixelblog-23-parallax-scrolling) · [Ambiente e pós-processamento no Godot](https://docs.godotengine.org/en/4.5/tutorials/3d/environment_and_post_processing.html)
