// MOSTROMETRO - firmware per LilyGO T-Display S3 Long (ESP32-S3 + schermo lungo 180x640 + ricarica USB-C)
//
// Cosa fa:
//  - Ognuno ha una mostruosita' di BASE fissa, che dipende dal suo nome: se ti
//    misuri due volte di fila, il risultato e' sempre lo stesso.
//  - Dal telefono si segnano le azioni da mostro (rutto a tavola, dispetti...):
//    danno punti, e quando premi di nuovo il bottone la tua mostruosita' sale.
//  - Premi il bottone: il mercurio sale lungo lo schermo fino a 100 e poi scende alla tua
//    percentuale, con un mostriciattolo che si trasforma.
//  - La scheda crea un suo WiFi "Mostrometro": dal telefono apri la pagina
//    (si apre da sola, oppure http://192.168.4.1) e vedi la classifica di famiglia.
//  - La classifica resta salvata nella memoria anche senza corrente.
//  - Funziona a batteria: dopo 5 minuti senza uso va in standby, il bottone lo risveglia.
//
// COME PROVARLO (NON e' stato provato su una scheda vera, vedi sotto):
//  1. Installa le librerie come spiegato nel README del produttore:
//     https://github.com/Xinyuan-LilyGO/T-Display-S3-Long  (copia la cartella lib/ nelle librerie di Arduino:
//     ci sono "GFX Library for Arduino" e XPowersLib).
//  2. Apri l'esempio ufficiale  examples/GFX_AXS15231B_Image  e controlla che lo schermo funzioni.
//  3. Se nell'esempio c'e' una parte che accende il chip di alimentazione (PMU, via I2C), copiala
//     nella funzione schedaInit() qui sotto: potrebbe servire per far funzionare la scheda a batteria.
//  4. Carica questo programma. Scheda: "ESP32S3 Dev Module", PSRAM "OPI PSRAM", flash 16 MB, USB CDC on boot attivo.
//
// Collegamenti:
//   Schermo e ricarica USB-C: sono gia' sulla scheda, non serve collegare niente.
//   Bottone grosso: due fili in parallelo al pulsantino BOOT della scheda (GPIO0). Premere il bottone = GPIO0 a GND.
//     Se il bottone e' premuto mentre la scheda si accende, entra nel modo "download" (schermo nero): rilascia e riaccendi.
//   Batteria LiPo nel connettore della scheda (controlla + e - !). La scheda ha un interruttore: deve stare su ON.

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <Arduino_GFX_Library.h>
#include "driver/rtc_io.h"
#include "esp_sleep.h"

// Pin dello schermo, presi da pins_config.h del produttore (esempio GFX_AXS15231B_Image).
// Nello stesso file i pin 16 e 21 compaiono anche per il touch e per un secondo pulsante: se lo schermo
// non parte, confronta con lo schema della scheda.
#define LCD_CS    12
#define LCD_SCLK  17
#define LCD_SDIO0 13
#define LCD_SDIO1 18
#define LCD_SDIO2 21
#define LCD_SDIO3 14
#define LCD_RST   16
#define LCD_BL     1
#define LCD_W    180
#define LCD_H    640

#define PIN_BTN   0          // pulsante BOOT della scheda: il bottone grosso si collega in parallelo
#define PIN_BAT   8          // lettura della batteria (dal produttore: PIN_BAT_VOLT = 8)
#define BAT_DIV   2.0        // rapporto del partitore: NON trovato nei documenti, controlla (se la % e' sbagliata cambialo)
#define IDLE_MS   300000UL   // dopo 5 minuti senza uso va in standby profondo (schermo e WiFi spenti)

const char* WIFI_SSID = "Mostrometro";
const char* WIFI_PASS = "mostro1234";   // almeno 8 caratteri

#define MAX_FAM 12

Arduino_DataBus *bus = new Arduino_ESP32QSPI(LCD_CS, LCD_SCLK, LCD_SDIO0, LCD_SDIO1, LCD_SDIO2, LCD_SDIO3);
Arduino_GFX *gfx = new Arduino_AXS15231(bus, LCD_RST, 0 /* rotazione */, false /* IPS */, LCD_W, LCD_H);
#define tft (*gfx)      // cosi' il resto del codice usa tft.fillRect(...) come prima
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
uint32_t ultimaAttivita = 0;   // ultimo momento in cui qualcuno ha fatto qualcosa (serve per lo standby)
void attivita() { ultimaAttivita = millis(); }

