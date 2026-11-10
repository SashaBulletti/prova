#!/usr/bin/env python3
"""Genera i suoni del Mostrometro e li scrive in mostrometro/audio_dati.h

Serve:  espeak-ng (voce italiana) e numpy.   Uso:  python3 genera_audio.py

Cosa produce (tutto a 12 kHz, mono, compresso in 8 bit "mu-law"):
  - i numeri da 0 a 100, detti con voce da mostro
  - "sei al" / "sei all'" / "per cento"
  - "urla!", "urlo da", "punti", un bip
  - 6 versi di mostro, dal piccolo pigolio al ruggito enorme (uno per ogni livello di mostruosita')
Se vuoi cambiare la voce, modifica VOCE_* qui sotto e rilancia lo script, poi ricarica il firmware.
"""
import os, subprocess, tempfile, wave
import numpy as np

RATE = 12000                                    # frequenza finale
USCITA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mostrometro", "audio_dati.h")

# --- voce da mostro: piu' bassa e un po' rauca
VOCE_ESPEAK = ["-v", "it", "-p", "8", "-s", "185", "-a", "190", "-g", "2"]
VOCE_ABBASSA = 0.86            # 1 = invariata, <1 = piu' grave (e piu' lenta)
VOCE_RAUCA = 2.2               # quanta distorsione aggiungere
rng = np.random.default_rng(49)

# ------------------------------------------------------------------ numeri in italiano
UNITA = ["zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci", "undici",
         "dodici", "tredici", "quattordici", "quindici", "sedici", "diciassette", "diciotto", "diciannove"]
DECINE = {2: "venti", 3: "trenta", 4: "quaranta", 5: "cinquanta", 6: "sessanta", 7: "settanta", 8: "ottanta", 9: "novanta"}

def numero(n):
    if n < 20:
        return UNITA[n]
    if n == 100:
        return "cento"
    d, u = divmod(n, 10)
    w = DECINE[d]
    if u == 0:
        return w
    if u in (1, 8):
        w = w[:-1]                      # ventuno, ventotto, trentuno...
    return w + ("tré" if u == 3 else UNITA[u])

def comincia_con_vocale(n):
    return numero(n)[0] in "uo"          # uno, undici, otto, ottanta...: "sei ALL'otto"

# ------------------------------------------------------------------ audio di base
def parla(testo):
    """Voce sintetica (espeak-ng) -> array float32 mono a 22050 Hz."""
    with tempfile.TemporaryDirectory() as d:
        f = os.path.join(d, "x.wav")
        subprocess.run(["espeak-ng", *VOCE_ESPEAK, "-w", f, testo], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with wave.open(f) as w:
            sr, n = w.getframerate(), w.getnframes()
            x = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float32) / 32768
    return x, sr

def ricampiona(x, sr_da, sr_a):
    if sr_da == sr_a:
        return x
    if sr_a < sr_da:                    # filtro semplice prima di togliere campioni
        k = max(1, int(round(sr_da / sr_a)))
        x = np.convolve(x, np.ones(k) / k, mode="same")
    t_new = np.arange(0, len(x) / sr_da, 1 / sr_a)
    return np.interp(t_new, np.arange(len(x)) / sr_da, x).astype(np.float32)

def taglia_silenzio(x, soglia=0.02, margine=0.02):
    idx = np.where(np.abs(x) > soglia * max(1e-6, np.max(np.abs(x))))[0]
    if len(idx) == 0:
        return x
    m = int(margine * RATE)
    return x[max(0, idx[0] - m): idx[-1] + m]

def distorci(x, quanto):
    return np.tanh(x * quanto) / np.tanh(quanto)

def passa_basso(x, hz):
    k = max(1, int(RATE / (2 * hz)))
    return np.convolve(x, np.ones(k) / k, mode="same")

def normalizza(x, picco=0.85):
    return (x / max(1e-6, np.max(np.abs(x))) * picco).astype(np.float32)

def voce_mostro(testo):
    x, sr = parla(testo)
    x = ricampiona(x, sr, int(RATE / VOCE_ABBASSA))     # rallentare/abbassare = suonare con meno campioni al secondo
    x = x.astype(np.float32)
    x = distorci(x, VOCE_RAUCA)
    t = np.arange(len(x)) / RATE
    x = x * (0.78 + 0.22 * np.sin(2 * np.pi * 34 * t))   # un po' di "grugnito"
    x = passa_basso(x, 3800)
    return normalizza(taglia_silenzio(x))

# ------------------------------------------------------------------ versi di mostro (sintetici)
def sega(fase):
    return 2 * (fase % 1.0) - 1

def verso(durata, f0, f1, vibrato_hz, vibrato, rauco, rumore, armoniche=3, sub=0.0, inviluppo="dolce"):
    n = int(durata * RATE)
    t = np.arange(n) / RATE
    f = np.linspace(f0, f1, n) * (1 + vibrato * np.sin(2 * np.pi * vibrato_hz * t))
    fase = np.cumsum(f) / RATE
    x = sum(sega(fase * k + 0.17 * k) / k for k in range(1, armoniche + 1))
    if sub:
        x += sub * np.sin(2 * np.pi * fase * 0.5)
    x += rumore * passa_basso(rng.standard_normal(n).astype(np.float32), 1500)
    x = distorci(x, rauco)
    if inviluppo == "dolce":
        env = np.sin(np.pi * np.linspace(0, 1, n)) ** 0.6
    elif inviluppo == "ruggito":
        a = np.minimum(1, np.linspace(0, 1, n) / 0.08)
        env = a * np.exp(-1.4 * np.linspace(0, 1, n))
    else:
        env = np.ones(n)
    return normalizza(x * env, 0.9)

