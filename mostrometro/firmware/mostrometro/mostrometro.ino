// MOSTROMETRO - firmware per ESP32 + schermo ST7789 240x240
//
// Cosa fa:
//  - Ognuno ha una mostruosita' di BASE fissa, che dipende dal suo nome: se ti
//    misuri due volte di fila, il risultato e' sempre lo stesso.
//  - Dal telefono si segnano le azioni da mostro (rutto a tavola, dispetti...):
//    danno punti, e quando premi di nuovo il bottone la tua mostruosita' sale.
//  - Premi il bottone: il mercurio sale fino a 100 e poi scende alla tua
//    percentuale, con un mostriciattolo che si trasforma.
//  - L'ESP32 crea un suo WiFi "Mostrometro": dal telefono apri la pagina
//    (si apre da sola, oppure http://192.168.4.1) e vedi la classifica di famiglia.
//  - La classifica resta salvata nella memoria dell'ESP32 anche senza corrente.
//
// Librerie (Gestione librerie Arduino): "Adafruit GFX Library", "Adafruit ST7735 and ST7789 Library".
// Scheda: "ESP32 Dev Module" (pacchetto esp32 di Espressif).
//
// Collegamenti:
//   Schermo  GND->GND  VCC->3V3  SCL->GPIO18  SDA->GPIO23  RES->GPIO17  DC->GPIO16  BLK->GPIO4  (CS->GPIO5 se c'e')
//   Bottone  un filo a GPIO27, l'altro a GND

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>

#define TFT_CS   5      // se il tuo schermo non ha il pin CS metti -1
#define TFT_DC   16
#define TFT_RST  17
#define TFT_BL   4
#define PIN_BTN  27
#define ROTAZIONE 0     // 0..3: cambialo se lo schermo risulta girato

const char* WIFI_SSID = "Mostrometro";
const char* WIFI_PASS = "mostro1234";   // almeno 8 caratteri

#define MAX_FAM 12

Adafruit_ST7789 tft(TFT_CS, TFT_DC, TFT_RST);
WebServer server(80);
DNSServer dns;
Preferences prefs;

// val   = ultima percentuale mostrata premendo il bottone (-1 = mai misurato)
// bonus = punti guadagnati con le azioni da mostro, in attesa della prossima misura
struct Persona { String nome; int bonus; int val; };
Persona fam[MAX_FAM];
int nFam = 0;
String chi = "";            // chi si sta misurando
int ultimo = -1;            // ultimo risultato (-1 = nessuno)
bool misurando = false;
bool richiestaMisura = false;

// ---------- colori e layout schermo ----------
const uint16_t BG = 0x0000, GRIGIO = 0x4A49, SCURO = 0x1082, BIANCO = 0xFFFF, NERO = 0x0000;
const int TX = 26, TW = 30, TY = 16, TH = 160;          // tubo
const int BCX = TX + TW / 2, BCY = TY + TH + 22, BR = 26; // bulbo
const int CX = 160, CY = 124;                            // centro del mostriciattolo

uint16_t coloreVal(int v) {            // verde -> giallo -> rosso
  int r, g;
  if (v < 50) { r = map(v, 0, 50, 60, 255); g = 220; }
  else        { r = 255; g = map(v, 50, 100, 220, 40); }
  return tft.color565(r, g, 60);
}

int livello(int v) {
  if (v < 10) return 0;
  if (v < 30) return 1;
  if (v < 50) return 2;
  if (v < 70) return 3;
  if (v < 90) return 4;
  return 5;
}
const char* FRASI[] = {
  "Angioletto? Sospetto...", "Mostriciattolo da divano", "Mostro medio",
  "Mostro serio! Papa ha ragione", "Mostro GIGANTE", "MOSTRO SUPREMO!!!"
};

// ---------- disegno ----------
void disegnaTubo() {
  tft.fillRect(0, 0, 76, 240, BG);
  tft.fillRoundRect(TX - 4, TY - 4, TW + 8, TH + 34, 12, GRIGIO);
  tft.fillRoundRect(TX, TY, TW, TH + 30, 10, SCURO);
  tft.fillCircle(BCX, BCY, BR + 4, GRIGIO);
  for (int i = 0; i <= 10; i++) {                       // tacche 0..100
    int y = TY + TH - i * TH / 10;
    int len = (i % 5 == 0) ? 10 : 5;
    tft.drawFastHLine(TX + TW + 6, y, len, BIANCO);
  }
}

