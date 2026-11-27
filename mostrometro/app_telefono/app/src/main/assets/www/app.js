/* Mostrometro sul telefono: stesse regole del Mostrometro vero (firmware/mostrometro/mostrometro.ino).
   - mostruosita' di base fissa per ogni nome (10-65%), + i punti presi con l'urlo e con le carte (massimo 100)
   - i punti restano "in attesa" finche' non ti misuri di nuovo
   - ogni carta vale una volta per serata; Mostro Supremo: 5 a testa con gli Artigli, altrimenti 2 a chi gioca */
"use strict";
const $ = s => document.querySelector(s);
const CHIAVE = "mostrometro_telefono_v1";
const MAX_FAM = 12, PUNTI_DA_SOLO = 2;
const FRASI = ["Angelo? Mah...", "Mostrino da divano", "Mostro medio", "Mostro serio! Papà ha ragione", "Mostro GIGANTE", "SUPER MOSTRO!"];
const livello = v => v < 10 ? 0 : v < 30 ? 1 : v < 50 ? 2 : v < 70 ? 3 : v < 90 ? 4 : 5;
const pulisci = s => (s || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^\x20-\x7e]/g, "")
  .replace(/[:;"\\<>&'%]/g, "").trim().slice(0, 14);
const telefono = window.Telefono || { vibra() {}, schermoAcceso() {} };

// ------------------------------------------------------------------ dati salvati
let S = { fam: [], chi: "", carte: {} };
try { const j = JSON.parse(localStorage.getItem(CHIAVE) || "null"); if (j && Array.isArray(j.fam)) S = Object.assign(S, j); } catch (e) {}
const salva = () => { try { localStorage.setItem(CHIAVE, JSON.stringify(S)); } catch (e) {} };

function base(nome) {                                   // FNV-1a, come nel firmware
  let h = 2166136261; nome = nome.toLowerCase();
  for (let i = 0; i < nome.length; i++) { h ^= nome.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
  return 10 + (h >>> 0) % 56;
}
const trova = n => S.fam.find(f => f.n.toLowerCase() === (n || "").toLowerCase());
const attuale = f => Math.min(100, base(f.n) + f.bonus);
const inAttesa = f => (f.v >= 0 && attuale(f) > f.v) ? attuale(f) - f.v : 0;
const carteDi = n => Object.values(S.carte).filter(x => x.toLowerCase() === n.toLowerCase()).length;
function crea(n) { const p = { n, bonus: 0, v: -1 }; S.fam.push(p); return p; }
function daiPunti(f, p) { f.bonus = Math.max(0, Math.min(100, f.bonus + p)); }

// ------------------------------------------------------------------ suoni
let ac = null; const buffer = {};
function audio() { if (!ac) ac = new (window.AudioContext || window.webkitAudioContext)(); if (ac.state === "suspended") ac.resume(); return ac; }
async function carica(nome) {
  if (buffer[nome]) return buffer[nome];
  const r = await fetch("suoni/" + nome + ".wav");
  buffer[nome] = await audio().decodeAudioData(await r.arrayBuffer());
  return buffer[nome];
}
let fineCoda = 0;
async function suona(nomi) {                            // in fila, uno dopo l'altro; risolve quando finiscono
  try {
    const bufs = await Promise.all(nomi.map(carica));
    const c = audio(); let t = Math.max(c.currentTime + 0.03, fineCoda);
    for (const b of bufs) { const s = c.createBufferSource(); s.buffer = b; s.connect(c.destination); s.start(t); t += b.duration; }
    fineCoda = t;
    await attendi((t - c.currentTime) * 1000);
  } catch (e) { console.warn("suono", e); }
}
const attendi = ms => new Promise(r => setTimeout(r, Math.max(0, ms)));
const num = n => "n" + String(n).padStart(3, "0");
const seiAl = n => (n === 1 || n === 8 || n === 11 || (n >= 80 && n <= 89)) ? "sei_all" : "sei_al";

// ------------------------------------------------------------------ il disegno: tacche, mercurio, occhi, sopracciglia
(function tacche() {
  const g = $("#tacche"); let h = "";
  for (let i = 0; i <= 10; i++) {
    const y = -(47.8 + i * 8.44), len = i % 5 === 0 ? 6 : 3.5;
    for (const s of [-1, 1]) { const x = s * (11.45 + 2.3 + len / 2); h += `<rect x="${x - len / 2}" y="${y - .5}" width="${len}" height="1" rx=".4"/>`; }
  }
  g.innerHTML = h;
})();

const COLORI = [[82, 224, 138], [255, 216, 74], [255, 147, 64], [255, 61, 90]];
function colore(v) {
  const t = Math.max(0, Math.min(1, v / 100)) * 3, i = Math.min(2, Math.floor(t)), f = t - i;
  const a = COLORI[i], b = COLORI[i + 1];
  return `rgb(${a.map((x, k) => Math.round(x + (b[k] - x) * f)).join(",")})`;
}
function mercurio(v, testo) {                           // v 0..100
  const h = 63 * Math.max(0, Math.min(100, v)) / 100;
  const m = $("#mercurio"); m.setAttribute("y", -55 - h); m.setAttribute("height", h + 0.01);
  $("#bulbo").setAttribute("fill", colore(v));
  $("#schermo-pct").textContent = testo !== undefined ? testo : Math.round(v) + "%";
}
function sopracciglia(v) {                              // da tranquillo (0) ad arrabbiato (100)
  const a = -8 + 30 * Math.max(0, Math.min(100, v)) / 100;
  $("#ciglio-sx").setAttribute("transform", `rotate(${a} -22 -164.5)`);
  $("#ciglio-dx").setAttribute("transform", `rotate(${-a} 22 -164.5)`);
}

// Occhioni "googly": la pupilla rotola dentro l'occhio, cade verso il basso (anche inclinando il telefono),
// rimbalza sul bordo, ogni tanto scatta da sola qua e la', e guarda il dito quando tocchi lo schermo.
const occhi = [
  { el: $("#pupilla-sx"), x: 0, y: 3, vx: 0, vy: 0 },
  { el: $("#pupilla-dx"), x: 0, y: 3, vx: 0, vy: 0 },
];
const RAGGIO = 12 - 6.4 - 0.7;
let gravita = { x: 0, y: 1 }, guarda = null, agitato = 0, ultimoT = 0, prossimoScatto = 0;
window.addEventListener("devicemotion", e => {
  const g = e.accelerationIncludingGravity; if (!g || g.x === null) return;
  gravita = { x: -g.x / 9.8, y: g.y / 9.8 };
  const a = e.acceleration; if (a && a.x !== null && Math.hypot(a.x, a.y, a.z) > 6) agitato = 1;   // scossone
});
function passoOcchi(t) {
  const dt = Math.min(0.05, (t - ultimoT) / 1000 || 0.016); ultimoT = t;
  if (t > prossimoScatto) {                             // scatto casuale: "vanno qua e la'"
    prossimoScatto = t + 900 + Math.random() * 2600;
    const a = Math.random() * Math.PI * 2, f = 40 + Math.random() * 60;
    occhi.forEach((o, i) => { o.vx += Math.cos(a + i * 0.6) * f; o.vy += Math.sin(a + i * 0.6) * f; });
  }
  occhi.forEach((o, i) => {
    let ax = gravita.x * 60, ay = gravita.y * 60;
    if (guarda) { ax = (guarda[i].x - o.x) * 40; ay = (guarda[i].y - o.y) * 40; }
    if (agitato > 0) { ax += (Math.random() - .5) * 900 * agitato; ay += (Math.random() - .5) * 900 * agitato; }
    o.vx = (o.vx + ax * dt) * 0.985; o.vy = (o.vy + ay * dt) * 0.985;
    o.x += o.vx * dt; o.y += o.vy * dt;
    const d = Math.hypot(o.x, o.y);
    if (d > RAGGIO) {                                    // rimbalzo sul bordo dell'occhio
      const nx = o.x / d, ny = o.y / d; o.x = nx * RAGGIO; o.y = ny * RAGGIO;
      const vn = o.vx * nx + o.vy * ny;
      if (vn > 0) { o.vx -= 1.6 * vn * nx; o.vy -= 1.6 * vn * ny; }
    }
    o.el.setAttribute("transform", `translate(${o.x.toFixed(2)} ${o.y.toFixed(2)})`);
  });
  agitato = Math.max(0, agitato - dt * 1.5);
  requestAnimationFrame(passoOcchi);
}
requestAnimationFrame(passoOcchi);

const svg = $("#mostro");
function punto(e) { const p = svg.createSVGPoint(); p.x = e.clientX; p.y = e.clientY; return p.matrixTransform(svg.getScreenCTM().inverse()); }
function guardaVerso(e) {
  const p = punto(e);
  guarda = [-22, 22].map(cx => { const dx = p.x - cx, dy = p.y + 147.5, d = Math.hypot(dx, dy) || 1, k = Math.min(RAGGIO, d / 6) / d; return { x: dx * k, y: dy * k }; });
}
document.addEventListener("pointerdown", e => { if ($("#v-mostro").classList.contains("attiva")) guardaVerso(e); });
document.addEventListener("pointermove", e => { if (guarda) guardaVerso(e); });
document.addEventListener("pointerup", () => { guarda = null; });
document.addEventListener("pointercancel", () => { guarda = null; });

// ------------------------------------------------------------------ misura e urlo
let occupato = false;
const palco = $("#palco");
function animaValore(da, a, ms, cb) {
  return new Promise(r => {
    const t0 = performance.now();
    (function f(t) {
      const k = Math.min(1, (t - t0) / ms), e = k < .5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2;
      cb(da + (a - da) * e); if (k < 1) requestAnimationFrame(f); else r();
    })(t0);
  });
}
async function misura() {
  const f = trova(S.chi);
  if (!f) { scegliChi("Prima scegli chi si misura"); return; }
  if (occupato) return; occupato = true; telefono.schermoAcceso(true);
  const target = attuale(f);
  $("#frase").textContent = "Misuro..."; $("#pct").textContent = "...";
  palco.classList.add("trema"); agitato = 1; telefono.vibra(60);
  const verso = suona(["verso" + livello(target)]);
  await animaValore(0, 100, 2000, v => { mercurio(v); sopracciglia(v); });
  await animaValore(100, target, 900, v => { mercurio(v); sopracciglia(v); });
  await verso;
  palco.classList.remove("trema"); palco.classList.add("salta"); setTimeout(() => palco.classList.remove("salta"), 520);
  f.v = target; salva();
  mostraRisultato(f); telefono.vibra(30);
  await suona([seiAl(target), num(target), "per_cento"]);
  occupato = false; telefono.schermoAcceso(false); disegnaFamiglia();
}
async function urla() {
  const f = trova(S.chi);
  if (!f) { scegliChi("Prima scegli chi urla"); return; }
  if (occupato) return; occupato = true;
  let flusso;
  try { flusso = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false } }); }
  catch (e) { occupato = false; $("#frase").textContent = "Serve il permesso del microfono per l'urlo."; return; }
  $("#frase").textContent = "Pronto..."; $("#pct").textContent = "🎤";
  await suona(["urla", "bip"]);
  $("#frase").textContent = "URLA!"; palco.classList.add("trema");
  const c = audio(), src = c.createMediaStreamSource(flusso), an = c.createAnalyser(); an.fftSize = 1024; src.connect(an);
  const dati = new Float32Array(an.fftSize); let picco = 0; const onda = $("#onda"); onda.hidden = false;
  const t0 = performance.now();
  await new Promise(r => {
    (function ascolta() {
      an.getFloatTimeDomainData(dati); let s = 0; for (const x of dati) s += x * x;
      const rms = Math.sqrt(s / dati.length); picco = Math.max(picco, rms);
      const db = 20 * Math.log10(Math.max(rms, 1e-6)), liv = Math.max(0, Math.min(100, (db + 50) / 40 * 100));
      onda.style.setProperty("--livello", liv + "%"); mercurio(liv, ""); agitato = Math.max(agitato, liv / 100);
      if (performance.now() - t0 < 2000) requestAnimationFrame(ascolta); else r();
    })();
  });
  flusso.getTracks().forEach(t => t.stop()); src.disconnect(); onda.hidden = true; palco.classList.remove("trema");
  const db = 20 * Math.log10(Math.max(picco, 1e-6));
  const punti = Math.max(0, Math.min(10, Math.round((db + 45) / 30 * 10)));   // come il firmware: -45 dB = 0, -15 dB = 10
  daiPunti(f, punti); salva();
  mercurio(f.v >= 0 ? f.v : 0, f.v >= 0 ? f.v + "%" : "--");
  $("#pct").textContent = "+" + punti; $("#frase").textContent = punti >= 8 ? "Che urlo da MOSTRO!" : punti >= 4 ? "Bell'urlo!" : "Tutto qui? Più forte!";
  mostraAttesa(f);
  await suona(["urlo_da", num(punti), "punti"]);
  occupato = false; disegnaFamiglia();
}
function mostraRisultato(f) {
  $("#pct").textContent = f.v >= 0 ? f.v + "%" : "--%";
  $("#frase").textContent = f.v >= 0 ? FRASI[livello(f.v)] : "Tocca il naso per misurarti";
  mostraAttesa(f);
}
function mostraAttesa(f) {
  const p = inAttesa(f), a = $("#attesa");
  a.hidden = !(p > 0 || (f.v < 0 && f.bonus > 0));
  a.textContent = f.v < 0 ? "+" + f.bonus + " punti pronti" : "+" + p + " in attesa: premi il naso!";
}

