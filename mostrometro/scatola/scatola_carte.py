#!/usr/bin/env python3
"""Scatolina per le 100 carte (senza il Mostrometro di plastica: si gioca con l'app del telefono).
Due fogli A4 di cartoncino 200-250 g, stampabili a casa: 1) il fondo  2) il coperchio  3) il disegno con le misure.
Pareti doppie che si rimboccano dentro, come la scatola grande.
Uso:  python3 scatola_carte.py && node fai_pdf.js scatola_carte.html scatola_carte.pdf
"""
import os
import fustella as F                      # stessa rete con le pareti doppie (crea anche fustella.html, va bene)
from grafica import BASE, COP2, MASC

QUI = os.path.dirname(os.path.abspath(__file__))
A4 = (210, 297)
# carte 63 x 88, 100 carte su cartoncino 250 g = circa 30 mm
FONDO = (67, 92, 33)                      # dentro circa 66 x 91 x 33
COPERCHIO = (69.5, 94.5, 20)
LINGUETTA = 12

def rete_centrata(misure, alto=10):
    W, H, h = misure
    e = 2 * h - F.SPESSORE
    iw, ih = W + 2 * e, H + 2 * e
    return F.rete((A4[0] - iw) / 2, alto + (A4[1] - 22 - ih) / 2, W, H, h, LINGUETTA)

fon, cop = rete_centrata(FONDO), rete_centrata(COPERCHIO)

REGOLE = [
    "Apri l'app <b>Mostrometro</b> sul telefono e aggiungi i giocatori.",
    "All'inizio ognuno si misura: tocca il naso del mostro nell'app.",
    "Dai qualche carta a ognuno, senza farle vedere.",
    "Fai l'azione della carta davanti a tutti, senza avvisare.",
    "Scansiona il QR con l'app e scegli chi l'ha fatta: <b>+5</b>.",
    "A fine serata tutti si misurano di nuovo: chi è più in alto è il <b>Mostro della serata</b>!",
]

def lato(w, h, testo, piccolo=""):
    """Parete piccola: la scritta si adatta allo spazio; le mascotte solo se c'e' posto."""
    m = 0.66 * h
    con_mascotte = w - 2 * m - 8 >= len(testo) * 0.66 * h * 0.3
    spazio = w - (2 * m + 8 if con_mascotte else 6)
    fs = min(h * 0.36, spazio / (len(testo) * 0.68))
    img = f'<img class="m" src="{MASC}" alt="">' if con_mascotte else ""
    p = f'<div class="pic" style="font-size:{min(h * 0.09, fs * 0.4):.1f}mm">{piccolo}</div>' if piccolo else ""
    return (f'<div class="lato" style="justify-content:{"space-between" if con_mascotte else "center"}">{img}<div class="sc">'
            f'<div class="titolo" style="font-size:{fs:.1f}mm;white-space:nowrap">{testo}</div>{p}</div>{img}</div>')

def sopra(w, h):
    return f'''<div class="mc"><img src="{COP2}" alt=""><div class="mc-t"><div class="titolo">MOSTROMETRO</div>
  <div class="mc-s">100 carte · il gioco della serata</div></div></div>'''

def sotto(w, h):
    li = "".join(f"<li>{r}</li>" for r in REGOLE)
    return f'''<div class="mr"><div class="titolo" style="font-size:6.4mm">MOSTROMETRO</div><h3>Come si gioca</h3><ol>{li}</ol>
  <p>100 carte azione · si gioca con l'app per Android</p></div>'''

def pagina(rete_, grafiche, nome):
    t, p, _, (iw, ih) = rete_
    fw, fh = A4
    fondo = (f'<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">{F.PATTERN}'
             f'<path d="{t}" fill="#4a1fa8" stroke="#4a1fa8" stroke-width="4" stroke-linejoin="round"/><path d="{t}" fill="url(#pt)"/></svg>')
    linee = (f'<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">'
             f'<path d="{t}" fill="none" stroke="#000" stroke-width=".25"/>'
             f'<path d="{p}" fill="none" stroke="#fff" stroke-width=".3" stroke-dasharray="2.5 1.6"/></svg>')
    nota = (f'<div class="nota-f">Scatola delle carte · {nome} · aperto {iw:.0f} × {ih:.0f} mm · A4, stampa al 100% '
            '(«dimensione reale») su cartoncino 200–250 g · linea nera = taglia · tratteggio bianco = piega</div>')
    return f'<section class="foglio">{fondo}{"".join(grafiche)}{linee}{nota}</section>'

def foglio_fondo():
    _, _, pf, _ = fon; g = []
    x, y, w, h = pf["centro"]; g.append(F.posa(x, y, w, h, sotto(w, h)))
    x, y, w, h = pf["su"];  g.append(F.posa(x, y, w, h, lato(w, h, "MOSTROMETRO")))
    x, y, w, h = pf["giu"]; g.append(F.posa(x, y, w, h, lato(w, h, "MOSTROMETRO"), 180))
    x, y, w, h = pf["sx"];  g.append(F.posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), -90))
    x, y, w, h = pf["dx"];  g.append(F.posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), 90))
    return pagina(fon, g, "fondo")

