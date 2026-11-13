#!/usr/bin/env python3
"""Crea lista.html: la carta di prova e l'elenco delle 100 azioni, da rivedere prima di generare tutte le carte.
Uso: python3 pagina_lista.py PERCORSO_PNG_CARTA_1
"""
import base64, html, io, os, sys
from PIL import Image
from azioni import GRUPPI, PUNTI_CARTA

QUI = os.path.dirname(os.path.abspath(__file__))
COLORI = {
    "Rumori a tavola": "#7a4fe0", "Versi da mostro": "#e0533f", "Facce e gesti": "#e09a1f",
    "Dispetti innocui": "#2f9e6e", "Parole e frasi": "#2f7fd0", "Movimento e ballo": "#d04f9c",
    "Cibo da mostro": "#c7781a", "A sorpresa": "#5a5ad6",
}

im = Image.open(sys.argv[1]).convert("RGB")
buf = io.BytesIO(); im.save(buf, "JPEG", quality=86)
carta = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
font = "data:font/ttf;base64," + base64.b64encode(open(os.path.join(QUI, "font", "Fredoka.ttf"), "rb").read()).decode()

gruppi_html = []
n = 0
for gruppo, carte in GRUPPI.items():
    righe = []
    for titolo, come in carte:
        n += 1
        righe.append(f'<li><span class="n">{n:03d}</span><span class="t"><b>{html.escape(titolo)}</b>'
                     f'<small>{html.escape(come)}</small></span></li>')
    gruppi_html.append(f'<section class="gruppo" style="--g:{COLORI[gruppo]}"><h3>{html.escape(gruppo)}'
                       f' <span>{len(carte)} carte</span></h3><ol>{"".join(righe)}</ol></section>')

pagina = f'''<title>Carte del Mostrometro</title>
<meta name="claude:viewport-fit-sides" content="cover">
<style>
/* Layout: in alto la carta di prova accanto alle regole, sotto le 100 azioni divise per gruppo in colonne. */
@font-face{{font-family:"Fredoka";src:url("{font}") format("truetype");font-weight:300 700}}
:root{{--bg:#f6f2fb;--panel:#fff;--ink:#2b1650;--mute:#6a5a86;--line:#e3daf1;--accent:#7a4fe0;
  --f-display:"Fredoka","Trebuchet MS",system-ui,sans-serif;--f-body:"Fredoka",system-ui,-apple-system,"Segoe UI",sans-serif}}
@media (prefers-color-scheme: dark){{:root:not([data-theme="light"]){{--bg:#161026;--panel:#221838;--ink:#f1eafc;--mute:#b5a6cf;--line:#352a52;--accent:#a888ff;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#161026;--panel:#221838;--ink:#f1eafc;--mute:#b5a6cf;--line:#352a52;--accent:#a888ff;color-scheme:dark}}
*{{box-sizing:border-box}}
body{{background:var(--bg);color:var(--ink);font:400 1rem/1.5 var(--f-body);padding-block:1.5rem 3rem;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}}
.wrap{{max-width:64rem;margin:0 auto}}
h1,h2,h3{{font-family:var(--f-display);margin:0;text-wrap:balance}}
h1{{font-size:clamp(2rem,6vw,3rem);font-weight:700;line-height:1.05}}
.kicker{{color:var(--accent);font-weight:600;letter-spacing:.08em;text-transform:uppercase;font-size:.8rem}}
.top{{display:grid;gap:2rem;grid-template-columns:1fr;align-items:start;margin-top:1rem}}
@media (min-width:760px){{.top{{grid-template-columns:minmax(0,18rem) 1fr}}}}
.top img{{width:100%;max-width:18rem;display:block;margin:0 auto;border-radius:18px;box-shadow:0 6px 24px rgba(43,22,80,.25)}}
.regole{{min-width:0}}
.regole ol{{padding-left:1.3rem;margin:.6rem 0}} .regole li{{margin:.35rem 0}}
.nota{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:.8rem 1rem;margin-top:1rem;color:var(--mute)}}
h2{{font-size:1.6rem;margin:2.5rem 0 1rem}}
.gruppi{{columns:1;column-gap:1.25rem}}
@media (min-width:640px){{.gruppi{{columns:2}}}}
@media (min-width:1000px){{.gruppi{{columns:3}}}}
.gruppo{{break-inside:avoid;background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:.9rem 1rem;margin:0 0 1.25rem}}
.gruppo h3{{font-size:1.15rem;color:var(--g);display:flex;justify-content:space-between;align-items:baseline;gap:.5rem}}
.gruppo h3 span{{font-size:.8rem;color:var(--mute);font-weight:500}}
.gruppo ol{{list-style:none;padding:0;margin:.5rem 0 0}}
.gruppo li{{display:flex;gap:.6rem;padding:.4rem 0;border-top:1px solid var(--line)}}
.gruppo .n{{font-variant-numeric:tabular-nums;color:var(--g);font-weight:600;min-width:2.2rem}}
.gruppo .t{{min-width:0}} .gruppo b{{display:block;font-weight:600}} .gruppo small{{color:var(--mute);font-size:.88rem}}
</style>
<div class="wrap">
  <div class="kicker">Il gioco della serata</div>
  <h1>Carte del Mostrometro</h1>
  <div class="top">
    <img src="{carta}" alt="Carta di prova numero 1: il mostro rutta a tavola, con il titolo Rutta a tavola, +{PUNTI_CARTA} mostro e il QR code">
    <div class="regole">
      <h3>Come si gioca</h3>
      <ol>
        <li>A inizio serata ognuno riceve qualche carta, senza farla vedere.</li>
        <li>Durante la serata fa l'azione della carta davanti a tutti, senza avvisare.</li>
        <li>Poi scansiona il QR con il telefono collegato al WiFi del Mostrometro, scrive il proprio nome e prende <b>+{PUNTI_CARTA} di mostruosità</b>.</li>
        <li>Ogni carta vale una volta sola. Alla prossima misura il mercurio sale.</li>
      </ol>
      <div class="nota">Questa è la <b>carta di prova</b>, la numero 1, in formato da carta da gioco (63 × 88 mm), pronta per la stampa. Il disegno lo fa Higgsfield con la nostra mascotte; il testo, i punti e il QR li mette un programma, così sono sempre giusti. Il QR è stato verificato con un lettore.</div>
    </div>
  </div>
  <h2>Le 100 azioni</h2>
  <div class="gruppi">{"".join(gruppi_html)}</div>
</div>
'''
out = os.path.join(QUI, "lista.html")
open(out, "w", encoding="utf8").write(pagina)
print("scritto", out, len(pagina) // 1024, "KB,", n, "azioni")