// il naso: tocco = misura, tenuto premuto = urlo
const naso = $("#naso"); let timerNaso = null, lungo = false;
naso.addEventListener("pointerdown", e => {
  e.preventDefault(); audio(); naso.classList.add("premuto"); lungo = false; telefono.vibra(15);
  timerNaso = setTimeout(() => { lungo = true; telefono.vibra(80); urla(); }, 650);
});
const lascia = () => { naso.classList.remove("premuto"); if (timerNaso) { clearTimeout(timerNaso); timerNaso = null; if (!lungo) misura(); } };
naso.addEventListener("pointerup", lascia);
naso.addEventListener("pointerleave", () => { naso.classList.remove("premuto"); if (timerNaso) { clearTimeout(timerNaso); timerNaso = null; } });
naso.addEventListener("contextmenu", e => e.preventDefault());

// ------------------------------------------------------------------ foglio dal basso
let alChiudere = null;
function apriFoglio(html, chiusura) {
  $("#foglio-dentro").innerHTML = html; $("#foglio").hidden = false; $("#velo").hidden = false; alChiudere = chiusura || null;
  $("#foglio").scrollTop = 0;
}
function chiudiFoglio() { if ($("#foglio").hidden) return false; $("#foglio").hidden = true; $("#velo").hidden = true; const c = alChiudere; alChiudere = null; if (c) c(); return true; }
$("#velo").addEventListener("click", chiudiFoglio);
const esc = s => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