def pigolio():
    a = verso(0.14, 900, 1500, 9, 0.02, 1.2, 0.0, 1)
    b = verso(0.12, 1300, 1900, 9, 0.02, 1.2, 0.0, 1)
    return np.concatenate([a, np.zeros(int(0.05 * RATE), np.float32), b])

def versi():
    return [
        pigolio(),                                                                           # 0 angelo
        np.concatenate([verso(0.30, 230, 330, 6, 0.03, 1.6, 0.05, 3), verso(0.25, 330, 410, 6, 0.03, 1.6, 0.05, 3)]),  # 1 "mmh?"
        verso(0.65, 120, 90, 14, 0.05, 2.6, 0.18, 5, 0.3),                                   # 2 grugnito
        verso(0.95, 100, 70, 22, 0.08, 3.2, 0.30, 6, 0.5, "ruggito"),                        # 3 ringhio
        verso(1.25, 85, 50, 28, 0.12, 4.0, 0.42, 8, 0.7, "ruggito"),                         # 4 ruggito
        np.concatenate([verso(1.1, 70, 38, 31, 0.15, 5.0, 0.50, 9, 0.9, "ruggito"),          # 5 RUGGITO ENORME
                        verso(0.7, 120, 45, 20, 0.2, 5.0, 0.55, 8, 0.9, "ruggito")]),
    ]

def bip():
    n = int(0.18 * RATE)
    t = np.arange(n) / RATE
    return normalizza(np.sin(2 * np.pi * 880 * t) * np.sin(np.pi * np.linspace(0, 1, n)), 0.7)

# ------------------------------------------------------------------ mu-law a 8 bit
MU = 255.0
def mulaw(x):
    x = np.clip(x, -1, 1)
    y = np.sign(x) * np.log1p(MU * np.abs(x)) / np.log1p(MU)
    return np.round((y + 1) / 2 * 255).astype(np.uint8)

def main():
    clip = []                                              # (nome, campioni)
    for n in range(101):
        clip.append((f"numero_{n}", voce_mostro(numero(n))))
    clip.append(("sei_al", voce_mostro("sei al")))
    clip.append(("sei_all", voce_mostro("sei all")))
    clip.append(("per_cento", voce_mostro("per cento")))
    clip.append(("urla", voce_mostro("urla")))
    clip.append(("urlo_da", voce_mostro("urlo da")))
    clip.append(("punti", voce_mostro("punti")))
    clip.append(("bip", bip()))
    for i, v in enumerate(versi()):
        clip.append((f"verso_{i}", v))

    pool, offsets, lunghezze = [], [], []
    pos = 0
    for nome, x in clip:
        b = mulaw(x)
        offsets.append(pos)
        lunghezze.append(len(b))
        pool.append(b)
        pos += len(b)
    dati = np.concatenate(pool)

    nomi = [n for n, _ in clip]
    righe = []
    righe.append("// GENERATO da firmware/genera_audio.py: non modificare a mano.")
    righe.append(f"// {len(clip)} suoni, {len(dati) / 1024:.0f} KB, {RATE} Hz, mono, mu-law a 8 bit.")
    righe.append("#pragma once\n#include <stdint.h>\n")
    righe.append(f"#define AUDIO_RATE {RATE}")
    righe.append(f"#define AUDIO_NCLIP {len(clip)}")
    idx = {n: i for i, n in enumerate(nomi)}
    righe.append(f"#define CLIP_NUMERO0 {idx['numero_0']}        // CLIP_NUMERO0 + n = il numero n (0..100)")
    for chiave in ("sei_al", "sei_all", "per_cento", "urla", "urlo_da", "punti", "bip", "verso_0"):
        nome_c = "CLIP_VERSO0" if chiave == "verso_0" else f"CLIP_{chiave.upper()}"
        righe.append(f"#define {nome_c} {idx[chiave]}")
    righe.append("// CLIP_VERSO0 + livello = verso del mostro per quel livello (0..5)\n")
    righe.append("const uint32_t AUDIO_OFFSET[AUDIO_NCLIP] = {" + ",".join(str(o) for o in offsets) + "};")
    righe.append("const uint32_t AUDIO_LUNGH[AUDIO_NCLIP] = {" + ",".join(str(n) for n in lunghezze) + "};")
    righe.append(f"const uint8_t AUDIO_POOL[{len(dati)}] = {{")
    for i in range(0, len(dati), 32):
        righe.append(",".join(str(int(v)) for v in dati[i:i + 32]) + ",")
    righe.append("};")
    with open(USCITA, "w") as f:
        f.write("\n".join(righe) + "\n")

    # riepilogo
    sec = np.array(lunghezze) / RATE
    print(f"{len(clip)} suoni, {len(dati) / 1024:.0f} KB -> {USCITA}")
    print(f"numeri: durata media {sec[:101].mean():.2f} s (min {sec[:101].min():.2f}, max {sec[:101].max():.2f})")
    for i in range(6):
        print(f"verso {i}: {sec[idx['verso_0'] + i]:.2f} s")
    for n in (0, 1, 8, 21, 28, 60, 100):
        print(f"  {n:3d} -> '{numero(n)}'  ({sec[n]:.2f} s)  lead = {'sei all' if comincia_con_vocale(n) else 'sei al'}")

if __name__ == "__main__":
    main()