def foglio_coperchio():
    _, _, pc, _ = cop; g = []
    x, y, w, h = pc["centro"]; g.append(F.posa(x, y, w, h, sopra(w, h)))
    x, y, w, h = pc["su"];  g.append(F.posa(x, y, w, h, lato(w, h, "100 CARTE"), 180))
    x, y, w, h = pc["giu"]; g.append(F.posa(x, y, w, h, lato(w, h, "100 CARTE")))
    x, y, w, h = pc["sx"];  g.append(F.posa(x, y, w, h, lato(h, w, "MOSTROMETRO"), 90))
    x, y, w, h = pc["dx"];  g.append(F.posa(x, y, w, h, lato(h, w, "MOSTROMETRO"), -90))
    return pagina(cop, g, "coperchio")

def foglio_misure():
    vw = 330
    righe = []
    y0 = 14
    for nome, (W, H, h), r in (("FONDO", FONDO, None), ("COPERCHIO", COPERCHIO, None)):
        e = 2 * h - F.SPESSORE; iw, ih = W + 2 * e, H + 2 * e
        t, p, pan, _ = F.rete((vw - iw) / 2, y0 + 10, W, H, h, LINGUETTA)
        x, y, w, hh = pan["centro"]; ox, oy = x - e, y - e
        righe.append(f'<path d="{t}" class="cut"/><path d="{p}" class="fold"/>')
        righe.append(f'<text x="{x + w / 2}" y="{y + hh / 2 - 6}" class="nome">{nome}</text>')
        righe.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 3}" class="dim">{W} × {H} mm</text>')
        righe.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 10}" class="dimp">parete {h} + rimbocco {h - F.SPESSORE} mm</text>')
        righe.append(F.quota(x, oy - 6, x + w, oy - 6, f"{W}"))
        righe.append(F.quota(ox - 6, y, ox - 6, y + hh, f"{H}"))
        righe.append(F.quota(ox, oy + ih + 7, ox + iw, oy + ih + 7, f"ingombro {iw:.0f}", -1))
        righe.append(F.quota(ox + iw + 7, oy, ox + iw + 7, oy + ih, f"ingombro {ih:.0f}", -1))
        y0 += ih + 34
    vh = y0 + 20
    return f'''<section class="foglio tecnico"><svg viewBox="0 0 {vw} {vh}" style="width:{A4[0]}mm;height:{A4[1]}mm">
  <defs><marker id="f" viewBox="0 0 6 6" refX="3" refY="3" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M0 0L6 3L0 6Z" fill="#555"/></marker></defs>
  {"".join(righe)}
  <text x="8" y="{vh - 12}" class="leg">Misure in mm (non in scala). Chiusa: circa {COPERCHIO[0] + 1} × {COPERCHIO[1] + 1} × {FONDO[2] + 1} mm. Dentro: 66 × 91 × 33 mm.</text>
</svg></section>'''

STILE = BASE + F.STILE.split("@page", 1)[1].split("}", 1)[1] + f'''
@page{{size:A4;margin:0}}
.foglio{{width:{A4[0]}mm;height:{A4[1]}mm}}
.nota-f{{font-size:2.4mm;bottom:5mm;padding:0 8mm}}
.mc{{position:absolute;inset:0;background:#3b1a7a}}
.mc img{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:50% 100%}}
.mc-t{{position:absolute;left:0;right:0;top:3.5mm;text-align:center}}
.mc .titolo{{font-size:7.4mm}}
.lato .m{{height:66%}}
.mc-s{{display:inline-block;margin-top:1.6mm;background:#fff;color:#4a1fa8;font-weight:600;font-size:2.7mm;padding:.6mm 2.6mm;border-radius:5mm}}
.mr{{position:absolute;inset:2.5mm;background:#fff6e6;border-radius:2mm;padding:3.5mm 3.5mm;color:#2b1650;text-align:center}}
.mr h3{{margin:1.6mm 0 1mm;font-size:3.6mm;color:#4a1fa8}}
.mr ol{{margin:0;padding-left:4mm;text-align:left;font-size:2.55mm;line-height:1.25}}
.mr li{{margin-bottom:1.1mm}}
.mr p{{margin:2mm 0 0;font-size:2.3mm;color:#6a5a86}}
'''
html = ('<!doctype html><meta charset="utf-8"><title>Scatola delle carte</title><style>' + STILE + "</style>\n"
        + foglio_fondo() + foglio_coperchio() + foglio_misure())
open(os.path.join(QUI, "scatola_carte.html"), "w", encoding="utf8").write(html)
print("fondo aperto", fon[3], "coperchio aperto", cop[3])