function bottoniNomi(id, campo) {
  return `<div class="scelte" id="${id}">${S.fam.map(f => `<button type="button" data-n="${esc(f.n)}">${esc(f.n)}</button>`).join("")}</div>
    <form class="aggiungi" data-per="${id}"><input id="${campo}" maxlength="14" placeholder="…oppure scrivi il nome" autocomplete="off"></form>`;
}
function collegaNomi(id, campo, alClic) {
  const box = document.getElementById(id), input = document.getElementById(campo);
  box.querySelectorAll("button").forEach(b => b.onclick = () => {
    input.value = b.dataset.n; box.querySelectorAll("button").forEach(x => x.classList.toggle("sel", x === b)); if (alClic) alClic(b.dataset.n);
  });
  input.oninput = () => box.querySelectorAll("button").forEach(x => x.classList.remove("sel"));
  input.closest("form").onsubmit = e => { e.preventDefault(); if (alClic) alClic(input.value); };
}

function scegliChi(titolo) {
  apriFoglio(`<h2>${esc(titolo || "Chi si misura?")}</h2>${bottoniNomi("sc-chi", "chi-nuovo")}<div id="sc-avv" class="avviso"></div>`);
  collegaNomi("sc-chi", "chi-nuovo", n => {
    n = pulisci(n); if (!n) return;
    let f = trova(n);
    if (!f) { if (S.fam.length >= MAX_FAM) { $("#sc-avv").textContent = "La famiglia è piena (12): togline uno in «Famiglia»."; return; } f = crea(n); }
    S.chi = f.n; salva(); chiudiFoglio(); aggiornaChi(); disegnaFamiglia();
  });
}
function aggiornaChi() {
  const f = trova(S.chi);
  $("#chi-nome").textContent = f ? f.n : "Scegli";
  if (f) { mercurio(f.v >= 0 ? f.v : 0, f.v >= 0 ? f.v + "%" : "--"); sopracciglia(f.v >= 0 ? f.v : 0); mostraRisultato(f); }
  else { mercurio(0, "--"); $("#pct").textContent = "--%"; $("#frase").textContent = "Scegli chi si misura"; $("#attesa").hidden = true; }
}
$("#chi").onclick = () => scegliChi();

