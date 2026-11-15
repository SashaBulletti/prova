#!/usr/bin/env python3
"""La scatola del Mostrometro TUTTA IN UN PEZZO (fustella): coperchio e fondo stampati su due fogli 50 x 70 cm
di cartoncino, da ritagliare, piegare e incollare. Niente cartone piuma, niente etichette separate.

Crea fustella.html con 3 pagine 50 x 70 cm:
  1) il coperchio da stampare  2) il fondo da stampare  (grafica + linee di taglio continue e di piega tratteggiate)
  3) il disegno con tutte le misure (ingombri), comprese le pareti doppie che si rimboccano dentro
Poi:  node fai_pdf.js fustella.html scatola_fustella.pdf
"""
import os
from grafica import BASE, COP1, COP2, MASC

QUI = os.path.dirname(os.path.abspath(__file__))

# ---------- MISURE (mm) ----------
# Ogni parete e' DOPPIA: la parte esterna (con la grafica) e una parte interna che si rimbocca verso dentro
# sopra il bordo, cosi' il cartone tagliato non si vede e le alette degli angoli restano nascoste.
# Dentro il fondo resta 227 x 213 x 45: ci sta l'inserto (225,4 x 211,4 x 33) e sopra il bottone del naso.
FONDO = (229, 215, 45)            # pannello di base x profondita' x altezza delle pareti
COPERCHIO = (233, 219, 30)        # un po' piu' largo del fondo: si appoggia senza forzare
LINGUETTA = 15                    # alette da incollare negli angoli
RIENTRO = 1.5                     # la parte rimboccata e' un po' piu' corta per lato, cosi' entra negli angoli
SPESSORE = 1                      # e un po' piu' bassa, cosi' arriva giusta al fondo
FOGLIO = (500, 700)               # 50 x 70 cm, verticale: un foglio per il coperchio e uno per il fondo

def rete(ox, oy, W, H, h, t):
    """Scatola aperta con pareti doppie. Pannello centrale W x H; ogni parete: esterna alta h + rimbocco alto h - SPESSORE.
    Le 4 alette (t) stanno sulle pareti esterne di sinistra e destra e si incollano dentro le pareti accanto."""
    R, e = RIENTRO, 2 * h - SPESSORE
    A, B = ox + e, ox + e + W
    D, E = oy + e, oy + e + H
    taglio = (f"M{A + R} {oy}H{B - R}V{D - h}H{B}V{D - t}H{B + h - 6}L{B + h - 2} {D}H{B + h}V{D + R}H{B + e}V{E - R}H{B + h}V{E}"
              f"H{B + h - 2}L{B + h - 6} {E + t}H{B}V{E + h}H{B - R}V{E + e}H{A + R}V{E + h}H{A}V{E + t}H{A - h + 6}L{A - h + 2} {E}"
              f"H{A - h}V{E - R}H{ox}V{D + R}H{A - h}V{D}H{A - h + 2}L{A - h + 6} {D - t}H{A}V{D - h}H{A + R}Z"
              f"M{B} {D - t}V{D}M{A} {D - t}V{D}M{B} {E}V{E + t}M{A} {E}V{E + t}")          # 4 tagli tra aletta e parete
    piega = (f"M{A} {D}H{B}V{E}H{A}Z"                                                        # intorno al pannello centrale
             f"M{A + R} {D - h}H{B - R}M{A + R} {E + h}H{B - R}M{A - h} {D + R}V{E - R}M{B + h} {D + R}V{E - R}"  # bordo: rimbocco
             f"M{B} {D}H{B + h - 2}M{B} {E}H{B + h - 2}M{A - h + 2} {D}H{A}M{A - h + 2} {E}H{A}")   # le 4 alette
    pannelli = {
        "centro": (A, D, W, H),
        "su": (A, D - h, W, h), "giu": (A, E, W, h),
        "sx": (A - h, D, h, H), "dx": (B, D, h, H),
    }
    return taglio, piega, pannelli, (W + 2 * e, H + 2 * e)

def ingombro(misure):
    W, H, h = misure
    e = 2 * h - SPESSORE
    return W + 2 * e, H + 2 * e

