#!/usr/bin/env python3
"""La scatola del Mostrometro TUTTA IN UN PEZZO (fustella): coperchio e fondo stampati su un foglio 50 x 70 cm
di cartoncino, da ritagliare, piegare e incollare. Niente cartone piuma, niente etichette separate.

Crea fustella.html con 2 pagine 50 x 70 cm:
  1) il foglio da stampare: grafica + linee di taglio (continue) e di piega (tratteggiate)
  2) il disegno tecnico con tutte le misure (ingombri)
Poi:  node fai_pdf.js fustella.html scatola_fustella.pdf
"""
import os
from grafica import BASE, COP1, COP2, MASC

QUI = os.path.dirname(os.path.abspath(__file__))

# ---------- MISURE (mm) ----------
# Dentro il fondo ci sta l'inserto (225,4 x 211,4 x 33) e sopra resta spazio per il bottone del naso.
FONDO = (227, 213, 45)            # base x profondita' x altezza delle pareti
COPERCHIO = (230, 216, 30)        # 1,5 mm di gioco per lato intorno al fondo: si appoggia senza forzare
LINGUETTA = 15                    # alette da incollare negli angoli
FOGLIO = (500, 700)               # 50 x 70 cm, verticale
MARGINE = 12

def rete(ox, oy, W, H, h, t):
    """Coordinate di una scatola aperta: pannello centrale W x H, 4 pareti alte h, 4 alette t sulle pareti di sinistra/destra."""
    A, B, C = ox + h, ox + h + W, ox + 2 * h + W
    D, E, F = oy + h, oy + h + H, oy + 2 * h + H
    taglio = (f"M{A} {oy}H{B}V{D - t}L{C - 6} {D - t}L{C - 2} {D}H{C}V{E}H{C - 2}L{C - 6} {E + t}H{B}V{F}H{A}"
              f"V{E + t}H{ox + 6}L{ox + 2} {E}H{ox}V{D}H{ox + 2}L{ox + 6} {D - t}H{A}Z"
              f"M{B} {D - t}V{D}M{A} {D - t}V{D}M{B} {E}V{E + t}M{A} {E}V{E + t}")       # 4 tagli tra aletta e parete
    piega = (f"M{A} {D}H{B}V{E}H{A}Z"                                                     # intorno al pannello centrale
             f"M{B} {D}H{C - 2}M{B} {E}H{C - 2}M{ox + 2} {D}H{A}M{ox + 2} {E}H{A}")         # le 4 alette
    pannelli = {
        "centro": (A, D, W, H),
        "su": (A, oy, W, h), "giu": (A, E, W, h),
        "sx": (ox, D, h, H), "dx": (B, D, h, H),
    }
    ingombro = (2 * h + W, 2 * h + H)
    return taglio, piega, pannelli, ingombro

CW, CH, Ch = COPERCHIO
FW, FH, Fh = FONDO
cop_w, cop_h = CW + 2 * Ch, CH + 2 * Ch
fon_w, fon_h = FW + 2 * Fh, FH + 2 * Fh
spazio = (FOGLIO[1] - 2 * MARGINE - cop_h - fon_h) / 3
cop = rete((FOGLIO[0] - cop_w) / 2, MARGINE + spazio, CW, CH, Ch, LINGUETTA)
fon = rete((FOGLIO[0] - fon_w) / 2, MARGINE + 2 * spazio + cop_h, FW, FH, Fh, LINGUETTA)

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
    passi = [
        "Collega il telefono al WiFi <b>Mostrometro</b> (password <b>mostro1234</b>) e aggiungi i giocatori nell'app.",
        "Mescola le carte e danne qualcuna a ognuno, senza farle vedere.",
        "Durante la serata fai l'azione della carta, davanti a tutti, senza avvisare.",
        "Scansiona il QR della carta e scegli chi l'ha fatta: +5 di mostruosità. Ogni carta vale una volta.",
        "Premi il naso del Mostrometro: il mercurio sale. Chi arriva più in alto è il Mostro della serata!",
    ]
    li = "".join(f"<li>{p}</li>" for p in passi)
    return f'''<div class="regole"><div class="col-img"><img src="{COP1}" alt=""></div><div class="col-txt">
  <div class="titolo" style="font-size:11mm">MOSTROMETRO</div><h3>Come si gioca</h3><ol>{li}</ol>
  <h3>Nella scatola</h3><p>1 Mostrometro · 100 carte azione · tanta mostruosità</p>
  <p class="nota">Il Mostrometro si ricarica con un cavo USB-C. Fatto in casa, con la stampante 3D.</p></div></div>'''