// ------------------------------------------------------------------ famiglia
function disegnaFamiglia() {
  const L = $("#lista"), o = [...S.fam].sort((a, b) => b.v - a.v);
  if (!o.length) { L.innerHTML = `<div class="riquadro vuoto">Nessun mostro ancora: aggiungi i nomi qui sopra.</div>`; $("#corona").textContent = ""; return; }
  L.innerHTML = o.map(f => {
    const p = inAttesa(f), c = carteDi(f.n);
    const sotto = [p > 0 ? `<b>+${p} in attesa</b>` : "", c ? `${c} ${c > 1 ? "carte" : "carta"} stasera` : ""].filter(Boolean).join(" · ") || (f.v < 0 ? "non ancora misurato" : "&nbsp;");
    return `<div class="persona ${f.n === S.chi ? "scelta" : ""}" data-n="${esc(f.n)}">
      <div><div class="nome">${esc(f.n)}</div><div class="sotto">${sotto}</div></div>
      <div class="val">${f.v < 0 ? "?" : f.v + "%"}</div><button class="togli" data-togli="${esc(f.n)}" aria-label="Togli ${esc(f.n)}">✕</button>
      <div class="barra-v"><i style="width:${Math.max(0, f.v)}%"></i></div></div>`;
  }).join("");
  L.querySelectorAll(".persona").forEach(el => el.onclick = e => {
    if (e.target.dataset.togli) return;
    S.chi = el.dataset.n; salva(); aggiornaChi(); vai("mostro");
  });
  L.querySelectorAll("[data-togli]").forEach(b => b.onclick = () => conferma(`Togliere ${b.dataset.togli}?`, "Togli", () => {
    S.fam = S.fam.filter(f => f.n !== b.dataset.togli); if (S.chi === b.dataset.togli) S.chi = ""; salva(); disegnaFamiglia(); aggiornaChi();
  }));
  const mis = o.filter(f => f.v >= 0);
  $("#corona").textContent = mis.length ? `👑 Mostro della famiglia: ${mis[0].n} (${mis[0].v}%)` : "";
}
$("#f-nuovo").onsubmit = e => {
  e.preventDefault(); const n = pulisci($("#nuovo").value), m = $("#msg-fam");
  if (!n) { m.textContent = "Scrivi prima un nome."; return; }
  if (trova(n)) { m.textContent = n + " c'è già."; return; }
  if (S.fam.length >= MAX_FAM) { m.textContent = "La famiglia è piena (12 persone): togline una con la ✕."; return; }
  crea(n); if (!S.chi) S.chi = n; salva(); $("#nuovo").value = ""; m.textContent = n + " fa parte della famiglia!"; disegnaFamiglia(); aggiornaChi();
};
function conferma(testo, si, fatto) {
  apriFoglio(`<h2>${esc(testo)}</h2><button class="primario" id="cf-si">${esc(si)}</button><button class="secondario" id="cf-no">Annulla</button>`);
  $("#cf-si").onclick = () => { chiudiFoglio(); fatto(); };
  $("#cf-no").onclick = chiudiFoglio;
}

