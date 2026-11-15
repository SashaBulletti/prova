#!/usr/bin/env python3
"""Crea guida_scatola.html: come stampare le carte fronte-retro, costruire la scatola e stampare l'inserto."""
import base64, os

QUI = os.path.dirname(os.path.abspath(__file__))
def img(nome):
    p = os.path.join(QUI, "grafica", "guida", nome)
    return "data:image/jpeg;base64," + base64.b64encode(open(p, "rb").read()).decode()
def img_carta1():
    p = os.path.join(QUI, "..", "carte", "carta_prova_001.png")
    from PIL import Image
    import io
    b = io.BytesIO(); Image.open(p).convert("RGB").resize((372, 520)).save(b, "JPEG", quality=85)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

TAGLI = [
    ("Fondo", "Base", "227 × 213", 1),
    ("Fondo", "Lato lungo", "237 × 50", 2),
    ("Fondo", "Lato corto", "213 × 50", 2),
    ("Coperchio", "Sopra", "238 × 224", 1),
    ("Coperchio", "Lato lungo", "248 × 30", 2),
    ("Coperchio", "Lato corto", "224 × 30", 2),
]
righe = "".join(f"<tr><td>{a}</td><td>{b}</td><td class='num'>{c}</td><td class='num'>{d}</td></tr>" for a, b, c, d in TAGLI)