// Carica della batteria in %, dalla tensione (curva tipica delle LiPo da 3,7 V).
int batteriaPct() {
  float v = analogReadMilliVolts(PIN_BAT) * BAT_DIV / 1000.0;   // il partitore della scheda riduce la tensione
  static const float V[] = {3.30, 3.50, 3.65, 3.75, 3.85, 4.00, 4.15};
  static const int   P[] = {0,    5,    15,   35,   55,   80,   100};
  if (v <= V[0]) return 0;
  for (int i = 1; i < 7; i++)
    if (v <= V[i]) return P[i - 1] + (int)((v - V[i - 1]) * (P[i] - P[i - 1]) / (V[i] - V[i - 1]));
  return 100;
}

// ---------- colori e layout schermo (180 x 640, in verticale) ----------
const uint16_t BG = 0x0000, GRIGIO = 0x4A49, SCURO = 0x1082, BIANCO = 0xFFFF, NERO = 0x0000;
const int TX = 8, TW = 36, TY = 14, TH = 612;          // tubo lungo a sinistra: occupa quasi tutto lo schermo
const int MX = TX + 4, MW = TW - 8;                    // colonna del mercurio
const int MB = TY + TH - 16, MH = TH - 32;             // da dove parte (in basso) e quanto e' alta a 100%
const int PX = 68, PW = 108;                           // pannello a destra
const int CX = 122, CY = 150;                          // centro del mostriciattolo

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
// Frasi con parole di al massimo 9 lettere: nel pannello entrano 9 caratteri per riga.
const char* FRASI[] = {
  "Angelo? Mah...", "Mostrino da divano", "Mostro medio",
  "Mostro serio! Papa ha ragione", "Mostro GIGANTE", "SUPER MOSTRO!!!"
};

// Scrive il testo andando a capo tra le parole (e dove c'e' '\n').
void stampaParole(const char* s, int x, int y, int maxCh, int rigaH) {
  String testo = s, riga = "";
  int n = testo.length(), i = 0, yy = y;
  while (i <= n) {
    int j = i;
    while (j < n && testo[j] != ' ' && testo[j] != '\n') j++;
    String parola = testo.substring(i, j);
    bool aCapo = (j < n && testo[j] == '\n');
    if (riga.length() && riga.length() + 1 + parola.length() > (unsigned)maxCh) {
      tft.setCursor(x, yy); tft.print(riga); yy += rigaH; riga = "";
    }
    if (riga.length()) riga += " ";
    riga += parola;
    if (aCapo || j >= n) { tft.setCursor(x, yy); tft.print(riga); yy += rigaH; riga = ""; }
    i = j + 1;
  }
}

// ---------- disegno ----------
static int mercurioDisegnato = -1;       // altezza (in pixel) gia' disegnata: si ridisegna solo la differenza

void disegnaTubo() {
  tft.fillRect(0, 0, PX - 4, LCD_H, BG);
  tft.fillRoundRect(TX - 4, TY - 4, TW + 8, TH + 8, 22, GRIGIO);
  tft.fillRoundRect(TX, TY, TW, TH, 18, SCURO);
  for (int i = 0; i <= 10; i++) {                       // tacche 0..100
    int y = MB - i * MH / 10;
    tft.drawFastHLine(TX + TW + 6, y, (i % 5 == 0) ? 12 : 6, BIANCO);
  }
  mercurioDisegnato = -1;
}

void disegnaMercurio(int v) {
  int h = v * MH / 100;
  if (mercurioDisegnato < 0) { tft.fillRect(MX, TY + 8, MW, TH - 16, SCURO); mercurioDisegnato = 0; }
  if (h > mercurioDisegnato)
    for (int i = mercurioDisegnato; i < h; i++) tft.drawFastHLine(MX, MB - i, MW, coloreVal(i * 100 / MH));
  else if (h < mercurioDisegnato)
    tft.fillRect(MX, MB - mercurioDisegnato + 1, MW, mercurioDisegnato - h, SCURO);
  mercurioDisegnato = h;
}

void disegnaPercentuale(int v) {
  char buf[12];
  if (v < 0) snprintf(buf, sizeof(buf), " --%%"); else snprintf(buf, sizeof(buf), "%3d%%", v);
  tft.setTextSize(4);
  tft.setTextColor(v < 0 ? GRIGIO : coloreVal(v), BG);
  tft.setCursor(PX, 36);
  tft.print(buf);
}