def al_centro(misure, fw=FOGLIO[0], fh=FOGLIO[1]):
    iw, ih = ingombro(misure)
    return rete((fw - iw) / 2, (fh - ih) / 2 - 8, *misure, LINGUETTA)

cop = al_centro(COPERCHIO)
fon = al_centro(FONDO)

def posa(x, y, w, h, contenuto, giro=0):
    """Mette un riquadro grafico al centro del pannello (x, y, w, h), girato di 'giro' gradi.
    Se il giro e' 90 o -90 il contenuto e' disegnato lungo h e alto w, poi ruotato."""
    cw, ch = (h, w) if giro in (90, -90) else (w, h)
    return (f'<div class="posa" style="left:{x + w / 2}mm;top:{y + h / 2}mm;width:{cw}mm;height:{ch}mm;'
            f'transform:translate(-50%,-50%) rotate({giro}deg)">{contenuto}</div>')

def coperchio_sopra(w, h):
    return f'''<div class="cop"><img src="{COP2}" alt="">
  <div class="testa"><div class="titolo">MOSTROMETRO</div><div class="sotto">Il gioco di famiglia che misura la mostruosità</div></div>
  <div class="bollini"><span>100 carte</span><span>da 2 a 12 mostri</span><span>per tutta la famiglia</span></div></div>'''

def lato(w, h, testo, piccolo=""):
    m = f'<img class="m" src="{MASC}" alt="">'
    fs = min(h * 0.42, w / len(testo) * 1.25)
    p = f'<div class="pic" style="font-size:{h * 0.09:.1f}mm">{piccolo}</div>' if piccolo else ""
    return f'<div class="lato">{m}<div class="sc"><div class="titolo" style="font-size:{fs:.1f}mm">{testo}</div>{p}</div>{m}</div>'

def fondo_sotto(w, h):
    from regole import REGOLE as passi
    li = "".join(f"<li>{p}</li>" for p in passi)
    return f'''<div class="regole"><div class="col-img"><img src="{COP1}" alt=""></div><div class="col-txt">
  <div class="titolo" style="font-size:11mm">MOSTROMETRO</div><h3>Come si gioca</h3><ol>{li}</ol>
  <h3>Nella scatola</h3><p>1 Mostrometro · 100 carte azione · tanta mostruosità</p>
  <p class="nota">Il Mostrometro si ricarica con un cavo USB-C. Fatto in casa, con la stampante 3D.</p></div></div>'''

PATTERN = ('<defs><pattern id="pt" width="7" height="7" patternUnits="userSpaceOnUse"><circle cx="1.75" cy="1.75" r=".9" '
           'fill="#ffd84a" fill-opacity=".22"/><circle cx="5.25" cy="5.25" r=".7" fill="#fff" fill-opacity=".12"/></pattern></defs>')

def foglio_pezzo(rete_, grafiche, nome):
    t, p, _, (iw, ih) = rete_
    fw, fh = FOGLIO
    fondo = (f'<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">{PATTERN}'
             f'<path d="{t}" fill="#4a1fa8" stroke="#4a1fa8" stroke-width="5" stroke-linejoin="round"/><path d="{t}" fill="url(#pt)"/></svg>')
    linee = (f'<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">'
             f'<path d="{t}" fill="none" stroke="#000" stroke-width=".3"/>'
             f'<path d="{p}" fill="none" stroke="#fff" stroke-width=".35" stroke-dasharray="3 2"/></svg>')
    nota = (f'<div class="nota-f">Mostrometro · {nome} · aperto {iw:.0f} × {ih:.0f} mm · foglio {fw / 10:.0f} × {fh / 10:.0f} cm, '
            'stampa al 100% su cartoncino 300–350 g · linea nera = taglia · tratteggio bianco = piega</div>')
    return f'<section class="foglio">{fondo}{"".join(grafiche)}{linee}{nota}</section>'

def foglio_coperchio():
    _, _, pc, _ = cop
    g = []
    x, y, w, h = pc["centro"]; g.append(posa(x, y, w, h, coperchio_sopra(w, h)))
    # coperchio: le pareti si piegano in giu' -> la scritta guarda verso il pannello centrale
    x, y, w, h = pc["su"];  g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO"), 180))
    x, y, w, h = pc["giu"]; g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO")))
    x, y, w, h = pc["sx"];  g.append(posa(x, y, w, h, lato(h, w, "100 CARTE"), 90))
    x, y, w, h = pc["dx"];  g.append(posa(x, y, w, h, lato(h, w, "1 MOSTROMETRO"), -90))
    return foglio_pezzo(cop, g, "coperchio")

