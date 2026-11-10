"""Converte gli STL dei due gusci in mostrometro/modello.js (usato da progetto.html).
Dopo aver cambiato mostrometro.scad: riesporta gli STL e lancia  python3 bake_modello.py

Formato: coordinate in centesimi di mm, int16, base64.
Sistema di riferimento del visualizzatore: y verso l'alto, il fronte guarda l'osservatore (+z).
  fronte: (x, y, z) -> (x, y, 30 - z)      retro: (x, y, z) -> (x, y, z)
"""
import os, re, struct, base64

DEPTH = 30.0
BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))   # cartella mostrometro/

def leggi(nome):
    t = open(f"{BASE}/hardware/stl/{nome}.stl").read()
    v = re.findall(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", t)
    return [tuple(map(float, p)) for p in v]

def impacchetta(vertici, mappa):
    out = []
    for p in vertici:
        for c in mappa(p):
            q = round(c * 100)
            assert -32768 <= q <= 32767
            out.append(q)
    return base64.b64encode(struct.pack(f"<{len(out)}h", *out)).decode()

def forma(prefisso):
    f = impacchetta(leggi(prefisso + "fronte"), lambda p: (p[0], p[1], DEPTH - p[2]))
    r = impacchetta(leggi(prefisso + "retro"), lambda p: (p[0], p[1], p[2]))
    return f, r

fB, rB = forma("")        # totem (B): stl/fronte.stl, stl/retro.stl
fA, rA = forma("A_")      # mostro tondo (A): stl/A_fronte.stl, stl/A_retro.stl
js = ("// Generato da bake_modello.py a partire da hardware/stl/*.stl (int16, centesimi di mm, base64). Non modificare a mano.\n"
      f'window.MOSTRO_MODELLO={{B:{{fronte:"{fB}",retro:"{rB}"}},A:{{fronte:"{fA}",retro:"{rA}"}}}};\n')
open(f"{BASE}/modello.js", "w").write(js)
print("modello.js", len(js) // 1024, "KB")