void disegnaNome() {
  tft.fillRect(PX - 2, 4, PW + 4, 26, BG);
  tft.setTextSize(2);
  tft.setTextColor(BIANCO, BG);
  tft.setCursor(PX, 10);
  String n = chi.length() ? chi : String("Ospite");
  tft.print(n.substring(0, 9));
}

void disegnaBatteria() {                                   // in basso a destra
  int p = batteriaPct();
  uint16_t c = p < 15 ? 0xF800 : (p < 40 ? 0xFD20 : 0x07E0);
  tft.fillRect(PX - 2, 604, PW + 4, 28, BG);
  tft.drawRect(PX, 610, 28, 14, BIANCO);
  tft.fillRect(PX + 28, 614, 3, 6, BIANCO);
  tft.fillRect(PX + 1, 611, p * 26 / 100, 12, c);
  char buf[8]; snprintf(buf, sizeof(buf), "%d%%", p);
  tft.setTextSize(2); tft.setTextColor(BIANCO, BG);
  tft.setCursor(PX + 40, 609); tft.print(buf);
}

void disegnaFrase(const char* s, uint16_t col) {
  tft.fillRect(PX - 2, 206, PW + 4, 150, BG);
  tft.setTextSize(2);
  tft.setTextColor(col, BG);
  stampaParole(s, PX, 212, PW / 12, 20);
}

void disegnaMostro(int v) {
  tft.fillRect(PX - 2, 80, PW + 4, 120, BG);
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
  disegnaBatteria();
  disegnaPercentuale(v);
  disegnaMostro(v);
  if (v < 0) disegnaFrase("Premi il bottone!", BIANCO);
  else disegnaFrase(FRASI[livello(v)], coloreVal(v));
}