void disegnaMercurio(int v) {
  uint16_t c = coloreVal(v);
  int h = v * TH / 100;
  int xc = BCX - 7;
  tft.fillCircle(BCX, BCY, BR, c);
  tft.fillRect(xc, TY + TH, 14, BCY - (TY + TH), c);     // collo del bulbo
  for (int i = 0; i < h; i++)                            // colonna colorata
    tft.drawFastHLine(xc, TY + TH - 1 - i, 14, coloreVal(i * 100 / TH));
  if (TH - h > 0) tft.fillRect(xc, TY, 14, TH - h, SCURO);
}

void disegnaPercentuale(int v) {
  char buf[12];
  if (v < 0) snprintf(buf, sizeof(buf), " --%%"); else snprintf(buf, sizeof(buf), "%3d%%", v);
  tft.setTextSize(5);
  tft.setTextColor(v < 0 ? GRIGIO : coloreVal(v), BG);
  tft.setCursor(84, 28);
  tft.print(buf);
}

void disegnaNome() {
  tft.fillRect(80, 4, 160, 20, BG);
  tft.setTextSize(2);
  tft.setTextColor(BIANCO, BG);
  tft.setCursor(84, 6);
  String n = chi.length() ? chi : String("Ospite");
  tft.print(n.substring(0, 13));
}

void disegnaFrase(const char* s, uint16_t col) {
  tft.fillRect(80, 172, 160, 68, BG);
  tft.setTextSize(2);
  tft.setTextColor(col, BG);
  tft.setCursor(84, 178);
  tft.print(s);
}

void disegnaMostro(int v) {
  tft.fillRect(CX - 80, CY - 56, 160, 104, BG);
  if (v < 0) {                                           // punto interrogativo
    tft.setTextSize(8); tft.setTextColor(GRIGIO, BG);
    tft.setCursor(CX - 24, CY - 32); tft.print("?");
    return;
  }
  uint16_t corpo = tft.color565(80 + v * 17 / 10, max(40, 220 - v * 18 / 10), 120 - v / 2);
  int l = livello(v);
  if (l >= 2) {                                          // corna
    int hh = min(18, 8 + (v - 30) / 3);          // le corna non devono toccare la percentuale
    tft.fillTriangle(CX - 34, CY - 20, CX - 16, CY - 34, CX - 32, CY - 34 - hh, 0xFFE0);
    tft.fillTriangle(CX + 34, CY - 20, CX + 16, CY - 34, CX + 32, CY - 34 - hh, 0xFFE0);
  }
  tft.fillCircle(CX, CY, 36, corpo);
  tft.fillCircle(CX - 14, CY - 8, 9, BIANCO);            // occhi
  tft.fillCircle(CX + 14, CY - 8, 9, BIANCO);
  tft.fillCircle(CX - 14 + (l >= 3 ? 2 : 0), CY - 8, 4, NERO);
  tft.fillCircle(CX + 14 - (l >= 3 ? 2 : 0), CY - 8, 4, NERO);
  if (l >= 5) tft.fillCircle(CX, CY - 24, 6, BIANCO), tft.fillCircle(CX, CY - 24, 3, 0xF800);  // terzo occhio
  if (l >= 3) {                                          // sopracciglia arrabbiate
    tft.drawLine(CX - 26, CY - 22, CX - 6, CY - 14, NERO);
    tft.drawLine(CX - 26, CY - 21, CX - 6, CY - 13, NERO);
    tft.drawLine(CX + 26, CY - 22, CX + 6, CY - 14, NERO);
    tft.drawLine(CX + 26, CY - 21, CX + 6, CY - 13, NERO);
  }
  if (l <= 1) {                                          // sorriso
    tft.drawLine(CX - 14, CY + 12, CX - 7, CY + 18, NERO);
    tft.drawLine(CX - 7, CY + 18, CX + 7, CY + 18, NERO);
    tft.drawLine(CX + 7, CY + 18, CX + 14, CY + 12, NERO);
  } else if (l == 2) {                                   // bocca dritta
    tft.drawLine(CX - 12, CY + 16, CX + 12, CY + 16, NERO);
    tft.drawLine(CX - 12, CY + 17, CX + 12, CY + 17, NERO);
  } else {                                               // boccaccia con i denti
    tft.fillRect(CX - 16, CY + 10, 32, 16, NERO);
    for (int i = 0; i < 4; i++)
      tft.fillTriangle(CX - 16 + i * 8, CY + 10, CX - 12 + i * 8, CY + 18, CX - 8 + i * 8, CY + 10, BIANCO);
    if (l >= 4)
      for (int i = 0; i < 3; i++)
        tft.fillTriangle(CX - 12 + i * 10, CY + 26, CX - 7 + i * 10, CY + 18, CX - 2 + i * 10, CY + 26, BIANCO);
  }
}

