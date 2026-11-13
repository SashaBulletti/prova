#!/usr/bin/env python3
"""Impagina le carte del Mostrometro: disegno (da Higgsfield) + titolo + come farlo + punti + QR.

Uso:
  python3 genera_carte.py                 -> crea carte.html con tutte le carte che hanno un disegno in disegni/
  python3 genera_carte.py --solo 1        -> solo la carta 1
Le immagini PNG si ottengono poi aprendo carte.html in un browser (vedi fai_png.js).

Il QR porta a  http://192.168.4.1/c?n=<numero>&k=<codice>  cioe' alla pagina del Mostrometro:
funziona quando il telefono e' collegato al WiFi del Mostrometro. Il codice serve perche' nessuno possa
"inventarsi" carte scrivendo l'indirizzo a mano.
"""
import base64, hashlib, json, os, sys
import segno
from azioni import AZIONI, PUNTI_CARTA

QUI = os.path.dirname(os.path.abspath(__file__))
SEGRETO = "mostrometro-carte-2026"     # se lo cambi, cambia anche nel firmware (sono legati)

def codice(n):
    """4 lettere che dipendono dal numero della carta: il Mostrometro accetta solo il codice giusto."""
    h = hashlib.sha256(f"{SEGRETO}:{n}".encode()).hexdigest()
    alfabeto = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    return "".join(alfabeto[int(h[i:i + 2], 16) % len(alfabeto)] for i in range(0, 8, 2))

def url(n):
    return f"http://192.168.4.1/c?n={n}&k={codice(n)}"

def qr_svg(n):
    q = segno.make(url(n), error="m", micro=False)
    return q.svg_inline(scale=4, border=2, dark="#2b1650", light="#ffffff", omitsize=True)

def data_uri(path):
    ext = os.path.splitext(path)[1].lower().strip(".")
    mime = "image/jpeg" if ext in ("jpg", "jpeg") else "image/png"
    return f"data:{mime};base64," + base64.b64encode(open(path, "rb").read()).decode()

COLORI = {   # colore della cornice per gruppo
    "Rumori a tavola": "#7a4fe0", "Versi da mostro": "#e0533f", "Facce e gesti": "#e09a1f",
    "Dispetti innocui": "#2f9e6e", "Parole e frasi": "#2f7fd0", "Movimento e ballo": "#d04f9c",
    "Cibo da mostro": "#c7781a", "A sorpresa": "#5a5ad6",
}

def carta_html(n, gruppo, titolo, come, img):
    col = COLORI.get(gruppo, "#7a4fe0")
    arte = f'<img class="arte" src="{data_uri(img)}" alt="">' if img else '<div class="arte vuota">disegno in arrivo</div>'
    return f'''<div class="carta" id="carta-{n}" style="--c:{col}">
  <div class="testa"><span class="num">N. {n:03d}</span><span class="gruppo">{gruppo}</span></div>
  {arte}
  <div class="corpo">
  <div class="titolo">{titolo}</div>
  <div class="come">{come}</div>
  <div class="piede">
    <div class="punti"><b>+{PUNTI_CARTA}</b><span>mostro</span></div>
    <div class="regola">Fallo davanti a tutti, senza avvisare.<br>Poi scansiona il QR.</div>
    <div class="qr">{qr_svg(n)}</div>
  </div>
  </div>
</div>'''

FONT = data_uri(os.path.join(QUI, "font", "Fredoka.ttf")).replace("image/png", "font/ttf")

STILE = '''@font-face{font-family:"Fredoka";src:url("FONT") format("truetype");font-weight:300 700}
*{box-sizing:border-box}
body{margin:0;background:#e9e2f5;font-family:"Fredoka",sans-serif;display:flex;flex-wrap:wrap;gap:24px;padding:24px}
.carta{width:63mm;height:88mm;border-radius:4mm;background:var(--c);padding:2.2mm;display:flex;flex-direction:column;
  box-shadow:0 2px 8px rgba(0,0,0,.25);overflow:hidden;color:#2b1650}
.testa{display:flex;justify-content:space-between;align-items:center;color:#fff;font-weight:600;font-size:2.6mm;padding:0 1mm 1.2mm}
.arte{display:block;width:100%;aspect-ratio:6/5;object-fit:cover;object-position:50% 40%;border-radius:2.6mm;background:#fff6e6;border:.6mm solid #fff}
.arte.vuota{display:flex;align-items:center;justify-content:center;color:#b9a6dd;font-size:3mm}
.corpo{background:#fff;margin-top:1.6mm;border-radius:2.4mm;flex:1;display:flex;flex-direction:column}
.titolo{padding:1.4mm 2mm 0;font-weight:700;font-size:5.4mm;line-height:1.05;text-align:center}
.come{padding:.6mm 2.4mm 1.2mm;font-size:2.75mm;line-height:1.2;text-align:center;font-weight:400;color:#4a3a66;flex:1}
.piede{display:flex;align-items:center;gap:1.6mm;padding:0 1.6mm 1.6mm}
.punti{background:var(--c);color:#fff;border-radius:2mm;width:11mm;height:11mm;display:flex;flex-direction:column;align-items:center;justify-content:center;line-height:1}
.punti b{font-size:5mm;font-weight:700}.punti span{font-size:1.9mm;font-weight:500}
.regola{flex:1;font-size:2.15mm;line-height:1.25;color:#6a5a86}
.qr svg{display:block;width:13mm;height:13mm}
'''.replace("FONT", FONT)

def main():
    solo = None
    if "--solo" in sys.argv:
        solo = int(sys.argv[sys.argv.index("--solo") + 1])
    carte = []
    for i, (gruppo, titolo, come) in enumerate(AZIONI, start=1):
        if solo and i != solo:
            continue
        img = None
        for ext in ("png", "jpg"):
            p = os.path.join(QUI, "disegni", f"{i:03d}.{ext}")
            if os.path.exists(p):
                img = p
        carte.append(carta_html(i, gruppo, titolo, come, img))
    html = '<!doctype html><meta charset="utf-8"><title>Carte del Mostrometro</title><style>' + STILE + "</style>\n" + "\n".join(carte)
    out = os.path.join(QUI, "carte.html")
    open(out, "w", encoding="utf8").write(html)
    # elenco dei codici, per il firmware
    json.dump({str(i): codice(i) for i in range(1, len(AZIONI) + 1)}, open(os.path.join(QUI, "codici.json"), "w"), indent=0)
    print("scritto", out, "con", len(carte), "carte;", "esempio QR:", url(1))

if __name__ == "__main__":
    main()
