---
tags: [changelog, registro]
---
# Changelog

## 2026-11-13
- Obsidian já estava instalado (v1.14.4). Cofre criado em `B:\Antigravity\Liga Dos Guerreiros\Obsidian` e registrado no app.
- Cofre preenchido: visão geral, personagens, sistemas, fase 1, bestiário, arte, tecnologia e registros, todos com tags.
- **Protótipo v0.1** jogável no navegador (HTML5): seleção de personagem (Kael, Lyra, Oren), combo de 3 golpes, cancelamento em habilidade, 3 habilidades por classe, esquiva, pulo duplo, plataformas, 4 inimigos comuns, chefe Colosso de Pedra, barreiras por área, portal de fim, tela de resultado com ranking. Arte provisória desenhada em código.
  - Arquivo: `Prototipo\index.html` (abrir no navegador)
  - Link online: https://claude.ai/artifact/6qELho25Nizv5V71uSwcYJ
- Engine definida: **Godot 4** (escolha do Italo). Início da migração do protótipo.
- Plataforma definida: PC. Multijogador entra no planejamento desde já (começa com 1 jogador).
- **Projeto Godot v0.2** criado em `Godot\`: protótipo migrado por completo (3 classes, combos, habilidades, 4 inimigos, chefe, barreiras, portal, ranking), estrutura pronta para multijogador. Testado no Godot 4.5.1. Ver [[Projeto Godot]].
- Estudo de **personagens em 2.5D**: 4 caminhos comparados em [[Personagens em 2.5D]] e teste jogável com 3 estilos em `Testes\2.5D\index.html`. Nenhuma alteração no projeto Godot.
- Italo escolheu o **3D em tempo real**. Novo teste **Kael gótico** em `Testes\2.5D\gotico.html`: proporções adultas, armadura de placas, capa de tecido animada, 3 paletas, ruínas de catedral com lua, vitrais, névoa e braseiros, espectros como inimigos de treino. Nota nova [[Direção de Arte]]. Projeto Godot ainda sem alterações.
- Teste **Arena gótica** em `Testes\2.5D\arena.html`, seguindo a referência de pegada do Italo: proporção anime de ação, contorno grosso, três andares de plataformas, cascatas e vegetação, interface (vida, mana, técnicas, cronômetro), técnica Investida e descida de plataforma. Projeto Godot ainda sem alterações.
- **Kael rascunho 4**: cabeça esculpida com rosto e olhos pintados em estilo anime (pupila em losango, cicatriz, piscar), cabelo em mechas com rabo de cavalo e mecha tingida, armadura com texturas ornamentadas, manto de penas, capa bordada, espada com runas, escudo com brasão. Vitrine em `Testes\2.5D\kael.html` e modelo aplicado na arena.
- **Kael rascunho 5**: proporção pequena (3 cabeças), cabeça mais redonda, olhos maiores, tronco curto, manoplas e botas grandes. Vitrine e arena atualizadas.
- Kael: cabeça e cabelo mais estreitos (largura 83%). Corpo mantido.
- **Kael rascunho 6**: modelo separado em base (macacão, espada e escudo de madeira) e equipamentos (armadura, manto e capa, espada rúnica, escudo da Ordem), com botões na vitrine e tecla E na arena. Nota nova [[Equipamentos]].
- **Kael rascunho 7**: base simplificada. Macacão liso de uma cor só, de manga curta e short, com braços, pernas, mãos e pés de pele. Saíram zíper, vivos, bolsos, rosácea, cinto, luvas e botas (cinto passou para a armadura). Rosto, cabeça, corpo e armas de madeira mantidos. Vitrine e arena atualizadas.
- **Kael rascunho 8**: ombros mais baixos e encaixados no torso, torso 20% mais longo (TS 0,72), cintura mais larga, quadril menos bojudo com a raiz das coxas unida, pernas mais juntas, mãos com polegar e pés mais achatados. Ombreiras da armadura acompanharam.
- **Kael rascunho 9**: pescoço encurtado (constante NK 0,58 no `kael.js`) e ombros retos, sem a rampa longa até o ombro. Gola, manto e capa da armadura acompanharam.
- **Kael rascunho 10**: cabeça mais baixa, com o queixo cobrindo o pescoço (NK 0,56). Maxilar e queixo arredondados, sem o V, e cabeça mais fina (78% de largura). Olhos, cicatriz e cabelo mantidos.
- Vitrine do Kael: botão **Cabelo** que mostra ou esconde o cabelo, para conferir o formato da cabeça. No modelo, o cabelo virou um grupo próprio (`Kael.equipar(k, "cabelo", false)`).
- **Kael rascunho 11**: parte de trás do crânio reduzida (constante TRAS 0,8 no `kael.js`), orelhas modeladas com o miolo mais escuro, e pele uniforme na cabeça (saíram as sombras arroxeadas pintadas no couro cabeludo e nas laterais). Rosto, olhos e volume do cabelo mantidos.
- **Kael rascunho 12**: cabelo reajustado ao crânio menor (constante CAB_TRAS 0,72 no `kael.js`): calota, mechas de trás e rabo de cavalo agora ficam rentes à cabeça. Penteado, cores e mecha tingida mantidos.
- **Kael rascunho 13**: perfil mais suave. Nariz cerca de um terço mais baixo e região da boca um pouco à frente. Resto do rosto mantido.
- Kael rascunho 13 (complemento): rosto mais plano na frente e olhos um pouco mais próximos do centro, para ficarem menos lateralizados.
- **Kael rascunho 14**: cabeça recuada sobre os ombros (centralizada no pescoço), para tirar o ar de corcunda. Altura da cabeça mantida.
- Nota nova [[Revisão do Modelo Base]]: 12 pontos de melhoria do modelo base, com ordem recomendada. Nenhuma alteração no modelo.
- Projeto enviado ao **GitHub**: https://github.com/MozaTatalo/liga-dos-guerreiros (pastas `Godot/`, `Prototipo/`, `Testes/2.5D/` com o Kael rascunho 14, e `Obsidian/`), com README em português, `.gitignore` para Godot e Obsidian e `.gitattributes`. Nada do jogo ou do modelo foi alterado.
- **Kael rascunho 15** (acabamento do corpo base): mãos em punho fechado com quatro dedos e polegar em volta do cabo; pés com tornozelo, calcanhar, peito do pé e dedos; cotovelos, pulsos e joelhos sem emenda; pele com três tons de sombra, pescoço na sombra do queixo, sombra da franja na testa e contorno de espessura uniforme; cabelo com segunda camada na franja e atrás, e balanço ao correr. Pomo da espada de madeira encurtado (atravessava o antebraço).
- **Kael rascunho 16**: mãos e pés voltaram ao formato do rascunho 14, a pedido do Italo. Mantidos do rascunho 15: juntas sem emenda, sombra e contorno, cabelo em camadas com balanço e o pomo curto da espada de madeira.
- **Kael rascunho 17** (cabelo refeito): cerca de 90 mechas finas no lugar de 35 largas, em três camadas atrás, franja de pontas desencontradas com fios soltos por cima, laterais divididas, rabo de cavalo ondulado com duas mechas tingidas. Textura nova com fios finos e faixa de brilho suave, contorno do cabelo pela metade. Penteado, cores e mecha vermelha mantidos.
- Kael: removida a sombra semitransparente da franja na testa (aparecia como uma faixa reta entre as mechas finas).
- **Rascunho 18** (corpo estreito e corpo feminino): tronco 28% mais estreito de lado a lado, ombros e pernas mais próximos do eixo, braços e pernas mais finos, pés mais estreitos. `Kael.criar({ corpo: "f" })` gera o corpo feminino. A vitrine mostra os dois lado a lado, com botões Corpo (Os dois, Masculino, Feminino) e Armas (esconde as armas para ver o corpo). A armadura ainda não foi reajustada ao corpo estreito.
- **Rascunho 19** (masculino e feminino mais diferentes): masculino com tronco e ombros mais largos, braços afastados e pernas abertas na pose parada. Feminino com ombros para dentro, braços junto ao corpo, pernas juntas, top sem manga e short com a barriga à mostra, e busto discreto. Cada corpo tem a sua pose parada.