// ------------------------------------------------------------------ carte
const COLORE_GRUPPO = { "Rumori a tavola": "#7a4fe0", "Versi da mostro": "#e0533f", "Facce e gesti": "#e09a1f", "Dispetti innocui": "#2f9e6e",
  "Parole e frasi": "#2f7fd0", "Movimento e ballo": "#d04f9c", "Cibo da mostro": "#c7781a", "A sorpresa": "#5a5ad6" };
const img = n => "disegni/" + String(n).padStart(3, "0") + ".jpg";

function disegnaCarte() {
  const g = Object.entries(S.carte).sort((a, b) => a[0] - b[0]);
  $("#conto").textContent = `${g.length} su ${CARTE.length} giocate`;
  $("#giocate").innerHTML = g.length ? g.map(([n, da]) => `<div class="giocata"><img src="${img(n)}" alt=""><span>${String(n).padStart(3, "0")} · ${esc(CARTE[n - 1].t)}</span><span class="da">${esc(da)}</span></div>`).join("")
    : `<div class="vuoto">Nessuna carta giocata stasera.</div>`;
}
function apriCarta(n, k) {
  n = parseInt(n, 10); const c = CARTE[n - 1];
  if (!c || (k !== null && k !== undefined && String(k).toUpperCase() !== c.k)) {
    apriFoglio(`<h2>Carta non valida</h2><p>Questo QR non è una carta del Mostrometro.</p><button class="secondario" id="cv-ok">Chiudi</button>`);
    $("#cv-ok").onclick = chiudiFoglio; return;
  }
  vai("carte");
  const da = S.carte[n];
  const testa = `<div class="carta-vista" style="--c:${COLORE_GRUPPO[c.g] || "#7a4fe0"}"><div class="num"><span>N. ${String(n).padStart(3, "0")}</span><span>${esc(c.g)}</span></div>
    <img src="${img(n)}" alt=""><div class="testo"><h3>${esc(c.t)}</h3><p>${esc(c.c)}</p><span class="punti">+${c.s ? "2/5" : c.p} mostro</span></div></div>`;
  if (da) { apriFoglio(testa + `<div class="avviso">Questa carta è già stata giocata stasera da ${esc(da)}.</div><button class="secondario" id="cv-ok">Chiudi</button>`); $("#cv-ok").onclick = chiudiFoglio; return; }
  let html = testa + `<h2>Chi l'ha fatto?</h2>${bottoniNomi("cv-chi", "cv-nome")}`;
  if (c.s) html += `<h2 style="margin-top:14px">Chi è stato chiamato Mostro Supremo?</h2>${bottoniNomi("cv-altro", "cv-altro-n")}
      <label class="spunta"><input type="checkbox" id="cv-art">Ha la carta «Artigli da mostro»</label>`;
  html += `<div id="cv-avv" class="avviso"></div><button class="primario" id="cv-ok">ASSEGNA I PUNTI</button>`;
  apriFoglio(html);
  collegaNomi("cv-chi", "cv-nome"); if (c.s) collegaNomi("cv-altro", "cv-altro-n");
  $("#cv-ok").onclick = () => gioca(n, c);
}
function gioca(n, c) {
  const avv = $("#cv-avv"), nome = pulisci($("#cv-nome").value);
  if (!nome) { avv.textContent = "Scegli chi ha fatto l'azione."; return; }
  let punti = c.p, altro = "", puntiAltro = 0;
  if (c.s) {
    altro = pulisci($("#cv-altro-n").value);
    if (!altro) { avv.textContent = "Scegli chi è stato chiamato Mostro Supremo."; return; }
    if (altro.toLowerCase() === nome.toLowerCase()) { avv.textContent = "Non puoi chiamare Mostro Supremo te stesso!"; return; }
    if ($("#cv-art").checked) puntiAltro = c.p; else punti = PUNTI_DA_SOLO;   // la carta Artigli non si consuma
  }
  const nuovi = (trova(nome) ? 0 : 1) + (puntiAltro && !trova(altro) ? 1 : 0);
  if (S.fam.length + nuovi > MAX_FAM) { avv.textContent = "La famiglia è piena (12): togline uno in «Famiglia»."; return; }
  const f = trova(nome) || crea(nome); daiPunti(f, punti);
  let g = null; if (puntiAltro) { g = trova(altro) || crea(altro); daiPunti(g, puntiAltro); }
  S.carte[n] = f.n; S.chi = f.n; salva();
  suona(["bip"]); telefono.vibra(40);
  apriFoglio(`<h2>${esc(f.n)} prende +${punti}${g ? ` e ${esc(g.n)} +${puntiAltro}` : ""}! 🎉</h2>
    <p>I punti salgono quando ${esc(f.n)} preme il naso del Mostrometro.</p>
    <button class="primario" id="cv-mis">Vai a misurarti</button><button class="secondario" id="cv-chiudi">Chiudi</button>`);
  $("#cv-mis").onclick = () => { chiudiFoglio(); vai("mostro"); };
  $("#cv-chiudi").onclick = chiudiFoglio;
  disegnaCarte(); disegnaFamiglia(); aggiornaChi();
}
// i QR delle carte: http://192.168.4.1/c?n=57&k=UABV (anche #carta-57-UABV)
function leggiLink(t) {
  try { const u = new URL(t); const n = u.searchParams.get("n"), k = u.searchParams.get("k"); if (n && k) return { n, k }; } catch (e) {}
  const m = /carta-(\d+)-([A-Za-z]{4})/.exec(t || ""); return m ? { n: m[1], k: m[2] } : null;
}
window.apriLinkCarta = t => { const l = leggiLink(t); if (l) apriCarta(l.n, l.k); };

