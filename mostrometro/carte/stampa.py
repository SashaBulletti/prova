#!/usr/bin/env python3
"""Crea stampa.html: le 100 carte impaginate su fogli A4, 9 per foglio (3 x 3), con i segni per tagliare.
Poi fai_pdf.js lo trasforma in carte_da_stampare.pdf.
Stampa al 100% (dimensione reale, NON "adatta alla pagina"): ogni carta viene 63 x 88 mm.
"""
import os
from azioni import AZIONI
from genera_carte import carta_html, STILE, QUI

W, H = 63, 88                     # mm, carta
MX, MY = (210 - 3 * W) / 2, (297 - 3 * H) / 2   # margini del foglio

def disegno(i):
    for ext in ("png", "jpg"):
        p = os.path.join(QUI, "disegni", f"{i:03d}.{ext}")
        if os.path.exists(p):
            return p
    return None

carte = [carta_html(i, g, t, c, disegno(i), e) for i, (g, t, c, e) in enumerate(AZIONI, start=1)]

def segni():
    """Trattini fuori dalla griglia, in corrispondenza di ogni taglio."""
    s = []
    for k in range(4):
        x, y = MX + k * W, MY + k * H
        s.append(f'<i class="v" style="left:{x}mm;top:{MY - 7}mm"></i><i class="v" style="left:{x}mm;top:{MY + 3 * H + 2}mm"></i>')
        s.append(f'<i class="o" style="top:{y}mm;left:{MX - 7}mm"></i><i class="o" style="top:{y}mm;left:{MX + 3 * W + 2}mm"></i>')
    return "".join(s)

fogli = []
for f in range(0, len(carte), 9):
    gruppo = carte[f:f + 9]
    fogli.append(f'<section class="foglio">{segni()}<div class="griglia">{"".join(gruppo)}</div>'
                 f'<div class="nota">Mostrometro · foglio {f // 9 + 1} di {(len(carte) + 8) // 9} · stampa al 100%, poi taglia lungo i segni</div></section>')

PAGINA = STILE + f'''
@page{{size:A4;margin:0}}
body{{display:block;padding:0;background:#fff;-webkit-print-color-adjust:exact;print-color-adjust:exact}}
.foglio{{position:relative;width:210mm;height:297mm;overflow:hidden;page-break-after:always;break-after:page}}
.griglia{{position:absolute;left:{MX}mm;top:{MY}mm;display:grid;grid-template-columns:repeat(3,{W}mm);grid-auto-rows:{H}mm}}
.carta{{border-radius:0;box-shadow:none}}
.v,.o{{position:absolute;background:#000}} .v{{width:.2mm;height:5mm}} .o{{height:.2mm;width:5mm}}
.nota{{position:absolute;left:0;right:0;bottom:4mm;text-align:center;font-size:2.6mm;color:#888}}
'''
html = '<!doctype html><meta charset="utf-8"><title>Carte da stampare</title><style>' + PAGINA + "</style>\n" + "\n".join(fogli)
open(os.path.join(QUI, "stampa.html"), "w", encoding="utf8").write(html)
print("scritto stampa.html:", len(fogli), "fogli,", sum(1 for i in range(1, 101) if disegno(i)), "carte con disegno")
