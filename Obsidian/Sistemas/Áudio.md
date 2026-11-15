---
tags: [audio, sistema]
versao: 0.6
---
# Áudio

Tudo provisório e **feito por código** (síntese), sem amostras de terceiros: `Godot/ferramentas/gerar_som.py` gera os arquivos em `Godot/assets/som/`.

- **Efeitos (24):** golpe leve e pesado, acerto leve, pesado e crítico, pulo, esquiva, dano, carga e nível de carga, magia, explosão, flecha, item, moeda, menu, confirma, volta, subir de nível, vitória, derrota, chefe, queda e morte de inimigo.
- **Músicas (3):** menu (órgão e coro lentos em ré menor), fase (cravo, cordas e bateria) e chefe (mais rápida, com coro).
- `scripts/som.gd` (autoload `Som`): `Som.tocar("acerto")`, `Som.tema("fase")`. Volumes separados nas opções.

## Pendente #pendente
Trilha de verdade (orquestra gótica), vozes curtas dos heróis, sons próprios por inimigo.
