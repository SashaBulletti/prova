#!/usr/bin/env python3
"""Grafica della scatola del Mostrometro, pronta da stampare:
  scatola_A3.html -> etichetta del coperchio (246 x 232 mm)              -> stampa su A3
  scatola_A4.html -> 1) i 4 lati del coperchio  2) i 4 lati del fondo  3) l'etichetta sotto la scatola
Poi:  node fai_pdf.js scatola_A3.html scatola_A3.pdf A3  e  node fai_pdf.js scatola_A4.html scatola_A4.pdf A4
Le misure vengono dalla scatola in cartone piuma da 5 mm descritta nella guida (vedi MISURE qui sotto).
"""
import base64, io, os
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
CARTE = os.path.join(QUI, "..", "carte")

# ---------- MISURE (mm) ----------
INTERNO = (227, 213, 45)          # dentro la scatola: ci sta l'inserto (225,4 x 211,4 x 33) + il bottone del naso
S = 5                              # spessore del cartone piuma
FONDO_EST = (INTERNO[0] + 2 * S, INTERNO[1] + 2 * S, INTERNO[2] + S)          # 237 x 223 x 50
COP_INT = (FONDO_EST[0] + 1, FONDO_EST[1] + 1)                                # 238 x 224
COP_EST = (COP_INT[0] + 2 * S, COP_INT[1] + 2 * S, 30)                        # 248 x 234 x 30
# etichette: 1 mm piu' piccole per lato, cosi' non sbordano
ETI_COP = (COP_EST[0] - 2, COP_EST[1] - 2)                 # 246 x 232
LATI_COP = [(COP_EST[0] - 2, 28)] * 2 + [(COP_EST[1] - 2, 28)] * 2
LATI_FONDO = [(FONDO_EST[0] - 2, 40)] * 2 + [(FONDO_EST[1] - 2, 40)] * 2   # incollati dal basso: il coperchio copre la parte alta
ETI_SOTTO = (220, 190)

def jpg(path, lato=None, q=88):
    im = Image.open(path).convert("RGB")
    if lato:
        im = im.resize((lato, lato), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, "JPEG", quality=q)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

FONT = "data:font/ttf;base64," + base64.b64encode(open(os.path.join(CARTE, "font", "Fredoka.ttf"), "rb").read()).decode()
COP2 = jpg(os.path.join(QUI, "grafica", "cop2.png"))
def jpg_senza_cielo(path):     # toglie la fascia vuota in alto (era lo spazio per il titolo)
    im = Image.open(path).convert("RGB"); w, h = im.size
    b = io.BytesIO(); im.crop((0, int(h * 0.22), w, h)).save(b, "JPEG", quality=88)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()
COP1 = jpg_senza_cielo(os.path.join(QUI, "grafica", "cop1.png"))
MASC = jpg(os.path.join(QUI, "..", "mascotte", "mascotte_in_piedi.jpg"), 500)

BASE = f'''@font-face{{font-family:"Fredoka";src:url("{FONT}") format("truetype");font-weight:300 700}}
*{{box-sizing:border-box}}
body{{margin:0;font-family:"Fredoka",sans-serif;color:#2b1650;-webkit-print-color-adjust:exact;print-color-adjust:exact}}
.foglio{{position:relative;page-break-after:always;break-after:page;overflow:hidden;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:9mm}}
.taglio{{position:relative;outline:.25mm dashed #999;outline-offset:2mm}}
.istr{{font-size:3mm;color:#777;text-align:center}}
.viola{{background:#4a1fa8;color:#fff;
  background-image:radial-gradient(circle at 25% 25%,rgba(255,216,74,.22) 0 .9mm,transparent 1mm),radial-gradient(circle at 75% 75%,rgba(255,255,255,.12) 0 .7mm,transparent .8mm);
  background-size:7mm 7mm}}
.titolo{{font-weight:700;color:#ffd84a;letter-spacing:.02em;line-height:.9;
  text-shadow:0 .9mm 0 #2b1650,.6mm 0 0 #2b1650,-.6mm 0 0 #2b1650,0 -.6mm 0 #2b1650}}
'''

def coperchio():
    w, h = ETI_COP
    return f'''<section class="foglio" style="width:297mm;height:420mm">
<div class="istr">Etichetta del coperchio · {w} × {h} mm · stampa al 100% su A3, ritaglia lungo il tratteggio e incolla sopra il coperchio</div>
<div class="taglio cop" style="width:{w}mm;height:{h}mm">
  <img src="{COP2}" alt="">
  <div class="testa"><div class="titolo">MOSTROMETRO</div><div class="sotto">Il gioco di famiglia che misura la mostruosità</div></div>
  <div class="bollini"><span>100 carte</span><span>da 2 a 12 mostri</span><span>per tutta la famiglia</span></div>
</div></section>'''

STILE_COP = '''
.cop{overflow:hidden;background:#3b1a7a}
.cop img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:50% 100%}
.cop .testa{position:absolute;left:0;right:0;top:7mm;text-align:center}
.cop .titolo{font-size:30mm}
.cop .sotto{display:inline-block;margin-top:4mm;background:#fff;color:#4a1fa8;font-weight:600;font-size:7mm;padding:1.6mm 6mm;border-radius:10mm;box-shadow:0 1mm 0 #2b1650}
.cop .bollini{position:absolute;left:0;right:0;bottom:6mm;display:flex;justify-content:center;gap:4mm}
.cop .bollini span{background:#ffd84a;color:#2b1650;font-weight:700;font-size:5mm;padding:1.4mm 4.5mm;border-radius:8mm;box-shadow:0 .8mm 0 #2b1650}
'''