def foglio_fondo():
    _, _, pf, _ = fon
    g = []
    # fondo: le pareti si piegano in su -> la scritta guarda verso il bordo libero
    x, y, w, h = pf["centro"]; g.append(posa(x, y, w, h, fondo_sotto(w, h)))
    x, y, w, h = pf["su"];  g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO", "il gioco della serata")))
    x, y, w, h = pf["giu"]; g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO", "il gioco della serata"), 180))
    x, y, w, h = pf["sx"];  g.append(posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), -90))
    x, y, w, h = pf["dx"];  g.append(posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), 90))
    return foglio_pezzo(fon, g, "fondo")

def quota(x1, y1, x2, y2, testo, lato_testo=1):
    """Una linea di misura con le frecce e il numero."""
    mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    orizz = abs(y1 - y2) < 0.01
    tx, ty = (mx, my - 3.4 * lato_testo) if orizz else (mx - 3.6 * lato_testo, my)
    rot = "" if orizz else f' transform="rotate(-90 {tx} {ty})"'
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" class="q" marker-start="url(#f)" marker-end="url(#f)"/>'
            f'<text x="{tx}" y="{ty}"{rot} class="qt">{testo}</text>')

def foglio_tecnico():
    """I due pezzi uno sopra l'altro, in scala (il foglio e' piu' piccolo dei pezzi): contano i numeri."""
    vw = 480
    cw, ch = ingombro(COPERCHIO); bw, bh = ingombro(FONDO)
    vh = 40 + ch + 55 + bh + 50
    pezzi = [("COPERCHIO", COPERCHIO, rete((vw - cw) / 2, 40, *COPERCHIO, LINGUETTA)),
             ("FONDO", FONDO, rete((vw - bw) / 2, 40 + ch + 55, *FONDO, LINGUETTA))]
    parti = []
    for nome, (W, H, h), (t, p, pan, (iw, ih)) in pezzi:
        x, y, w, hh = pan["centro"]
        e = 2 * h - SPESSORE
        ox, oy = x - e, y - e
        parti.append(f'<path d="{t}" class="cut"/><path d="{p}" class="fold"/>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 - 8}" class="nome">{nome}</text>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 5}" class="dim">{W} × {H} mm</text>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 15}" class="dimp">parete {h} mm + rimbocco {h - SPESSORE} mm · alette {LINGUETTA} mm</text>')
        parti.append(quota(x, oy - 8, x + w, oy - 8, f"{W}"))
        parti.append(quota(ox, oy + ih + 9, ox + iw, oy + ih + 9, f"ingombro {iw:.0f}", -1))
        parti.append(quota(ox - 8, y, ox - 8, y + hh, f"{H}"))
        parti.append(quota(ox + iw + 9, oy, ox + iw + 9, oy + ih, f"ingombro {ih:.0f}", -1))
        # parete esterna e rimbocco, sul lato destro in alto
        parti.append(quota(x + w + 5, y - h, x + w + 5, y, f"{h}", -1))
        parti.append(quota(x + w + 5, oy, x + w + 5, y - h, f"{h - SPESSORE}", -1))
    fw, fh = FOGLIO
    chiusa = (f"Scatola chiusa: circa {COPERCHIO[0] + 1} × {COPERCHIO[1] + 1} × {FONDO[2] + 1} mm · "
              f"dentro: {FONDO[0] - 2} × {FONDO[1] - 2} × {FONDO[2]} mm · inserto: 225 × 211 × 33 mm")
    return f'''<section class="foglio tecnico"><svg viewBox="0 0 {vw} {vh}" style="width:{fw}mm;height:{fh}mm">
  <defs><marker id="f" viewBox="0 0 6 6" refX="3" refY="3" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M0 0L6 3L0 6Z" fill="#555"/></marker></defs>
  {"".join(parti)}
  <text x="10" y="{vh - 26}" class="leg">Disegno con le misure, in mm (non in scala: per tagliare usa le pagine 1 e 2). Linea continua = taglia · tratteggio = piega.</text>
  <text x="10" y="{vh - 14}" class="leg">{chiusa}</text>
</svg></section>'''

