#!/usr/bin/env python3
"""Crea qr_prova.html: alcuni QR di prova che aprono l'ANTEPRIMA dell'app (non il Mostrometro vero).
Si apre la pagina sul computer e si inquadrano i QR con il telefono, per provare il gioco senza la scheda.
I QR delle carte vere invece puntano a http://192.168.4.1 e funzionano solo con il WiFi del Mostrometro.
"""
import html, os
import segno
from azioni import AZIONI
from genera_carte import codice

QUI = os.path.dirname(os.path.abspath(__file__))
ANTEPRIMA = "https://claude.ai/artifact/2H1LL8aDYkZjzgbLoAD3Xb"
PROVE = [1, 3, 30, 57, 89, 100]

def qr(n):
    link = f"{ANTEPRIMA}#carta-{n}-{codice(n)}"
    return segno.make(link, error="m").svg_inline(scale=5, border=2, dark="#1d1238", light="#ffffff", omitsize=True)

blocchi = []
for n in PROVE:
    _, titolo, come, extra = AZIONI[n - 1]
    blocchi.append(f'''<figure class="qr">
  <div class="cod">{qr(n)}</div>
  <figcaption><span class="num">Carta N. {n:03d}</span><b>{html.escape(titolo)}</b><small>{html.escape(come)}</small></figcaption>
</figure>''')

pagina = f'''<title>QR di prova</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;600;700&display=swap">
<style>
/* Layout: istruzioni in alto, sotto una griglia di QR grandi con il titolo della carta. */
:root{{--bg:#f4f0fa;--panel:#ffffff;--ink:#1d1238;--mute:#655a80;--line:#ddd3ee;--accent:#ff6a3d;
  --f:"Fredoka","Trebuchet MS",system-ui,sans-serif}}
@media (prefers-color-scheme: dark){{:root:not([data-theme="light"]){{--bg:#140d24;--panel:#221838;--ink:#f3edff;--mute:#b3a7cc;--line:#382c58;--accent:#ff8a5c;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#140d24;--panel:#221838;--ink:#f3edff;--mute:#b3a7cc;--line:#382c58;--accent:#ff8a5c;color-scheme:dark}}
*{{box-sizing:border-box}}
body{{background:var(--bg);color:var(--ink);font:400 1rem/1.5 var(--f);padding-block:1.5rem 3rem;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}}
.wrap{{max-width:60rem;margin:0 auto;display:grid;gap:1.5rem}}
h1{{margin:0;font-size:clamp(1.8rem,5vw,2.6rem);line-height:1.1;text-wrap:balance}}
.passi{{margin:0;padding-left:1.3rem;max-width:42rem}} .passi li{{margin:.3rem 0}}
.nota{{color:var(--mute);max-width:42rem;margin:0}}
.griglia{{display:grid;gap:1rem;grid-template-columns:repeat(auto-fill,minmax(15rem,1fr))}}
.qr{{margin:0;background:var(--panel);border:1px solid var(--line);border-radius:16px;padding:1rem;display:grid;gap:.6rem}}
.cod{{background:#fff;border-radius:10px;padding:.4rem}}
.cod svg{{display:block;width:100%;height:auto;max-width:15rem;margin:0 auto}}
figcaption{{display:grid;gap:.1rem;min-width:0}}
.num{{color:var(--accent);font-weight:600;font-size:.8rem;letter-spacing:.06em;text-transform:uppercase}}
figcaption b{{font-size:1.15rem}} figcaption small{{color:var(--mute);font-size:.9rem}}
</style>
<div class="wrap">
  <h1>QR di prova</h1>
  <ol class="passi">
    <li>Tieni questa pagina aperta sul <b>computer</b>.</li>
    <li>Apri la <b>fotocamera del telefono</b> e inquadra un QR.</li>
    <li>Tocca il link che compare: si apre l'anteprima dell'app con quella carta, pronta da assegnare.</li>
  </ol>
  <p class="nota">Questi QR aprono l'anteprima su claude.ai, per provare. I QR stampati sulle carte vere aprono il Mostrometro e funzionano quando il telefono è collegato al suo WiFi.</p>
  <div class="griglia">{"".join(blocchi)}</div>
</div>
'''
open(os.path.join(QUI, "qr_prova.html"), "w", encoding="utf8").write(pagina)
print("scritto qr_prova.html")
