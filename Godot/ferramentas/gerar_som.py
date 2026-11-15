#!/usr/bin/env python3
"""Gera os efeitos sonoros e as músicas provisórias do jogo por síntese (sem amostras de terceiros).
Uso: python3 gerar_som.py <pasta assets/som>   (precisa de numpy; as músicas viram .ogg com o ffmpeg)"""
import sys, os, wave, subprocess
import numpy as np

SR = 22050
rng = np.random.default_rng(7)
OUT = sys.argv[1] if len(sys.argv) > 1 else "."

def t_(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=0.1, curva=2.0):
    e = np.ones(n); na = max(1, int(a * SR)); nr = max(1, min(n, int(r * SR)))
    e[:na] = np.linspace(0, 1, na); e[-nr:] *= np.linspace(1, 0, nr) ** curva
    return e
def dec(d, k): return np.exp(-t_(d) * k)
def varre(f0, f1, d, forma="sin", curva=1.0):
    k = np.linspace(0, 1, int(SR * d)) ** curva
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / SR
    if forma == "sin": return np.sin(ph)
    if forma == "saw": return sum(np.sin(ph * h) / h for h in range(1, 9)) * 0.6
    if forma == "quad": return sum(np.sin(ph * h) / h for h in range(1, 12, 2)) * 0.8
def ruido(d): return rng.uniform(-1, 1, int(SR * d))
def filtro(x, f0, f1, q=2.0, modo="bp"):
    """Filtro de estado variável com frequência que desliza de f0 a f1."""
    n = len(x); y = np.zeros(n); lo = bp = 0.0
    fs = np.linspace(f0, f1, n); damp = 1.0 / q
    for i in range(n):
        f = 2 * np.sin(np.pi * min(fs[i], SR / 6.5) / SR)
        lo += f * bp; hi = x[i] - lo - damp * bp; bp += f * hi
        y[i] = bp if modo == "bp" else (lo if modo == "lp" else hi)
    return y
def junta(*partes):
    n = max(len(p) for p in partes); y = np.zeros(n)
    for p in partes: y[:len(p)] += p
    return y