def striscia(w, h, testo, piccolo, alto):
    m = f'<img class="m" src="{MASC}" alt="">'
    return f'''<div class="taglio striscia viola" style="width:{w}mm;height:{h}mm">
  {m}<div class="sc"><div class="titolo" style="font-size:{h * (0.36 if alto else 0.5)}mm">{testo}</div>
  {f'<div class="pic">{piccolo}</div>' if piccolo else ''}</div>{m}</div>'''

STILE_STRISCE = '''
.striscia{display:flex;align-items:center;justify-content:space-between;padding:0 3mm}
.striscia .m{height:80%;aspect-ratio:1;border-radius:50%;border:.6mm solid #ffd84a;object-fit:cover;background:#fff6e6}
.striscia .sc{text-align:center}
.striscia .pic{font-size:3.6mm;font-weight:500;letter-spacing:.12em;text-transform:uppercase;margin-top:1.2mm}
.strisce{display:flex;flex-direction:column;gap:6mm;align-items:center}
'''

def lati_coperchio():
    testi = [("MOSTROMETRO", ""), ("MOSTROMETRO", ""), ("100 CARTE", ""), ("1 MOSTROMETRO", "")]
    s = "".join(striscia(w, h, t, p, False) for (w, h), (t, p) in zip(LATI_COP, testi))
    return f'''<section class="foglio" style="width:297mm;height:210mm">
<div class="istr">I 4 lati del coperchio · 2 da {LATI_COP[0][0]} mm e 2 da {LATI_COP[2][0]} mm, alti {LATI_COP[0][1]} mm</div>
<div class="strisce">{s}</div></section>'''

def lati_fondo():
    testi = [("MOSTROMETRO", "il gioco della serata")] * 2 + [("MOSTROMETRO", "100 carte")] * 2
    s = "".join(striscia(w, h, t, p, True) for (w, h), (t, p) in zip(LATI_FONDO, testi))
    return f'''<section class="foglio" style="width:297mm;height:210mm">
<div class="istr">I 4 lati del fondo · 2 da {LATI_FONDO[0][0]} mm e 2 da {LATI_FONDO[2][0]} mm, alti {LATI_FONDO[0][1]} mm</div>
<div class="strisce">{s}</div></section>'''

def sotto():
    w, h = ETI_SOTTO
    passi = [
        "Collega il telefono al WiFi <b>Mostrometro</b> (password <b>mostro1234</b>) e aggiungi i giocatori nell'app.",
        "Mescola le carte e danne qualcuna a ognuno, senza farle vedere.",
        "Durante la serata fai l'azione della carta, davanti a tutti, senza avvisare.",
        "Scansiona il QR della carta, scegli chi l'ha fatta: +5 di mostruosità. Ogni carta vale una volta.",
        "Premi il naso del Mostrometro: il mercurio sale. Chi arriva più in alto è il Mostro della serata!",
    ]
    li = "".join(f"<li>{p}</li>" for p in passi)
    return f'''<section class="foglio" style="width:297mm;height:210mm">
<div class="istr">Etichetta per sotto la scatola · {w} × {h} mm</div>
<div class="taglio retro-sc" style="width:{w}mm;height:{h}mm">
  <div class="col-img"><img src="{COP1}" alt=""></div>
  <div class="col-txt">
    <div class="titolo" style="font-size:12mm">MOSTROMETRO</div>
    <h3>Come si gioca</h3><ol>{li}</ol>
    <h3>Nella scatola</h3>
    <p>1 Mostrometro · 100 carte azione · tanta mostruosità</p>
    <p class="nota">Il Mostrometro si ricarica con un cavo USB-C. Fatto in casa, con la stampante 3D.</p>
  </div>
</div></section>'''

STILE_SOTTO = '''
.retro-sc{display:grid;grid-template-columns:92mm 1fr;gap:7mm;padding:8mm;align-items:center;background:#fff6e6;border-radius:2mm}
.col-img img{width:100%;aspect-ratio:4/5;object-fit:cover;object-position:50% 100%;border-radius:4mm;border:1mm solid #4a1fa8;display:block}
.col-txt{min-width:0}
.col-txt h3{margin:4mm 0 1.5mm;font-size:6mm;color:#4a1fa8}
.col-txt ol{margin:0;padding-left:5mm;font-size:4.2mm;line-height:1.3}
.col-txt li{margin-bottom:1.8mm}
.col-txt p{margin:0;font-size:4.2mm}
.col-txt .nota{margin-top:4mm;color:#6a5a86;font-size:3.4mm}
'''

def pagina(titolo, fogli, formato, stile):
    return (f'<!doctype html><meta charset="utf-8"><title>{titolo}</title><style>@page{{size:{formato};margin:0}}'
            + BASE + stile + "</style>\n" + "\n".join(fogli))

if __name__ == "__main__":
    open(os.path.join(QUI, "scatola_A3.html"), "w", encoding="utf8").write(pagina("Coperchio", [coperchio()], "A3", STILE_COP))
    open(os.path.join(QUI, "scatola_A4.html"), "w", encoding="utf8").write(
        pagina("Lati e fondo", [lati_coperchio(), lati_fondo(), sotto()], "A4 landscape", STILE_STRISCE + STILE_SOTTO))

    print("fondo esterno", FONDO_EST, "coperchio esterno", COP_EST)
    print("etichetta coperchio", ETI_COP, "lati coperchio", LATI_COP, "lati fondo", LATI_FONDO)
