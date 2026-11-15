#!/usr/bin/env python3
"""Disegna la pianta del retro del mostro tondo (forma A) per progetto.html, con le misure di mostrometro.scad.
Uso: python3 pianta_A.py fuori.svg dentro.svg  (le due sagome esportate da OpenSCAD: esterna e interna)
Stampa l'<svg> da mettere nella guida. Scala: 1 mm = 2 unita'."""
import re, sys

def percorso(f):
    d = re.search(r'd="([^"]+)"', open(f).read()).group(1)
    pts = re.findall(r"(-?[\d.]+),(-?[\d.]+)", d)
    return "M" + " L".join(f"{float(x):.2f},{float(y):.2f}" for x, y in pts) + "Z"

FUORI, DENTRO = percorso(sys.argv[1]), percorso(sys.argv[2])

# misure della forma A (mm, origine in basso al centro) da mostrometro.scad
top_y = 180; win_cy = 90; win_w, win_h = 22.9, 84.4
brd_w, brd_l = 29.0, 95.1
btn_y, btn_d = 28, 24.2
bat_w, bat_l, bat_cy = 34, 50, win_cy - 24.5
spk_d, spk_y = 28, top_y - 22
mic_x, mic_y = 12.5, win_cy + 2.65
posts = [(-44, win_cy + 13), (44, win_cy + 13), (-22, top_y - 22), (22, top_y - 22)]
usb_w = 12

CX, BASE, K = 320, 440, 2
X = lambda x: CX + K * x
Y = lambda y: BASE - K * y

def rect(cx, cy, w, h, **a):
    att = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in a.items())
    return f'<rect x="{X(cx - w / 2):.1f}" y="{Y(cy + h / 2):.1f}" width="{K * w:.1f}" height="{K * h:.1f}" {att}/>'

def cerchio(cx, cy, d, **a):
    att = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in a.items())
    return f'<circle cx="{X(cx):.1f}" cy="{Y(cy):.1f}" r="{K * d / 2:.1f}" {att}/>'

T = f'transform="translate({CX},{BASE}) scale({K})"'
p = []
p.append(f'<path {T} d="{FUORI}" fill="var(--tube)" stroke="var(--ink)" stroke-width="3" vector-effect="non-scaling-stroke" stroke-linejoin="round"/>')
p.append(f'<path {T} d="{DENTRO}" fill="var(--panel)"/>')
for x, y in posts:
    p.append(cerchio(x, y, 7, fill="var(--tube)", stroke="var(--ink)", stroke_width="2"))
p.append(cerchio(0, spk_y, spk_d, fill="var(--ink)", fill_opacity=".14", stroke="var(--ink)", stroke_width="2"))
p.append(cerchio(0, spk_y, 21, fill="none", stroke="var(--ink)", stroke_opacity=".5", stroke_width="1.5", stroke_dasharray="2 5"))
p.append(rect(0, bat_cy, bat_w, bat_l, rx="2", fill="var(--warn)", fill_opacity=".3", stroke="var(--warn)", stroke_width="2"))
p.append(rect(0, win_cy, brd_w, brd_l, rx="2", fill="var(--scale)", fill_opacity=".22", stroke="var(--scale)", stroke_width="2"))
p.append(rect(0, win_cy, win_w, win_h, rx="6", fill="none", stroke="var(--scale)", stroke_width="1.5", stroke_dasharray="5 4"))
for s in (-1, 1):
    p.append(cerchio(s * mic_x, mic_y, 4, fill="var(--bg)", stroke="var(--ink)", stroke_width="1.5"))
p.append(cerchio(0, btn_y, 28, fill="var(--mercury)", fill_opacity=".25", stroke="var(--mercury)", stroke_width="2"))
p.append(cerchio(0, btn_y, 33, fill="none", stroke="var(--mute)", stroke_width="1.5", stroke_dasharray="5 4"))
p.append(rect(0, top_y - 1.2, usb_w, 2.4, fill="var(--ink)"))

# richiami: a destra (x >= 480) e a sinistra (x <= 170)
R, L = 480, 10
def a_destra(y, xa, titolo, sotto):
    return (f'<path d="M{xa:.1f} {y:.1f}H{R - 5}"/>', f'<text x="{R}" y="{y - 4:.1f}" class="b">{titolo}</text><text x="{R}" y="{y + 12:.1f}" class="s">{sotto}</text>')
def a_sinistra(y, xa, titolo, sotto):
    return (f'<path d="M150 {y:.1f}H{xa:.1f}"/>', f'<text x="{L}" y="{y - 4:.1f}" class="b">{titolo}</text><text x="{L}" y="{y + 12:.1f}" class="s">{sotto}</text>')

righe = [
    a_destra(Y(spk_y), X(14), "Altoparlante", "Ø28 mm, griglia sul retro"),
    a_destra(Y(win_cy + 30), X(14.5), "Scheda + schermo", "29 × 95 mm"),
    a_destra(Y(bat_cy - 12), X(17), "Batteria", "34 × 50 mm, dietro la scheda"),
    a_destra(Y(btn_y), X(14), "Bottone", "corpo 21 mm, in basso"),
    a_sinistra(Y(posts[2][1]), X(-25.5), "Piantoni viti", "Ø7 mm, ce ne sono 4"),
    a_sinistra(Y(mic_y), X(-14.5), "Fori microfoni", "Ø3 mm, sul retro"),
]
linee = "".join(r[0] for r in righe) + f'<path d="M{X(6):.1f} {Y(top_y) - 2:.1f}L{R - 5} {Y(top_y) - 22:.1f}"/>'
testi = "".join(r[1] for r in righe) + f'<text x="{R}" y="{Y(top_y) - 18:.1f}" class="s">presa USB-C, in cima</text>'

svg = (f'<svg viewBox="0 0 640 470" role="img" aria-label="Pianta del retro aperto del mostro tondo con la posizione di scheda, schermo, batteria, altoparlante, microfoni, bottone e viti">\n      '
       + "\n      ".join(p)
       + f'\n      <g stroke="var(--mute)" stroke-width="1.2" fill="none">{linee}</g>\n      {testi}\n'
       + '      <text x="10" y="462" class="s">Larghezza 142 mm con le braccia · altezza 203 mm con le corna · profondità 30 mm</text>\n    </svg>')
print(svg)