def atraso(x, d): return np.concatenate([np.zeros(int(SR * d)), x])
def norm(x, pico=0.9): return x / (np.max(np.abs(x)) + 1e-9) * pico
def salva(nome, x, pico=0.9):
    x = norm(x, pico); x[-64:] *= np.linspace(1, 0, 64)
    with wave.open(os.path.join(OUT, nome + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())

def sino(f, d, k=5.0, parciais=((1, 1), (2.76, 0.45), (5.4, 0.25), (8.93, 0.12))):
    t = t_(d); return sum(a * np.sin(2 * np.pi * f * m * t) * np.exp(-t * k * (1 + i * 0.6)) for i, (m, a) in enumerate(parciais))

# ---------------- efeitos ----------------
def efeitos():
    n = ruido(0.2); salva("golpe", filtro(n, 500, 3200, 1.6) * env(len(n), 0.03, 0.12), 0.55)
    n = ruido(0.3); salva("golpe2", junta(filtro(n, 300, 2400, 1.4) * env(len(n), 0.06, 0.16), varre(180, 70, 0.3) * env(int(SR * 0.3), 0.05, 0.2) * 0.3), 0.7)
    n = ruido(0.09); salva("acerto", junta(varre(170, 55, 0.13) * dec(0.13, 22), filtro(n, 3500, 900, 1.2) * dec(0.09, 40) * 0.9), 0.85)
    n = ruido(0.16); salva("acerto2", junta(varre(130, 38, 0.24) * dec(0.24, 13) * 1.2, filtro(n, 2500, 400, 1.0) * dec(0.16, 22), varre(900, 300, 0.08, "saw") * dec(0.08, 40) * 0.3), 0.95)
    n = ruido(0.08); salva("critico", junta(varre(200, 50, 0.2) * dec(0.2, 14), filtro(n, 5000, 2000, 1.0) * dec(0.08, 30), sino(1568, 0.5, 7) * 0.5, sino(2093, 0.5, 9) * 0.35), 0.95)
    n = int(SR * 0.14); salva("pulo", varre(260, 520, 0.14, "sin", 0.6)[:n] * env(n, 0.01, 0.1) + filtro(ruido(0.14), 800, 2500, 1.5)[:n] * env(n, 0.01, 0.1) * 0.25, 0.4)
    n = ruido(0.22); salva("esquiva", filtro(n, 3500, 700, 2.2) * env(len(n), 0.02, 0.17), 0.5)
    n = ruido(0.12); salva("dano", junta(varre(240, 80, 0.22, "saw") * dec(0.22, 12) * 0.7, filtro(n, 1800, 500, 1.0) * dec(0.12, 25), varre(110, 45, 0.2) * dec(0.2, 12)), 0.85)
    d = 0.5; salva("carga", (varre(110, 330, d, "saw", 1.4) * 0.5 + filtro(ruido(d), 600, 4000, 3.0) * 0.4) * env(int(SR * d), 0.1, 0.05), 0.4)
    salva("carga_nivel", junta(sino(988, 0.5, 8), atraso(sino(1480, 0.5, 8), 0.05)) , 0.6)
    d = 0.5; salva("magia", junta(np.sin(2 * np.pi * np.cumsum(np.linspace(500, 1400, int(SR * d))) / SR + 3 * np.sin(2 * np.pi * 37 * t_(d))) * env(int(SR * d), 0.02, 0.35) * 0.6,
                                 filtro(ruido(d), 2000, 6000, 3.0) * env(int(SR * d), 0.05, 0.4) * 0.5, sino(1320, d, 6) * 0.4), 0.6)
    d = 0.9; salva("explosao", junta(filtro(ruido(d), 1800, 90, 0.8, "lp") * dec(d, 4.5) * 1.5, varre(95, 28, 0.6) * dec(0.6, 5) * 1.3, filtro(ruido(0.05), 4000, 2000, 1.0) * dec(0.05, 50)), 0.98)
    n = ruido(0.16); salva("flecha", junta(varre(700, 240, 0.07, "saw") * dec(0.07, 45) * 0.6, atraso(filtro(n, 2500, 5500, 3.0) * env(len(n), 0.01, 0.13), 0.02)), 0.5)
    salva("item", junta(sino(880, 0.3, 9), atraso(sino(1318.5, 0.4, 8), 0.07)), 0.5)
    salva("moeda", junta(sino(1975, 0.2, 14, ((1, 1), (2.4, 0.4))), atraso(sino(2637, 0.35, 11, ((1, 1), (2.4, 0.4))), 0.06)), 0.4)
    salva("menu", sino(660, 0.12, 30, ((1, 1), (2, 0.3))) + filtro(ruido(0.12), 3000, 3000, 2.0) * dec(0.12, 80) * 0.3, 0.35)
    salva("confirma", junta(sino(587.3, 0.5, 6), atraso(sino(880, 0.5, 6), 0.045), atraso(sino(1174.7, 0.6, 5), 0.09)), 0.5)
    salva("volta", sino(392, 0.2, 16, ((1, 1), (2, 0.3))), 0.35)
    notas = [587.3, 740, 880, 1174.7, 1480]
    salva("nivel", junta(*[atraso(junta(sino(f, 1.0, 3.5), 0.3 * sino(f * 2, 0.8, 5)), i * 0.085) for i, f in enumerate(notas)], atraso(filtro(ruido(0.9), 3000, 8000, 3.0) * env(int(SR * 0.9), 0.2, 0.6) * 0.25, 0.3)), 0.7)
    def metal(f, d): return varre(f, f, d, "saw") * env(int(SR * d), 0.02, min(0.25, d * 0.6)) + varre(f * 1.005, f * 1.005, d, "quad") * env(int(SR * d), 0.02, 0.2) * 0.5
    fan = [(293.7, 0.0, 0.18), (293.7, 0.18, 0.18), (440, 0.36, 0.3), (587.3, 0.66, 0.9), (370, 0.66, 0.9), (440, 0.66, 0.9)]
    salva("vitoria", eco(junta(*[atraso(metal(f, d), a) for f, a, d in fan]), 0.11, 0.3), 0.6)
    der = [(440, 0.0, 0.35), (415.3, 0.35, 0.35), (349.2, 0.7, 0.4), (293.7, 1.1, 1.2), (174.6, 1.1, 1.2)]
    salva("derrota", eco(junta(*[atraso(metal(f, d) * 0.8, a) for f, a, d in der]), 0.16, 0.35), 0.5)
    d = 1.5; g = varre(70, 42, d, "saw") * (1 + 0.6 * np.sin(2 * np.pi * 23 * t_(d))) * env(int(SR * d), 0.15, 0.7)
    salva("chefe", eco(junta(g, filtro(ruido(d), 900, 200, 1.5) * env(int(SR * d), 0.2, 0.9) * 0.6), 0.13, 0.4), 0.9)
    salva("queda", junta(varre(120, 40, 0.18) * dec(0.18, 16), filtro(ruido(0.1), 900, 300, 1.0, "lp") * dec(0.1, 30)), 0.7)
    d = 0.6; salva("morte", junta(filtro(ruido(d), 2500, 300, 4.0) * env(int(SR * d), 0.02, 0.5), varre(520, 130, d, "sin", 0.7) * env(int(SR * d), 0.02, 0.5) * 0.35), 0.5)

def eco(x, d, g, vezes=5):
    y = np.concatenate([x, np.zeros(int(SR * d * vezes))])
    for k in range(1, vezes + 1):
        o = int(SR * d * k); y[o:o + len(x)] += x * g ** k
    return y

# ---------------- música ----------------
def hz(semitom): return 440.0 * 2 ** ((semitom - 69) / 12.0)

class Faixa:
    def __init__(self, bpm, batidas):
        self.spb = 60.0 / bpm; self.n = int(SR * self.spb * batidas); self.buf = np.zeros(self.n)
    def poe(self, x, batida, vol=1.0):
        o = int(batida * self.spb * SR); idx = (o + np.arange(len(x))) % self.n
        np.add.at(self.buf, idx, x * vol)
    def reverb(self, mix=0.3):
        w = np.zeros(self.n)
        for d, g in ((0.031, 0.5), (0.047, 0.45), (0.071, 0.4), (0.113, 0.33), (0.173, 0.27), (0.251, 0.2), (0.367, 0.14)):
            w += np.roll(self.buf, int(SR * d)) * g
        k = 5; w = np.convolve(np.concatenate([w[-k:], w, w[:k]]), np.ones(k) / k, "same")[k:-k]
        self.buf = self.buf + w * mix
    def grava(self, nome, pico=0.8):
        x = norm(self.buf, pico); cam = os.path.join(OUT, nome)
        with wave.open(cam + ".tmp.wav", "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", cam + ".tmp.wav", "-c:a", "libvorbis", "-q:a", "3", cam + ".ogg"], check=True)
        os.remove(cam + ".tmp.wav")

