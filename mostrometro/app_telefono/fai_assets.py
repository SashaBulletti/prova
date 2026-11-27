#!/usr/bin/env python3
"""Prepara la cartella app/src/main/assets/www dell'app del telefono, prendendo tutto dal resto del progetto:
  - web/ (la pagina: index.html, app.css, app.js, jsQR.js)
  - dati.js: le 100 carte (titolo, testo, gruppo, codice del QR) da carte/azioni.py
  - suoni/*.wav: la voce e i versi del mostro, gli stessi del Mostrometro vero (firmware/mostrometro/audio_dati.h)
  - disegni/*.jpg: i disegni delle carte, piu' piccoli
  - mascotte.jpg, Fredoka.ttf e l'icona dell'app
Uso:  python3 fai_assets.py      (poi gradle :app:assembleRelease, oppure ci pensa GitHub)
"""
import io, json, os, re, shutil, struct, sys, wave
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
PROG = os.path.join(QUI, "..")
WWW = os.path.join(QUI, "app", "src", "main", "assets", "www")
sys.path.insert(0, os.path.join(PROG, "carte"))
from azioni import AZIONI, PUNTI_CARTA          # noqa: E402
from genera_carte import codice                 # noqa: E402

shutil.rmtree(WWW, ignore_errors=True)
os.makedirs(os.path.join(WWW, "suoni")); os.makedirs(os.path.join(WWW, "disegni"))
for f in os.listdir(os.path.join(QUI, "web")):
    shutil.copy(os.path.join(QUI, "web", f), WWW)
shutil.copy(os.path.join(PROG, "carte", "font", "Fredoka.ttf"), WWW)

# ---------- carte ----------
carte = [{"t": t, "c": c, "g": g, "p": PUNTI_CARTA, "s": 1 if e.get("speciale") == "mostro_supremo" else 0, "k": codice(i)}
         for i, (g, t, c, e) in enumerate(AZIONI, start=1)]
open(os.path.join(WWW, "dati.js"), "w", encoding="utf8").write(
    "// GENERATO da fai_assets.py: le 100 carte del Mostrometro.\nconst CARTE = " + json.dumps(carte, ensure_ascii=False) + ";\n")

# ---------- suoni: dal file del firmware (mu-law 8 bit, 12 kHz) a WAV 16 bit ----------
h = open(os.path.join(PROG, "firmware", "mostrometro", "audio_dati.h"), encoding="utf8").read()
def numeri(nome):
    m = re.search(nome + r"\[[^\]]*\]\s*=\s*\{([^}]*)\}", h, re.S)
    return [int(x) for x in m.group(1).replace("\n", "").split(",") if x.strip()]
offset, lungh, pool = numeri("AUDIO_OFFSET"), numeri("AUDIO_LUNGH"), bytes(numeri("AUDIO_POOL"))
rate = int(re.search(r"#define AUDIO_RATE (\d+)", h).group(1))

MU = 255.0                                        # stessa formula di firmware/genera_audio.py
def mulaw(b):                                     # byte 0..255 -> campione 16 bit
    y = b / 255 * 2 - 1
    x = (1 if y >= 0 else -1) * ((1 + MU) ** abs(y) - 1) / MU
    return int(round(x * 32767))
TAB = [max(-32768, min(32767, mulaw(i))) for i in range(256)]

nomi = [f"n{i:03d}" for i in range(101)] + ["sei_al", "sei_all", "per_cento", "urla", "urlo_da", "punti", "bip"] + [f"verso{i}" for i in range(6)]
assert len(nomi) == len(offset), (len(nomi), len(offset))
for nome, o, l in zip(nomi, offset, lungh):
    with wave.open(os.path.join(WWW, "suoni", nome + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", TAB[b]) for b in pool[o:o + l]))

# ---------- disegni e mascotte ----------
for i in range(1, len(AZIONI) + 1):
    for ext in ("jpg", "png"):
        p = os.path.join(PROG, "carte", "disegni", f"{i:03d}.{ext}")
        if os.path.exists(p):
            Image.open(p).convert("RGB").resize((480, 480), Image.LANCZOS).save(os.path.join(WWW, "disegni", f"{i:03d}.jpg"), "JPEG", quality=80)
            break
masc = Image.open(os.path.join(PROG, "mascotte", "mascotte_in_piedi.jpg")).convert("RGB")
masc.resize((240, 240), Image.LANCZOS).save(os.path.join(WWW, "mascotte.jpg"), "JPEG", quality=85)

# icona: la mascotte in un tondo, su fondo viola
lato = 192
ico = Image.new("RGBA", (lato, lato), (0, 0, 0, 0))
fondo = Image.new("RGBA", (lato, lato), (74, 31, 168, 255))
maschera = Image.new("L", (lato, lato), 0); ImageDraw.Draw(maschera).ellipse((0, 0, lato - 1, lato - 1), fill=255)
ico.paste(fondo, (0, 0), maschera)
m = masc.resize((int(lato * 0.98), int(lato * 0.98)), Image.LANCZOS)
mm = Image.new("L", m.size, 0); ImageDraw.Draw(mm).ellipse((6, 6, m.size[0] - 7, m.size[1] - 7), fill=255)
ico.paste(m, ((lato - m.size[0]) // 2, (lato - m.size[1]) // 2), mm)
res = os.path.join(QUI, "app", "src", "main", "res", "mipmap-xxxhdpi")
os.makedirs(res, exist_ok=True); ico.save(os.path.join(res, "icona.png"))

tot = sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(WWW) for f in fs)
print(f"assets pronti: {len(carte)} carte, {len(nomi)} suoni, {tot // 1024} KB")