pagina = f'''<title>Scatola del Mostrometro</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&display=swap">
<style>
/* Layout: una colonna di lettura; ogni parte (carte, scatola, inserto, file) ha immagine + passi affiancati su schermo largo. */
:root{{--bg:#f6f2fb;--panel:#ffffff;--ink:#24123f;--mute:#62567a;--line:#e2d9f0;--accent:#6a35d9;--sun:#f2b705;
  --f:"Fredoka","Trebuchet MS",system-ui,sans-serif}}
@media (prefers-color-scheme: dark){{:root:not([data-theme="light"]){{--bg:#140d22;--panel:#1f1634;--ink:#f1ebfb;--mute:#b4a8cb;--line:#352a50;--accent:#a888ff;--sun:#ffd84a;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#140d22;--panel:#1f1634;--ink:#f1ebfb;--mute:#b4a8cb;--line:#352a50;--accent:#a888ff;--sun:#ffd84a;color-scheme:dark}}
*{{box-sizing:border-box}}
body{{background:var(--bg);color:var(--ink);font:400 1.02rem/1.55 var(--f);padding-block:1.5rem 4rem;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}}
.wrap{{max-width:62rem;margin:0 auto;display:grid;gap:2.6rem}}
h1,h2,h3{{margin:0;text-wrap:balance;line-height:1.1}}
h1{{font-size:clamp(2rem,6vw,3.1rem);font-weight:700}}
h2{{font-size:clamp(1.5rem,4vw,2rem);font-weight:700}}
h3{{font-size:1.15rem;font-weight:600;margin-top:1rem}}
.kicker{{color:var(--accent);font-weight:600;letter-spacing:.08em;text-transform:uppercase;font-size:.8rem}}
.intro{{color:var(--mute);max-width:40rem;margin:.6rem 0 0}}
.hero{{display:grid;gap:1.5rem;align-items:center}}
@media (min-width:760px){{.hero{{grid-template-columns:1.1fr .9fr}}}}
.hero img{{width:100%;border-radius:14px;box-shadow:0 10px 30px rgba(36,18,63,.25)}}
.parte{{display:grid;gap:1.2rem}}
.due{{display:grid;gap:1.4rem;align-items:start}}
@media (min-width:760px){{.due{{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}}}}
.due>*{{min-width:0}}
figure{{margin:0}} figure img{{width:100%;display:block;border-radius:12px;border:1px solid var(--line)}}
figcaption{{color:var(--mute);font-size:.88rem;margin-top:.4rem}}
.coppia{{display:grid;grid-template-columns:1fr 1fr;gap:.8rem}}
ol.passi{{margin:.4rem 0 0;padding-left:1.4rem;display:grid;gap:.45rem}}
ul.lista{{margin:.4rem 0 0;padding-left:1.2rem;display:grid;gap:.3rem}}
.box{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:1rem 1.1rem}}
.attenzione{{border-left:4px solid var(--sun)}}
.tab{{overflow-x:auto}}
table{{border-collapse:collapse;width:100%;font-variant-numeric:tabular-nums}}
th,td{{text-align:left;padding:.45rem .6rem;border-bottom:1px solid var(--line)}}
th{{font-size:.8rem;letter-spacing:.06em;text-transform:uppercase;color:var(--mute);font-weight:600}}
td.num{{text-align:right}} th.num{{text-align:right}}
.file{{display:grid;gap:.6rem}}
.file div{{display:grid;grid-template-columns:auto 1fr;gap:.2rem .8rem;align-items:baseline}}
code{{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:.88em;background:var(--panel);border:1px solid var(--line);border-radius:6px;padding:.05rem .35rem;overflow-wrap:anywhere}}
.misura{{font-weight:600;color:var(--accent)}}
</style>
<div class="wrap">
  <header class="hero">
    <div>
      <div class="kicker">Mostrometro · il gioco in scatola</div>
      <h1>Scatola del Mostrometro</h1>
      <p class="intro">Tutto per trasformare il Mostrometro in un gioco da tavolo: il retro delle carte, la scatola di cartone con le etichette stampate e l'inserto 3D che tiene fermi il Mostrometro e le 100 carte.</p>
    </div>
    <img src="{img("coperchio.jpg")}" alt="L'etichetta del coperchio: il mostro viola che ruggisce felice tra le carte, con il titolo MOSTROMETRO">
  </header>

  <section class="parte">
    <div><div class="kicker">1 · Le carte</div><h2>Fronte e retro</h2></div>
    <div class="due">
      <div class="coppia">
        <figure><img src="{img_carta1()}" alt="Il fronte della carta 1, Rutta a tavola"><figcaption>Fronte</figcaption></figure>
        <figure><img src="{img("retro.jpg")}" alt="Il retro delle carte: la mascotte in un tondo giallo su sfondo viola a puntini, con la scala del termometro"><figcaption>Retro, uguale per tutte</figcaption></figure>
      </div>
      <div>
        <p>Il file <code>carte_da_stampare.pdf</code> ha 24 pagine: dopo ogni foglio di carte c'è il foglio dei retro.</p>
        <ol class="passi">
          <li>Stampa <b>fronte-retro</b>, girando sul <b>lato lungo</b>, con la scala al <b>100%</b>.</li>
          <li>Prima prova con le pagine 1 e 2 su carta normale: guarda in controluce se fronte e retro combaciano.</li>
          <li>Se combaciano, stampa tutto su cartoncino da 200–250 g e taglia lungo i trattini.</li>
        </ol>
        <div class="box attenzione" style="margin-top:1rem">La tua stampante non fa il fronte-retro? Stampa le pagine dispari, rimetti i fogli nel cassetto girati e stampa le pagine pari. Il retro è simmetrico, quindi uno spostamento di 1–2 mm non si nota.</div>
      </div>
    </div>
  </section>

  <section class="parte">
    <div><div class="kicker">2 · La scatola</div><h2>Cartone piuma e etichette</h2>
      <p class="intro">Fuori misura <span class="misura">248 × 234 × 50 mm</span>. È fatta su misura per l'inserto, così dentro non balla niente.</p></div>
    <div class="due">
      <div class="box">
        <h3 style="margin-top:0">Ti serve</h3>
        <ul class="lista">
          <li>1 foglio di <b>cartone piuma da 5 mm</b>, 50 × 70 cm (cartoleria o negozio di belle arti)</li>
          <li>taglierino nuovo, righello di metallo, una base da taglio</li>
          <li>colla vinilica o pistola a caldo, colla stick per le etichette</li>
          <li>le etichette stampate: <b>1 foglio A3</b> (in copisteria) e <b>3 fogli A4</b></li>
        </ul>
      </div>
      <div class="tab box">
        <table>
          <thead><tr><th>Parte</th><th>Pezzo</th><th class="num">Misura (mm)</th><th class="num">Quanti</th></tr></thead>
          <tbody>{righe}</tbody>
        </table>
      </div>
    </div>
    <div class="due">
      <div>
        <h3 style="margin-top:0">Come si monta</h3>
        <ol class="passi">
          <li>Disegna i pezzi a matita e tagliali con più passate leggere, il taglierino sempre dritto.</li>
          <li><b>Fondo:</b> appoggia la base sul tavolo. Incolla i due lati lunghi <b>fuori</b> dalla base, in piedi; poi i due lati corti, in mezzo ai lunghi.</li>
          <li><b>Coperchio:</b> uguale, con il pezzo «sopra» e i lati da 30 mm.</li>
          <li>Prova: il coperchio deve scendere sul fondo senza forzare.</li>
          <li>Incolla l'etichetta grande sopra il coperchio e le 4 strisce strette sui lati del coperchio.</li>
          <li>Incolla le 4 strisce alte sui lati del fondo, partendo dal basso, e l'etichetta «come si gioca» sotto la scatola.</li>
        </ol>
      </div>
      <div class="file">
        <figure><img src="{img("lati.jpg")}" alt="Le 4 strisce viola per i lati del coperchio, con la scritta MOSTROMETRO"><figcaption>Le strisce per i lati del coperchio</figcaption></figure>
        <figure><img src="{img("sotto.jpg")}" alt="L'etichetta per sotto la scatola: illustrazione dei mostri a cena e le regole in 5 passi"><figcaption>Sotto la scatola: le regole in 5 passi</figcaption></figure>
      </div>
    </div>
  </section>

  <section class="parte">
    <div><div class="kicker">3 · L'inserto</div><h2>Tiene tutto fermo</h2></div>
    <div class="due">
      <figure><img src="{img("inserto.jpg")}" alt="L'inserto 3D: a sinistra il vassoio viola con la sagoma del Mostrometro, a destra il vassoio giallo con due vani per le carte"><figcaption>Viola: il Mostrometro sdraiato. Giallo: due vani da 50 carte.</figcaption></figure>
      <div>
        <p>Due pezzi che si mettono affiancati sul fondo della scatola. Insieme fanno <span class="misura">225 × 211 × 33 mm</span>.</p>
        <ul class="lista">
          <li><b>Vassoio del mostro</b> (150 × 211 mm): la sagoma esatta del Mostrometro, con due incavi ai lati della testa per tirarlo su con le dita.</li>
          <li><b>Vassoio delle carte</b> (74 × 211 mm): due vani da 50 carte, che vanno bene anche con le bustine. Un incavo per le dita su ogni vano.</li>
        </ul>
        <h3>Come stamparli</h3>
        <ul class="lista">
          <li>Stanno su un piatto da 220 × 220 mm. Uno alla volta, appoggiati sul fondo.</li>
          <li>Niente supporti. Strati da 0,28 mm, riempimento 10–15%.</li>
          <li>Colori: viola per il mostro, giallo per le carte, come le corna.</li>
        </ul>
        <div class="box attenzione" style="margin-top:1rem">Il naso (il bottone) sporge sopra l'inserto: per questo la scatola dentro è alta 45 mm. Se il tuo bottone è più alto, dimmelo e alzo la scatola.</div>
      </div>
    </div>
  </section>

  <section class="parte">
    <div><div class="kicker">4 · I file</div><h2>Cosa stampare</h2></div>
    <div class="box file">
      <div><code>carte_da_stampare.pdf</code><span>24 pagine A4: fronti e retro alternati.</span></div>
      <div><code>retro_carte.pdf</code><span>1 pagina A4: solo i retro, se stampi i due lati separati.</span></div>
      <div><code>scatola_A3.pdf</code><span>L'etichetta del coperchio, su A3.</span></div>
      <div><code>scatola_A4.pdf</code><span>3 pagine A4: lati del coperchio, lati del fondo, etichetta di sotto.</span></div>
      <div><code>inserto_mostro.stl</code><span>Il vassoio del Mostrometro.</span></div>
      <div><code>inserto_carte.stl</code><span>Il vassoio delle carte.</span></div>
    </div>
  </section>
</div>
'''
out = os.path.join(QUI, "guida_scatola.html")
open(out, "w", encoding="utf8").write(pagina)
print("scritto", out, len(pagina) // 1024, "KB")