$("#f-numero").onsubmit = e => { e.preventDefault(); const n = parseInt($("#numero").value, 10); $("#numero").value = ""; if (n >= 1 && n <= CARTE.length) apriCarta(n, null); };
$("#serata").onclick = () => {
  apriFoglio(`<h2>Nuova serata?</h2><p>Tutte le carte tornano giocabili.</p>
    <label class="spunta"><input type="checkbox" id="ns-punti">Azzera anche i punti e le misure di tutti</label>
    <button class="primario" id="ns-si">Nuova serata</button><button class="secondario" id="ns-no">Annulla</button>`);
  $("#ns-si").onclick = () => {
    S.carte = {}; if ($("#ns-punti").checked) S.fam.forEach(f => { f.bonus = 0; f.v = -1; });
    salva(); chiudiFoglio(); disegnaCarte(); disegnaFamiglia(); aggiornaChi();
  };
  $("#ns-no").onclick = chiudiFoglio;
};

// lettore QR con la fotocamera
let flussoVideo = null, cercando = false;
$("#scansiona").onclick = async () => {
  try { flussoVideo = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } }); }
  catch (e) { apriFoglio(`<h2>Fotocamera non disponibile</h2><p>Serve il permesso della fotocamera. Puoi anche scrivere il numero della carta.</p><button class="secondario" id="fc-ok">Chiudi</button>`); $("#fc-ok").onclick = chiudiFoglio; return; }
  const v = $("#video"); v.srcObject = flussoVideo; await v.play(); $("#lettore").hidden = false; cercando = true;
  const tela = document.createElement("canvas"), ctx = tela.getContext("2d", { willReadFrequently: true });
  (function cerca() {
    if (!cercando) return;
    if (v.videoWidth) {
      const s = Math.min(v.videoWidth, v.videoHeight), w = Math.min(640, s);
      tela.width = tela.height = w;
      ctx.drawImage(v, (v.videoWidth - s) / 2, (v.videoHeight - s) / 2, s, s, 0, 0, w, w);
      const q = jsQR(ctx.getImageData(0, 0, w, w).data, w, w, { inversionAttempts: "dontInvert" });
      if (q && q.data) { const l = leggiLink(q.data); if (l) { chiudiLettore(); telefono.vibra(50); apriCarta(l.n, l.k); return; } }
    }
    setTimeout(() => requestAnimationFrame(cerca), 120);
  })();
};
function chiudiLettore() {
  if ($("#lettore").hidden) return false;
  cercando = false; if (flussoVideo) flussoVideo.getTracks().forEach(t => t.stop()); flussoVideo = null; $("#lettore").hidden = true; return true;
}
$("#chiudi-lettore").onclick = chiudiLettore;

// ------------------------------------------------------------------ navigazione
function vai(v) {
  document.querySelectorAll(".vista").forEach(x => x.classList.toggle("attiva", x.id === "v-" + v));
  document.querySelectorAll(".barra button").forEach(b => b.classList.toggle("attivo", b.dataset.v === v));
  if (v === "famiglia") disegnaFamiglia(); if (v === "carte") disegnaCarte();
}
document.querySelectorAll(".barra button").forEach(b => b.onclick = () => vai(b.dataset.v));
window.indietro = () => {                                // tasto indietro di Android
  if (chiudiLettore()) return true;
  if (chiudiFoglio()) return true;
  if (!$("#v-mostro").classList.contains("attiva")) { vai("mostro"); return true; }
  return false;
};

// ------------------------------------------------------------------ avvio
aggiornaChi(); disegnaFamiglia(); disegnaCarte(); sopracciglia(0);
if (location.hash) window.apriLinkCarta(location.hash);
setTimeout(() => ["verso0", "verso1", "verso2", "verso3", "verso4", "verso5", "sei_al", "sei_all", "per_cento", "bip"].forEach(n => carica(n).catch(() => {})), 300);
