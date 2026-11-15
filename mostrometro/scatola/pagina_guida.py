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
      <p class="intro">Tutto per trasformare il Mostrometro in un gioco da tavolo: il retro delle carte, la scatola tutta in un pezzo da stampare e l'inserto 3D che tiene fermi il Mostrometro e le 100 carte.</p>
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
    <div><div class="kicker">2 · La scatola</div><h2>Tutta in un pezzo</h2>
      <p class="intro">Non serve comprare una scatola: coperchio e fondo si stampano già con la grafica su un foglio di cartoncino da 50 × 70 cm, poi si ritagliano, si piegano e si incollano. Chiusa misura circa <span class="misura">231 × 217 × 46 mm</span>, su misura per l'inserto.</p></div>
    <div class="due">
      <figure><img src="{img("fustella.jpg")}" alt="Il foglio da stampare: in alto il coperchio aperto con la copertina e le 4 pareti, in basso il fondo aperto con le regole e le 4 pareti"><figcaption>Il foglio da stampare. Linea nera: taglia. Tratteggio bianco: piega.</figcaption></figure>
      <figure><img src="{img("fustella_misure.jpg")}" alt="Il disegno tecnico con le misure: coperchio 230 per 216 con pareti da 30, fondo 227 per 213 con pareti da 45"><figcaption>Il disegno con le misure (pagina 2 del PDF).</figcaption></figure>
    </div>
    <div class="due">
      <div class="tab box">
        <table>
          <thead><tr><th>Pezzo</th><th class="num">Pannello (mm)</th><th class="num">Pareti</th><th class="num">Aperto (mm)</th></tr></thead>
          <tbody>
            <tr><td>Coperchio</td><td class="num">230 × 216</td><td class="num">30 mm</td><td class="num">290 × 276</td></tr>
            <tr><td>Fondo</td><td class="num">227 × 213</td><td class="num">45 mm</td><td class="num">317 × 303</td></tr>
            <tr><td>Alette negli angoli</td><td class="num">15</td><td class="num">8 in tutto</td><td class="num"></td></tr>
          </tbody>
        </table>
      </div>
      <div class="box">
        <h3 style="margin-top:0">Ti serve</h3>
        <ul class="lista">
          <li>la stampa di <code>scatola_fustella.pdf</code> (solo la pagina 1) su <b>cartoncino 300–350 g, formato 50 × 70 cm</b>, in copisteria, al 100%</li>
          <li>taglierino, righello di metallo, base da taglio</li>
          <li>una penna scarica (o il dorso di un coltello) per segnare le pieghe</li>
          <li>colla vinilica o nastro biadesivo</li>
        </ul>
      </div>
    </div>
    <div>
      <h3 style="margin-top:0">Come si monta</h3>
      <ol class="passi">
        <li>Ritaglia i due pezzi lungo la linea nera, compresi i 4 piccoli tagli vicino alle alette di ogni pezzo.</li>
        <li>Appoggia il righello su ogni linea tratteggiata e ripassala con la penna scarica, premendo: così la piega viene dritta.</li>
        <li>Piega tutte le pareti verso l'interno (la grafica resta fuori) e piega le alette.</li>
        <li>Metti la colla sulle alette e incollale dentro le pareti accanto. Tieni stretto un minuto per ogni angolo.</li>
        <li>Prova: il coperchio scende sul fondo senza forzare. Poi metti dentro l'inserto, le carte e il Mostrometro.</li>
      </ol>
      <div class="box attenzione" style="margin-top:1rem">Vuoi comprare una scatola già fatta? Deve misurare dentro almeno <b>23 × 22 × 4,5 cm</b>: va bene per esempio una scatola quadrata da 25 × 25 × 5 cm. Dentro avanzano un paio di centimetri.</div>
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
        <div class="box attenzione" style="margin-top:1rem">Il naso (il bottone) sporge sopra l'inserto: per questo il fondo della scatola è alto 45 mm. Se il tuo bottone è più alto, dimmelo e alzo la scatola.</div>
      </div>
    </div>
  </section>

  <section class="parte">
    <div><div class="kicker">4 · I file</div><h2>Cosa stampare</h2></div>
    <div class="box file">
      <div><code>carte_da_stampare.pdf</code><span>24 pagine A4: fronti e retro alternati.</span></div>
      <div><code>retro_carte.pdf</code><span>1 pagina A4: solo i retro, se stampi i due lati separati.</span></div>
      <div><code>scatola_fustella.pdf</code><span>Pagina 1: la scatola da stampare su 50 × 70 cm. Pagina 2: il disegno con le misure.</span></div>
      <div><code>inserto_mostro.stl</code><span>Il vassoio del Mostrometro.</span></div>
      <div><code>inserto_carte.stl</code><span>Il vassoio delle carte.</span></div>
    </div>
  </section>
</div>
'''
out = os.path.join(QUI, "guida_scatola.html")
open(out, "w", encoding="utf8").write(pagina)
print("scritto", out, len(pagina) // 1024, "KB")