def cordas(nota, d, a=0.12, r=0.3):
    t = t_(d + r); y = np.zeros(len(t))
    for det in (-0.07, 0.0, 0.08):
        f = hz(nota + det); y += sum(np.sin(2 * np.pi * f * h * t + h * det * 9) / h ** 1.25 for h in range(1, 9))
    return y * env(len(t), a, r) * 0.2
def orgao(nota, d):
    t = t_(d + 0.25); f = hz(nota)
    return sum(np.sin(2 * np.pi * f * h * t) * a for h, a in ((0.5, 0.5), (1, 1), (2, 0.6), (3, 0.3), (4, 0.35), (6, 0.12), (8, 0.1))) * env(len(t), 0.06, 0.25) * 0.2
def cravo(nota, d):
    t = t_(d); f = hz(nota)
    return sum(np.sin(2 * np.pi * f * h * t) / h ** 0.8 * np.exp(-t * (3 + h * 1.3)) for h in range(1, 12)) * env(len(t), 0.002, 0.03) * 0.3
def baixo(nota, d):
    t = t_(d); f = hz(nota)
    return sum(np.sin(2 * np.pi * f * h * t) / h * np.exp(-t * h * 2.5) for h in range(1, 7)) * env(len(t), 0.004, 0.04) * 0.5
def coro(nota, d):
    t = t_(d + 0.5); f = hz(nota); vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t)
    ph = 2 * np.pi * f * np.cumsum(vib) / SR
    y = sum(np.sin(ph * h) * np.exp(-((f * h - 750) / 420) ** 2) for h in range(1, 14)) + 0.4 * np.sin(ph)
    return y * env(len(t), 0.3, 0.5) * 0.25
def bumbo(): return varre(130, 42, 0.22, "sin", 0.5) * dec(0.22, 14)
def caixa():
    n = ruido(0.16); return junta(filtro(n, 2200, 1500, 0.8) * dec(0.16, 22), varre(210, 150, 0.08) * dec(0.08, 30) * 0.5)
def chimbal():
    n = ruido(0.04); return filtro(n, 7000, 7000, 1.5, "hp") * dec(0.04, 90)
def timpano(nota): return junta(varre(hz(nota) * 1.3, hz(nota), 0.7, "sin", 0.2) * dec(0.7, 5), filtro(ruido(0.1), 400, 200, 1.0, "lp") * dec(0.1, 25) * 0.5)

D, E, F, G, A, Bb, C = 50, 52, 53, 55, 57, 58, 60   # ré menor (ré2 = 50)
ACORDES = {"Dm": (D, F, A), "Bb": (Bb - 12, D, F), "Gm": (G - 12, Bb - 12, D), "A": (A - 12, C + 1 - 12, E), "F": (F - 12, A - 12, C), "C": (C - 12, E, G), "Em5": (E, G, Bb)}

