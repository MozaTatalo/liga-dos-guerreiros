---
tags: [inimigo]
---
# Bestiário

Desde a v0.6 todos os inimigos comuns podem ser **lançados, mantidos no ar, cravados e derrubados** (ver [[Combate]]). Cada um dá experiência e ouro (ver [[Progressão]]). Os espectros não ferem mais só por encostar.

## Lodo #inimigo
Gosma de ectoplasma verde-azulada e translúcida, com olhos e ossinhos boiando dentro; treme e estica ao pular (3D), pula na direção do jogador. Fraco, aparece em grupo.
## Espectro (antigo Saqueador) #inimigo
Aparição de manto rasgado, capuz vazio e olhos azuis, mãos de osso. Flutua até o jogador, ergue os braços (olhos ficam vermelhos) e golpeia. Modelo 3D do teste gótico.

**Versão nova (v0.9, 2026-11-15):** monge caído da catedral, modelado no Blender como uma malha só com esqueleto. Capuz pontudo com aba que esconde uma máscara de osso rachada (só os olhos brilham), mozeta curta, hábito com barra rasgada em tiras e faixa bordada a ouro desbotado, cordão de monge com contas e medalhão partido, mangas largas, antebraços e mãos de osso com garras de ferro, algema quebrada no pulso esquerdo. Animações feitas à mão: **parado** (flutua e respira), **andar** (inclina e a barra arrasta para trás), **preparo** (ergue a garra acima da cabeça, que acende vermelha), **golpe** (rasgo para baixo com avanço), **dor** e **morte** (desmorona e some). Tecla V volta ao modelo antigo para comparar. Ver [[Plano de Acabamento Visual]].
## Morcego de Cinzas #inimigo
Morcego 3D de asas de membrana roxa, olhos vermelhos e brasas caindo das asas. Voador, persegue em ondas. Pouca vida, atrapalha combos.
## Espectro Conjurador (antigo Atirador) #inimigo
Espectro de manto roxo e olhos violeta. Mantém distância em cima das plataformas e dispara projéteis. Na v0.9 usa o mesmo modelo novo do Espectro, com o hábito roxo.
## Espectro Ancião (antigo Colosso de Pedra) #chefe
Espectro gigante de manto cor de sangue seco e olhos âmbar, 1500 de vida (barra em 3 camadas), super armadura. Os golpes continuam os do Colosso.
- **Pisão:** salta e solta ondas de choque pelo chão para os dois lados
- **Investida:** prepara e corre até a parede
- **Arremesso de rochas:** joga pedras em arco
- Abaixo de 50% de vida fica mais rápido e agressivo, e os olhos ficam vermelhos.
- **Pilares sombrios (v0.7, só abaixo de 50%):** três pilares roxos sobem do chão, um de cada vez, onde o jogador está indo.
- **Apresentação (v0.7):** ao entrar na arena, faixas de cinema, o chefe cai do alto e aparece "Guardião das Ruínas · Espectro Ancião". O herói espera 2,5 s.
- **Golpes avisados (v0.7):** área vermelha no chão mostra onde o pisão vai cair, por onde a investida passa, onde cada rocha cai e onde os pilares sobem.
- **Postura (v0.7):** ver [[Combate]]. Quebrada, ele fica atordoado e leva mais dano.

## Regra de dano dos inimigos (Italo, 2026-11-14) #combate #decisao
Nenhum inimigo dá dano só de encostar. Cada um tem golpes próprios, e só o golpe ativo fere. Antes de todo golpe o inimigo **pisca branco** e solta um anel de luz, para o jogador saber que o golpe vem. Vale para todo inimigo novo.

| Inimigo | Golpe | Preparo | Depois |
|---|---|---|---|
| Lodo | **Bote:** encolhe e salta no herói. Só fere durante o salto | 0,43 s | fica parado 0,75 s |
| Morcego de Cinzas | **Mergulho:** para no ar e desce em linha reta no herói | 0,4 s | sobe de volta por 0,65 s |
| Espectro | Golpe de garra na frente | 0,37 s | 0,5 s |
| Espectro Conjurador | Projétil | 0,4 s | |
| Espectro Ancião | Pisão (fere na queda e nas ondas), investida (fere só correndo), rochas, pilares | 0,2 a 0,6 s | |

Fora do golpe, o Lodo anda em pulinhos que não ferem e o Morcego ronda por cima do herói.