void schermataCompleta(int v) {
  tft.fillScreen(BG);
  disegnaTubo();
  disegnaMercurio(v < 0 ? 0 : v);
  disegnaNome();
  disegnaPercentuale(v);
  disegnaMostro(v);
  if (v < 0) disegnaFrase("Premi il bottone!", BIANCO);
  else disegnaFrase(FRASI[livello(v)], coloreVal(v));
}

// ---------- memoria ----------
void carica() {
  String s = prefs.getString("fam", "");
  nFam = 0;
  int i = 0;
  while (i < (int)s.length() && nFam < MAX_FAM) {
    int pv = s.indexOf(';', i);
    if (pv < 0) pv = s.length();
    String r = s.substring(i, pv);
    int c1 = r.indexOf(':');
    int c2 = r.indexOf(':', c1 + 1);
    if (c1 > 0 && c2 > c1) {
      fam[nFam].nome = r.substring(0, c1);
      fam[nFam].bonus = r.substring(c1 + 1, c2).toInt();
      fam[nFam].val = r.substring(c2 + 1).toInt();
      nFam++;
    }
    i = pv + 1;
  }
}

void salva() {
  String s = "";
  for (int i = 0; i < nFam; i++) { if (i) s += ";"; s += fam[i].nome + ":" + String(fam[i].bonus) + ":" + String(fam[i].val); }
  prefs.putString("fam", s);
}

int trova(const String& nome) {
  for (int i = 0; i < nFam; i++)
    if (fam[i].nome.equalsIgnoreCase(nome)) return i;
  return -1;
}

int crea(const String& nome) {
  if (nFam == MAX_FAM) { for (int i = 1; i < nFam; i++) fam[i - 1] = fam[i]; nFam--; }  // butta il piu' vecchio
  fam[nFam].nome = nome; fam[nFam].bonus = 0; fam[nFam].val = -1;
  nFam++;
  salva();
  return nFam - 1;
}

// Mostruosita' di BASE: dipende solo dal nome (maiuscole ignorate), quindi e' sempre la stessa.
// Va da 10 a 65, cosi' c'e' spazio per salire con le azioni da mostro.
int baseDi(String nome) {
  nome.toLowerCase();
  uint32_t h = 2166136261u;                       // hash FNV-1a
  for (unsigned i = 0; i < nome.length(); i++) { h ^= (uint8_t)nome[i]; h *= 16777619u; }
  return 10 + (int)(h % 56);
}

// Quanto sei mostro adesso = base + punti delle azioni da mostro (massimo 100).
int valoreAttuale(int i) { return min(100, baseDi(fam[i].nome) + fam[i].bonus); }

void elimina(const String& nome) {
  for (int i = 0; i < nFam; i++)
    if (fam[i].nome.equalsIgnoreCase(nome)) {
      for (int j = i + 1; j < nFam; j++) fam[j - 1] = fam[j];
      nFam--; salva(); return;
    }
}

// solo caratteri ASCII stampabili (lo schermo non ha le lettere accentate)
String pulisci(String s) {
  String o = "";
  for (unsigned i = 0; i < s.length() && o.length() < 14; i++) {
    char c = s[i];
    if (c < 32 || c > 126) continue;
    if (strchr(":;\"\\<>&'%", c)) continue;
    o += c;
  }
  o.trim();
  return o;
}