def musica_menu():
    fx = Faixa(66, 32)
    prog = ["Dm", "Bb", "Gm", "A", "Dm", "F", "Gm", "A"]
    for i, nome in enumerate(prog):
        b = i * 4
        for n in ACORDES[nome]:
            fx.poe(orgao(n + 12, fx.spb * 3.9), b, 0.5); fx.poe(coro(n + 12, fx.spb * 3.6), b, 0.55)
        fx.poe(orgao(ACORDES[nome][0] - 12, fx.spb * 3.9), b, 0.9)
    mel = [(0, A + 12, 2), (2, F + 12, 1), (3, E + 12, 1), (4, D + 12, 3), (7, F + 12, 1), (8, G + 12, 2), (10, Bb + 12, 2), (12, A + 12, 3), (15, E + 12, 1),
           (16, F + 12, 2), (18, A + 12, 2), (20, C + 24, 3), (23, A + 12, 1), (24, Bb + 12, 2), (26, G + 12, 2), (28, A + 12, 2), (30, C + 13, 2)]
    for b, n, d in mel:
        fx.poe(sino(hz(n + 12), 2.4, 2.2) * 0.5, b, 0.5); fx.poe(cordas(n, fx.spb * d, 0.2, 0.5), b, 0.5)
    for b in (0, 16): fx.poe(timpano(D - 12), b, 0.7)
    fx.reverb(0.55); fx.grava("musica_menu", 0.7)

def musica_fase(nome, bpm, prog, tom=0, densa=False):
    barras = len(prog); fx = Faixa(bpm, barras * 4)
    mel_a = [0, 7, 5, 7, 3, 5, 2, 0]; escala = [D, E, F, G, A, Bb, C + 1]
    for i, ac in enumerate(prog):
        b = i * 4; notas = [n + tom for n in ACORDES[ac]]; raiz = notas[0] - 12
        passo = 0.25 if densa else 0.5
        for k in range(int(4 / passo)):   # baixo em ostinato
            oit = 12 if (k % 4 == 2) else 0
            fx.poe(baixo(raiz + oit, fx.spb * passo * 0.95), b + k * passo, 0.9)
        for n in notas: fx.poe(cordas(n + 12, fx.spb * 3.7, 0.15, 0.4), b, 0.55)
        for k in (1.5, 3.5) if not densa else (0.5, 1.5, 2.5, 3.5):   # golpes de cordas no contratempo
            for n in notas: fx.poe(cordas(n + 24, fx.spb * 0.3, 0.01, 0.15), b + k, 0.5)
        if densa:
            for n in notas: fx.poe(coro(n + 12, fx.spb * 3.6), b, 0.6)
        for k in range(4):
            fx.poe(bumbo(), b + k, 1.0 if k % 2 == 0 else (0.8 if densa else 0.0))
            if k % 2 == 1: fx.poe(caixa(), b + k, 0.55)
        for k in range(8): fx.poe(chimbal(), b + k * 0.5, 0.16 if k % 2 == 0 else 0.26)
        if i % 4 == 3: 
            for k in range(4): fx.poe(caixa(), b + 3 + k * 0.25, 0.3 + k * 0.08)
        if i % 4 == 0: fx.poe(timpano(raiz), b, 0.8)
        # melodia de cravo: arpejo do acorde com notas de passagem
        arp = [notas[0], notas[1], notas[2], notas[1] + 12, notas[2], notas[1], notas[0] + 12, notas[2]]
        if i % 2 == 0:
            for k, n in enumerate(arp): fx.poe(cravo(n + 24, fx.spb * 0.5), b + k * 0.5, 0.5)
        else:
            tema = [(0, notas[2] + 24, 1.5), (1.5, notas[1] + 24, 0.5), (2, notas[0] + 24, 1), (3, notas[1] + 24 + (1 if i % 4 == 3 else 0), 1)]
            for kb, n, d in tema:
                fx.poe(cravo(n, fx.spb * d), b + kb, 0.7); fx.poe(cordas(n, fx.spb * d, 0.05, 0.2), b + kb, 0.45)
    fx.reverb(0.35); fx.grava(nome, 0.75)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    efeitos()
    musica_menu()
    musica_fase("musica_fase", 126, ["Dm", "Dm", "Bb", "C", "Dm", "F", "Gm", "A"] * 2)
    musica_fase("musica_chefe", 148, ["Dm", "Bb", "Gm", "A", "Dm", "C", "Bb", "A"], 0, True)
    print("ok")