def foglio_stampa():
    t1, p1, pc, _ = cop
    t2, p2, pf, _ = fon
    g = []
    x, y, w, h = pc["centro"]; g.append(posa(x, y, w, h, coperchio_sopra(w, h)))
    # coperchio: le pareti si piegano in giu' -> la scritta guarda verso il pannello centrale
    x, y, w, h = pc["su"];  g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO"), 180))
    x, y, w, h = pc["giu"]; g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO")))
    x, y, w, h = pc["sx"];  g.append(posa(x, y, w, h, lato(h, w, "100 CARTE"), 90))
    x, y, w, h = pc["dx"];  g.append(posa(x, y, w, h, lato(h, w, "1 MOSTROMETRO"), -90))
    # fondo: le pareti si piegano in su -> la scritta guarda verso il bordo libero
    x, y, w, h = pf["centro"]; g.append(posa(x, y, w, h, fondo_sotto(w, h)))
    x, y, w, h = pf["su"];  g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO", "il gioco della serata")))
    x, y, w, h = pf["giu"]; g.append(posa(x, y, w, h, lato(w, h, "MOSTROMETRO", "il gioco della serata"), 180))
    x, y, w, h = pf["sx"];  g.append(posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), -90))
    x, y, w, h = pf["dx"];  g.append(posa(x, y, w, h, lato(h, w, "MOSTROMETRO", "100 carte"), 90))
    fw, fh = FOGLIO
    svg = f'''<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">
  <defs><pattern id="pt" width="7" height="7" patternUnits="userSpaceOnUse"><circle cx="1.75" cy="1.75" r=".9" fill="#ffd84a" fill-opacity=".22"/><circle cx="5.25" cy="5.25" r=".7" fill="#fff" fill-opacity=".12"/></pattern></defs>
  <g fill="#4a1fa8" stroke="#4a1fa8" stroke-width="5" stroke-linejoin="round"><path d="{t1}"/><path d="{t2}"/></g>
  <g fill="url(#pt)"><path d="{t1}"/><path d="{t2}"/></g>
</svg>'''
    linee = f'''<svg class="linee" viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">
  <g fill="none" stroke="#000" stroke-width=".3"><path d="{t1}"/><path d="{t2}"/></g>
  <g fill="none" stroke="#fff" stroke-width=".35" stroke-dasharray="3 2"><path d="{p1}"/><path d="{p2}"/></g>
</svg>'''
    nota = (f'<div class="nota-f">Mostrometro · scatola in un pezzo · foglio {fw / 10:.0f} × {fh / 10:.0f} cm, stampa al 100% su cartoncino 300–350 g · '
            'linea continua = taglia · tratteggio bianco = piega</div>')
    return f'<section class="foglio">{svg}{"".join(g)}{linee}{nota}</section>'

def quota(x1, y1, x2, y2, testo, lato_testo=1):
    """Una linea di misura con le frecce e il numero."""
    mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    orizz = abs(y1 - y2) < 0.01
    tx, ty = (mx, my - 2.2 * lato_testo) if orizz else (mx - 2.5 * lato_testo, my)
    rot = "" if orizz else f' transform="rotate(-90 {tx} {ty})"'
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" class="q" marker-start="url(#f)" marker-end="url(#f)"/>'
            f'<text x="{tx}" y="{ty}"{rot} class="qt">{testo}</text>')

def foglio_tecnico():
    fw, fh = FOGLIO
    parti = []
    for nome, (t, p, pan, (iw, ih)), (W, H, h) in (("COPERCHIO", cop, COPERCHIO), ("FONDO", fon, FONDO)):
        x, y, w, hh = pan["centro"]
        ox, oy = x - h, y - h
        parti.append(f'<path d="{t}" class="cut"/><path d="{p}" class="fold"/>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 - 6}" class="nome">{nome}</text>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 4}" class="dim">{W} × {H} mm</text>')
        parti.append(f'<text x="{x + w / 2}" y="{y + hh / 2 + 12}" class="dimp">pareti alte {h} mm · alette {LINGUETTA} mm</text>')
        parti.append(quota(x, oy - 6, x + w, oy - 6, f"{W}"))
        parti.append(quota(ox, oy + ih + 7, ox + iw, oy + ih + 7, f"ingombro {iw}", -1))
        parti.append(quota(ox - 6, y, ox - 6, y + hh, f"{H}"))
        parti.append(quota(ox + iw + 7, oy, ox + iw + 7, oy + ih, f"ingombro {ih}", -1))
        parti.append(quota(x + w + 4, oy, x + w + 4, y, f"{h}", -1))
    chiusa = (f"Scatola chiusa: {COPERCHIO[0] + 1} × {COPERCHIO[1] + 1} × {FONDO[2] + 1} mm circa · "
              f"dentro: {FONDO[0]} × {FONDO[1]} × {FONDO[2]} mm · inserto: 225 × 211 × 33 mm")
    return f'''<section class="foglio tecnico"><svg viewBox="0 0 {fw} {fh}" style="width:{fw}mm;height:{fh}mm">
  <defs><marker id="f" viewBox="0 0 6 6" refX="3" refY="3" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M0 0L6 3L0 6Z" fill="#555"/></marker></defs>
  {"".join(parti)}
  <text x="{MARGINE}" y="{fh - 16}" class="leg">Disegno tecnico, misure in mm. Linea continua = taglia · tratteggio = piega.</text>
  <text x="{MARGINE}" y="{fh - 9}" class="leg">{chiusa}</text>
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
.qt{{font-size:4.2px;fill:#333;text-anchor:middle;dominant-baseline:middle}}
.nome{{font-size:9px;font-weight:700;fill:#4a1fa8;text-anchor:middle}}
.dim{{font-size:7px;font-weight:600;fill:#222;text-anchor:middle}}
.dimp{{font-size:4.5px;fill:#555;text-anchor:middle}}
.leg{{font-size:4.6px;fill:#444}}
'''

html = ('<!doctype html><meta charset="utf-8"><title>Scatola in un pezzo</title><style>' + STILE + "</style>\n"
        + foglio_stampa() + "\n" + foglio_tecnico())
open(os.path.join(QUI, "fustella.html"), "w", encoding="utf8").write(html)
print("coperchio aperto", cop[3], "fondo aperto", fon[3], "spazio tra i pezzi", round(spazio, 1), "mm")