// ---------- misura ----------
void servizi() { dns.processNextRequest(); server.handleClient(); }

void misura() {
  misurando = true;
  String nome = chi.length() ? chi : String("Ospite");
  int idx = trova(nome); if (idx < 0) idx = crea(nome);
  int target = valoreAttuale(idx);            // sempre uguale, finche' non guadagni punti
  int prima = fam[idx].val;                   // -1 se non ti eri mai misurato
  disegnaFrase("Misuro...", BIANCO);
  int ultimoLiv = -1;
  for (int v = 0; v <= 100; v += 2) {                    // sale fino in cima
    disegnaMercurio(v); disegnaPercentuale(v);
    if (livello(v) != ultimoLiv) { ultimoLiv = livello(v); disegnaMostro(v); }
    servizi(); delay(14);
  }
  for (int v = 100; v >= target; v--) {                  // ...e scende alla tua percentuale
    disegnaMercurio(v); disegnaPercentuale(v);
    if (livello(v) != ultimoLiv) { ultimoLiv = livello(v); disegnaMostro(v); }
    servizi(); delay(22);
  }
  disegnaMostro(target);
  String f = FRASI[livello(target)];
  if (prima >= 0 && target > prima) f = "+" + String(target - prima) + " mostro!\n" + f;
  disegnaFrase(f.c_str(), coloreVal(target));
  ultimo = target;
  idx = trova(nome); if (idx < 0) idx = crea(nome);   // qualcuno puo' averti tolto dalla lista mentre misuravi
  fam[idx].val = target;
  salva();
  misurando = false;
}