// Qui va tutto cio' che serve alla SCHEDA e non a questo programma (per esempio accendere il chip di
// alimentazione via I2C, come fa l'esempio del produttore). Per ora non fa niente.
void schedaInit() {
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

// Standby profondo: schermo e WiFi spenti. Si risveglia premendo il bottone (e il programma riparte da capo).
void dormi() {
  tft.fillScreen(BG);
  tft.setTextSize(3); tft.setTextColor(GRIGIO, BG);
  tft.setCursor(40, 300); tft.print("Zzz...");
  delay(1200);
  digitalWrite(LCD_BL, LOW);
  gfx->displayOff();
  WiFi.mode(WIFI_OFF);
  rtc_gpio_pullup_en((gpio_num_t)PIN_BTN);               // il pull-up deve restare attivo durante il sonno
  rtc_gpio_pulldown_dis((gpio_num_t)PIN_BTN);
  esp_sleep_enable_ext0_wakeup((gpio_num_t)PIN_BTN, 0);  // si sveglia quando il bottone va a GND
  esp_deep_sleep_start();
}

void misura() {
  misurando = true;
  attivita();
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
  disegnaBatteria();
  misurando = false;
  attivita();
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
</style></head><body><main><h1>&#128121; MOSTROMETRO</h1><div class="s" id="bat"></div>
<div class="c"><input id="nome" list="l" maxlength="14" placeholder="Chi si misura?" autocomplete="off"><datalist id="l"></datalist>
<div class="big" id="pct">--%</div><div class="m" id="msg">Scrivi il tuo nome e premi il bottone (anche sul Mostrometro!)</div>
<button id="go">MISURA LA MOSTRUOSITA'</button></div>
<div class="c"><h3>Cosa ha combinato?</h3><div class="a" id="az"></div>
<div class="s" id="azmsg">Scrivi il nome, tocca cosa hai fatto e poi premi di nuovo il bottone: la tua mostruosita sale.</div></div>
<div class="c"><div id="lista"></div><div class="s" id="crown"></div><div class="s" id="avg"></div></div></main>
<script>
const $=s=>document.querySelector(s);
const pul=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^\x20-\x7e]/g,'').replace(/[:;"\\<>&'%]/g,'').trim().slice(0,14);
const FR=['Angelo? Mah...','Mostrino da divano','Mostro medio','Mostro serio! Papa ha ragione','Mostro GIGANTE','SUPER MOSTRO!!!'];
const liv=v=>v<10?0:v<30?1:v<50?2:v<70?3:v<90?4:5;
let ult=-1,aspetto=false;
async function api(p){const r=await fetch(p,{method:'POST'});return r.json()}
async function stato(){try{const d=await(await fetch('/api/stato')).json();disegna(d)}catch(e){$('#msg').textContent='Nessuna risposta. Collegati al WiFi Mostrometro. Se lo sei, il Mostrometro dorme: premi il bottone per svegliarlo.'}}
function disegna(d){
  const nm=$('#nome');if(document.activeElement!==nm&&!nm.value)nm.value=d.chi;
  $('#go').disabled=d.misurando;
  $('#bat').textContent='Batteria '+d.bat+'%'+(d.bat<15?' - da ricaricare!':'');
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
  String j = "{\"bat\":" + String(batteriaPct()) + ",\"chi\":\"" + chi + "\",\"val\":" + String(ultimo) + ",\"misurando\":" +
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
  schedaInit();
  pinMode(LCD_BL, OUTPUT); digitalWrite(LCD_BL, HIGH);
  gfx->begin();
  gfx->fillScreen(BG);

  prefs.begin("mostro", false);
  carica();
  chi = prefs.getString("chi", "");

  WiFi.mode(WIFI_AP);
  WiFi.softAP(WIFI_SSID, WIFI_PASS);
  dns.start(53, "*", WiFi.softAPIP());                   // fa aprire la pagina da sola sul telefono

  server.on("/", HTTP_GET, []() { server.send_P(200, "text/html; charset=utf-8", PAGINA); });
  server.on("/api/stato", HTTP_GET, []() { server.send(200, "application/json", statoJson()); });
  server.on("/api/chi", HTTP_POST, []() {
    chi = pulisci(server.arg("nome"));
    prefs.putString("chi", chi);                         // dopo lo standby si riparte dalla stessa persona
    attivita();
    if (!misurando) disegnaNome();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/misura", HTTP_POST, []() {
    if (misurando || richiestaMisura) { server.send(409, "application/json", "{\"ok\":false}"); return; }
    richiestaMisura = true;
    attivita();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/azione", HTTP_POST, []() {            // azione da mostro: +punti (o -punti per annullare)
    String nome = pulisci(server.arg("nome"));
    if (nome.length() == 0) { server.send(400, "application/json", "{\"ok\":false}"); return; }
    int punti = constrain((int)server.arg("punti").toInt(), -10, 10);
    int i = trova(nome); if (i < 0) i = crea(nome);
    fam[i].bonus = constrain(fam[i].bonus + punti, 0, 100);
    salva();
    attivita();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/elimina", HTTP_POST, []() {
    elimina(pulisci(server.arg("nome")));
    attivita();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.onNotFound([]() {                               // portale "captive": rimanda alla pagina
    server.sendHeader("Location", "http://192.168.4.1/");
    server.send(302, "text/plain", "");
  });
  server.begin();

  attivita();
  if (esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_EXT0) {   // svegliato dal bottone: niente benvenuto, misura subito
    while (digitalRead(PIN_BTN) == LOW) delay(10);
    schermataCompleta(-1);
    richiestaMisura = true;
    return;
  }

  // schermata di benvenuto
  tft.setTextColor(BIANCO, BG); tft.setTextSize(4);
  tft.setCursor(12, 40);  tft.print("MOSTRO");
  tft.setCursor(12, 80);  tft.print("METRO");
  tft.setTextSize(2); tft.setTextColor(0xFFE0, BG);
  tft.setCursor(12, 160); tft.print("WiFi:");
  tft.setCursor(12, 184); tft.print(WIFI_SSID);
  tft.setCursor(12, 230); tft.print("Password:");
  tft.setCursor(12, 254); tft.print(WIFI_PASS);
  uint32_t t0 = millis();
  while (millis() - t0 < 4000) { servizi(); delay(5); }
  schermataCompleta(-1);
}

void loop() {
  servizi();
  if (richiestaMisura) { richiestaMisura = false; misura(); }
  if (!misurando && !richiestaMisura && millis() - ultimaAttivita > IDLE_MS) dormi();   // risparmia la batteria
  static uint32_t ultimoTasto = 0;
  if (digitalRead(PIN_BTN) == LOW && millis() - ultimoTasto > 500) {
    ultimoTasto = millis();
    misura();
    while (digitalRead(PIN_BTN) == LOW) servizi();       // aspetta che lasci il bottone
  }
}