STILE = BASE + f'''
@page{{size:{FOGLIO[0]}mm {FOGLIO[1]}mm;margin:0}}
.foglio{{position:relative;width:{FOGLIO[0]}mm;height:{FOGLIO[1]}mm;overflow:hidden;page-break-after:always;break-after:page;background:#fff}}
.linee{{position:absolute;left:0;top:0}}
.posa{{position:absolute;overflow:hidden}}
.nota-f{{position:absolute;left:0;right:0;bottom:4mm;text-align:center;font-size:3.2mm;color:#777}}
.cop{{position:absolute;inset:0;background:#3b1a7a}}
.cop img{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:50% 100%}}
.cop .testa{{position:absolute;left:0;right:0;top:6mm;text-align:center}}
.cop .titolo{{font-size:27mm}}
.cop .sotto{{display:inline-block;margin-top:3.5mm;background:#fff;color:#4a1fa8;font-weight:600;font-size:6.4mm;padding:1.4mm 5.5mm;border-radius:10mm;box-shadow:0 1mm 0 #2b1650}}
.cop .bollini{{position:absolute;left:0;right:0;bottom:6mm;display:flex;justify-content:center;gap:3.5mm}}
.cop .bollini span{{background:#ffd84a;color:#2b1650;font-weight:700;font-size:4.6mm;padding:1.3mm 4mm;border-radius:8mm;box-shadow:0 .8mm 0 #2b1650}}
.lato{{position:absolute;inset:0;display:flex;align-items:center;justify-content:space-between;padding:0 3mm;color:#fff}}
.lato .m{{height:72%;aspect-ratio:1;border-radius:50%;border:.6mm solid #ffd84a;object-fit:cover;background:#fff6e6}}
.lato .sc{{text-align:center}}
.lato .pic{{font-weight:500;letter-spacing:.12em;text-transform:uppercase;margin-top:1mm}}
.regole{{position:absolute;inset:6mm;display:grid;grid-template-columns:86mm 1fr;gap:6mm;padding:7mm;background:#fff6e6;border-radius:3mm;align-items:center}}
.col-img img{{width:100%;aspect-ratio:4/5;object-fit:cover;object-position:50% 100%;border-radius:4mm;border:1mm solid #4a1fa8;display:block}}
.col-txt{{min-width:0;color:#2b1650}}
.col-txt h3{{margin:3mm 0 1.2mm;font-size:5.4mm;color:#4a1fa8}}
.col-txt ol{{margin:0;padding-left:5mm;font-size:3.8mm;line-height:1.28}}
.col-txt li{{margin-bottom:1.4mm}}
.col-txt p{{margin:0;font-size:3.8mm}}
.col-txt .nota{{margin-top:3mm;color:#6a5a86;font-size:3.1mm}}
.tecnico svg{{font-family:"Fredoka",sans-serif}}
.cut{{fill:#f6f2fb;stroke:#222;stroke-width:.5}}
.fold{{fill:none;stroke:#6a35d9;stroke-width:.45;stroke-dasharray:3 2}}
.q{{stroke:#555;stroke-width:.3}}
.qt{{font-size:5.2px;fill:#333;text-anchor:middle;dominant-baseline:middle}}
.nome{{font-size:12px;font-weight:700;fill:#4a1fa8;text-anchor:middle}}
.dim{{font-size:9px;font-weight:600;fill:#222;text-anchor:middle}}
.dimp{{font-size:5.6px;fill:#555;text-anchor:middle}}
.leg{{font-size:6px;fill:#444}}
'''

html = ('<!doctype html><meta charset="utf-8"><title>Scatola in un pezzo</title><style>' + STILE + "</style>\n"
        + foglio_coperchio() + "\n" + foglio_fondo() + "\n" + foglio_tecnico())
open(os.path.join(QUI, "fustella.html"), "w", encoding="utf8").write(html)
print("coperchio aperto", cop[3], "fondo aperto", fon[3])