// ---------- pagina web ----------
const char PAGINA[] PROGMEM = R"=====(<!doctype html><html lang="it"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Mostrometro</title>
<style>
body{margin:0;background:#1b1030;color:#fff4ff;font-family:system-ui,sans-serif}
main{max-width:520px;margin:0 auto;padding:16px}h1{text-align:center;margin:8px 0}
.c{background:#2a1a4a;border-radius:18px;padding:16px;margin-bottom:14px}
input{width:100%;box-sizing:border-box;padding:12px;border-radius:10px;border:2px solid #4a3480;background:#1b1030;color:#fff;font-size:1.1rem}
button{width:100%;padding:16px;border:0;border-radius:14px;font-size:1.2rem;font-weight:800;background:linear-gradient(90deg,#ff9340,#ff3d5a);color:#fff;margin-top:12px}
button:disabled{opacity:.5}.big{font-size:3.2rem;font-weight:900;text-align:center}.m{text-align:center;color:#ffd84a;min-height:1.4em}
.r{display:flex;align-items:center;gap:8px;padding:9px 0;border-bottom:1px solid #3d2a68}.r:last-child{border:0}
.n{flex:0 0 100px;font-weight:700;overflow:hidden;text-overflow:ellipsis}.b{flex:1;height:16px;border-radius:8px;background:#120a22;overflow:hidden}
.b i{display:block;height:100%;background:linear-gradient(90deg,#52e08a,#ffd84a,#ff9340,#ff3d5a)}.v{flex:0 0 46px;text-align:right;font-weight:800}
.x{width:auto;padding:2px 8px;margin:0;background:none;font-size:1rem;color:#b9a6dd}.s{text-align:center;color:#b9a6dd;margin-top:8px}
.a{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}.a button{width:auto;margin:0;padding:10px 12px;font-size:.95rem;background:#4a3480}
.p{color:#ffd84a;font-size:.8rem;font-weight:400}h3{margin:0}
</style></head><body><main><h1>&#128121; MOSTROMETRO</h1>
<div class="c"><input id="nome" list="l" maxlength="14" placeholder="Chi si misura?" autocomplete="off"><datalist id="l"></datalist>
<div class="big" id="pct">--%</div><div class="m" id="msg">Scrivi il tuo nome e premi il bottone (anche sul Mostrometro!)</div>
<button id="go">MISURA LA MOSTRUOSITA'</button></div>
<div class="c"><h3>Cosa ha combinato?</h3><div class="a" id="az"></div>
<div class="s" id="azmsg">Scrivi il nome, tocca cosa hai fatto e poi premi di nuovo il bottone: la tua mostruosita sale.</div></div>
<div class="c"><div id="lista"></div><div class="s" id="crown"></div><div class="s" id="avg"></div></div></main>
<script>
const $=s=>document.querySelector(s);
const pul=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^\x20-\x7e]/g,'').replace(/[:;"\\<>&'%]/g,'').trim().slice(0,14);
const FR=['Angioletto? Sospetto...','Mostriciattolo da divano','Mostro medio','Mostro serio! Papa ha ragione','Mostro GIGANTE','MOSTRO SUPREMO!!!'];
const liv=v=>v<10?0:v<30?1:v<50?2:v<70?3:v<90?4:5;
let ult=-1,aspetto=false;
async function api(p){const r=await fetch(p,{method:'POST'});return r.json()}
async function stato(){try{const d=await(await fetch('/api/stato')).json();disegna(d)}catch(e){$('#msg').textContent='Non sei collegato al WiFi Mostrometro'}}
function disegna(d){
  const nm=$('#nome');if(document.activeElement!==nm&&!nm.value)nm.value=d.chi;
  $('#go').disabled=d.misurando;
  if(d.misurando){$('#pct').textContent='...';$('#msg').textContent='Misuro...';aspetto=true}
  else if(d.val>=0){$('#pct').textContent=d.val+'%';$('#msg').textContent=FR[liv(d.val)]}
  $('#l').innerHTML=d.fam.map(f=>'<option value="'+f.n+'">').join('');
  const L=$('#lista');L.innerHTML='';
  const o=[...d.fam].sort((a,b)=>b.v-a.v);
  if(!o.length){L.textContent='Nessun mostro ancora!';$('#crown').textContent='';$('#avg').textContent='';return}
  o.forEach(f=>{const r=document.createElement('div');r.className='r';
    r.innerHTML='<div class="n"></div><div class="b"><i style="width:'+Math.max(0,f.v)+'%"></i></div><div class="v">'+(f.v<0?'?':f.v+'%')+'</div><button class="x">&#10005;</button>';
    const ne=r.querySelector('.n');ne.textContent=f.n;
    if(f.p>0){const s=document.createElement('div');s.className='p';s.textContent='+'+f.p+' in attesa';ne.appendChild(s)}
    r.querySelector('.x').onclick=async()=>{if(confirm('Togliere '+f.n+'?')){await api('/api/elimina?nome='+encodeURIComponent(f.n));stato()}};
    L.appendChild(r)});
  const mis=o.filter(f=>f.v>=0);
  $('#crown').textContent=mis.length?'\u{1F451} Mostro della famiglia: '+mis[0].n+' ('+mis[0].v+'%)':'';
  $('#avg').textContent=mis.length?'Mostruosita media: '+Math.round(mis.reduce((s,f)=>s+f.v,0)/mis.length)+'%':'';
}
const AZ=[['Rutto a tavola',3],['Calzini in giro',4],['Mangia con le mani',4],['Urla da mostro',5],['Non mette a posto',5],['Fa un dispetto',6],['Spaventa qualcuno',8]];
let ultima=null;
AZ.forEach(([t,p])=>{const b=document.createElement('button');b.textContent=t+' +'+p;b.onclick=()=>azione(p,t);$('#az').appendChild(b)});
const un=document.createElement('button');un.textContent="Annulla l'ultima";un.onclick=()=>{if(ultima)azione(-ultima,null)};$('#az').appendChild(un);
async function azione(p,t){
  const n=pul($('#nome').value),m=$('#azmsg');
  if(!n){m.textContent='Scrivi prima il tuo nome!';$('#nome').focus();return}
  await api('/api/chi?nome='+encodeURIComponent(n));
  await api('/api/azione?nome='+encodeURIComponent(n)+'&punti='+p);
  if(t){ultima=p;m.textContent=n+': '+t+' (+'+p+'). Premi il bottone per vedere quanto sei salito!'}else{ultima=null;m.textContent='Annullato.'}
  stato()}
$('#nome').onchange=()=>api('/api/chi?nome='+encodeURIComponent(pul($('#nome').value)));
$('#go').onclick=async()=>{await api('/api/chi?nome='+encodeURIComponent(pul($('#nome').value)));await api('/api/misura');stato()};
stato();setInterval(stato,1000);
</script></body></html>)=====";

String statoJson() {
  String j = "{\"chi\":\"" + chi + "\",\"val\":" + String(ultimo) + ",\"misurando\":" +
             (misurando || richiestaMisura ? "true" : "false") + ",\"fam\":[";
  for (int i = 0; i < nFam; i++) {
    if (i) j += ",";
    int att = valoreAttuale(i);
    int p = (fam[i].val >= 0 && att > fam[i].val) ? att - fam[i].val : 0;   // punti in attesa del prossimo bottone
    j += "{\"n\":\"" + fam[i].nome + "\",\"v\":" + String(fam[i].val) + ",\"p\":" + String(p) + "}";
  }
  return j + "]}";
}

// ---------- setup / loop ----------
void setup() {
  Serial.begin(115200);
  pinMode(PIN_BTN, INPUT_PULLUP);
  pinMode(TFT_BL, OUTPUT); digitalWrite(TFT_BL, HIGH);
  tft.init(240, 240, SPI_MODE3);
  tft.setRotation(ROTAZIONE);
  tft.fillScreen(BG);

  prefs.begin("mostro", false);
  carica();

  WiFi.mode(WIFI_AP);
  WiFi.softAP(WIFI_SSID, WIFI_PASS);
  dns.start(53, "*", WiFi.softAPIP());                   // fa aprire la pagina da sola sul telefono

  server.on("/", HTTP_GET, []() { server.send_P(200, "text/html; charset=utf-8", PAGINA); });
  server.on("/api/stato", HTTP_GET, []() { server.send(200, "application/json", statoJson()); });
  server.on("/api/chi", HTTP_POST, []() {
    chi = pulisci(server.arg("nome"));
    if (!misurando) disegnaNome();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/misura", HTTP_POST, []() {
    if (misurando || richiestaMisura) { server.send(409, "application/json", "{\"ok\":false}"); return; }
    richiestaMisura = true;
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/azione", HTTP_POST, []() {            // azione da mostro: +punti (o -punti per annullare)
    String nome = pulisci(server.arg("nome"));
    if (nome.length() == 0) { server.send(400, "application/json", "{\"ok\":false}"); return; }
    int punti = constrain((int)server.arg("punti").toInt(), -10, 10);
    int i = trova(nome); if (i < 0) i = crea(nome);
    fam[i].bonus = constrain(fam[i].bonus + punti, 0, 100);
    salva();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/elimina", HTTP_POST, []() {
    elimina(pulisci(server.arg("nome")));
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.onNotFound([]() {                               // portale "captive": rimanda alla pagina
    server.sendHeader("Location", "http://192.168.4.1/");
    server.send(302, "text/plain", "");
  });
  server.begin();

  // schermata di benvenuto
  tft.setTextColor(BIANCO, BG); tft.setTextSize(3);
  tft.setCursor(20, 30);  tft.print("MOSTROMETRO");
  tft.setTextSize(2); tft.setTextColor(0xFFE0, BG);
  tft.setCursor(20, 100); tft.print("WiFi:");
  tft.setCursor(20, 124); tft.print(WIFI_SSID);
  tft.setCursor(20, 156); tft.print("Password:");
  tft.setCursor(20, 180); tft.print(WIFI_PASS);
  uint32_t t0 = millis();
  while (millis() - t0 < 4000) { servizi(); delay(5); }
  schermataCompleta(-1);
}

void loop() {
  servizi();
  if (richiestaMisura) { richiestaMisura = false; misura(); }
  static uint32_t ultimoTasto = 0;
  if (digitalRead(PIN_BTN) == LOW && millis() - ultimoTasto > 500) {
    ultimoTasto = millis();
    misura();
    while (digitalRead(PIN_BTN) == LOW) servizi();       // aspetta che lasci il bottone
  }
}
