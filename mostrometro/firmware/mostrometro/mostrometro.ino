// MOSTROMETRO - firmware per Waveshare ESP32-S3-Touch-LCD-3.49 (versione V2)
// Schermo lungo 172x640, due microfoni, altoparlante, ricarica USB-C e batteria sulla stessa scheda.
//
// Cosa fa:
//  - Ognuno ha una mostruosita' di BASE fissa, che dipende dal suo nome: se ti misuri due volte
//    di fila, il risultato e' sempre lo stesso.
//  - Premi il naso (il bottone): il mostro fa il suo verso mentre il mercurio sale lungo lo schermo,
//    poi scende alla tua percentuale e il mostro dice "sei al sessanta per cento".
//  - Tieni premuto il naso per un secondo (o usa il telefono): "Urla da mostro!". Il microfono ascolta
//    per 2 secondi e piu' urli forte, piu' punti prendi (da 0 a 10). I punti si aggiungono alla tua
//    mostruosita' e la prossima volta che premi il naso il mercurio sale.
//  - Dal telefono si segnano anche le altre azioni da mostro (rutto a tavola, dispetti...).
//  - La scheda crea un suo WiFi "Mostrometro": dal telefono apri la pagina
//    (si apre da sola, oppure http://192.168.4.1) e vedi la classifica di famiglia.
//  - La classifica resta salvata nella memoria anche senza corrente.
//  - Funziona a batteria: dopo 5 minuti senza uso va in standby, il naso lo risveglia.
//
// COME SI CARICA: leggi la guida (progetto.html) e il file LEGGIMI.txt in questa cartella.
// Tutti i dettagli della scheda (pin, schermo, audio, accensione a batteria) sono nel file scheda.h.
// Questo programma NON e' mai girato su una scheda vera: puo' servire qualche ritocco.

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include "scheda.h"          // schermo, audio, batteria, bottone: tutto cio' che riguarda la scheda

#define IDLE_MS   300000UL   // dopo 5 minuti senza uso va in standby profondo (schermo e WiFi spenti)

const char* WIFI_SSID = "Mostrometro";
const char* WIFI_PASS = "mostro1234";   // almeno 8 caratteri

#define MAX_FAM 12

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
bool richiestaUrlo = false;
uint32_t ultimaAttivita = 0;   // ultimo momento in cui qualcuno ha fatto qualcosa (serve per lo standby)
void attivita() { ultimaAttivita = millis(); }

// ---------- colori e layout schermo (172 x 640, in verticale) ----------
const uint16_t BG = 0x0000, GRIGIO = 0x4A49, SCURO = 0x1082, BIANCO = 0xFFFF, NERO = 0x0000;
const int TX = 8, TW = 36, TY = 14, TH = 612;          // tubo lungo a sinistra: occupa quasi tutto lo schermo
const int MX = TX + 4, MW = TW - 8;                    // colonna del mercurio
const int MB = TY + TH - 16, MH = TH - 32;             // da dove parte (in basso) e quanto e' alta a 100%
const int PX = 66, PW = 104;                           // pannello a destra
const int CX = 118, CY = 150;                          // centro del mostriciattolo

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
// Frasi con parole di al massimo 8 lettere: nel pannello entrano 8 caratteri per riga.
const char* FRASI[] = {
  "Angelo? Mah...", "Mostrino da divano", "Mostro medio",
  "Mostro serio! Papa ha ragione", "Mostro GIGANTE", "SUPER MOSTRO!"
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
  tft.print(n.substring(0, 8));
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

void dormi() {
  tft.fillScreen(BG);
  tft.setTextSize(3); tft.setTextColor(GRIGIO, BG);
  tft.setCursor(30, 300); tft.print("Zzz...");
  mostra();
  delay(1200);
  WiFi.mode(WIFI_OFF);
  schedaDormi();                                          // spegne tutto; il naso lo risveglia
}

// "sei al sessanta per cento": davanti a uno, otto, undici e agli ottanta si dice "sei all'..."
void dilloIn(int pct) {
  bool vocale = (pct == 1 || pct == 8 || pct == 11 || (pct >= 80 && pct <= 89));
  audioAccoda(vocale ? CLIP_SEI_ALL : CLIP_SEI_AL);
  audioAccoda(CLIP_NUMERO0 + pct);
  audioAccoda(CLIP_PER_CENTO);
}

void aspettaAudio() { while (audioOccupato()) { servizi(); delay(10); } }

void misura() {
  misurando = true;
  attivita();
  String nome = chi.length() ? chi : String("Ospite");
  int idx = trova(nome); if (idx < 0) idx = crea(nome);
  int target = valoreAttuale(idx);            // sempre uguale, finche' non guadagni punti
  int prima = fam[idx].val;                   // -1 se non ti eri mai misurato
  disegnaFrase("Misuro...", BIANCO);
  mostra();
  audioAccoda(CLIP_VERSO0 + livello(target)); // il verso del mostro parte subito e dura mentre il mercurio sale
  int ultimoLiv = -1;
  for (int v = 0; v <= 100; v += 2) {                    // sale fino in cima
    disegnaMercurio(v); disegnaPercentuale(v);
    if (livello(v) != ultimoLiv) { ultimoLiv = livello(v); disegnaMostro(v); }
    mostra(); servizi(); delay(14);
  }
  for (int v = 100; v >= target; v--) {                  // ...e scende alla tua percentuale
    disegnaMercurio(v); disegnaPercentuale(v);
    if (livello(v) != ultimoLiv) { ultimoLiv = livello(v); disegnaMostro(v); }
    mostra(); servizi(); delay(22);
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
  mostra();
  dilloIn(target);                                      // "sei al sessanta per cento"
  aspettaAudio();
  misurando = false;
  attivita();
}

// Urlo da mostro: il microfono ascolta 2 secondi e il piu' forte momento diventa punti (0..10).
void urla() {
  misurando = true;
  attivita();
  String nome = chi.length() ? chi : String("Ospite");
  disegnaFrase("URLA DA MOSTRO!", 0xF800);
  mostra();
  audioAccoda(CLIP_URLA);
  audioAccoda(CLIP_BIP);
  aspettaAudio();
  float db = microfonoPicco(2000);
  int punti = puntiDaDb(db);
  int idx = trova(nome); if (idx < 0) idx = crea(nome);
  fam[idx].bonus = constrain(fam[idx].bonus + punti, 0, 100);
  salva();
  String f = "Urlo da " + String(punti) + " punti!\nPremi il naso";
  disegnaFrase(f.c_str(), 0xFFE0);
  mostra();
  audioAccoda(CLIP_URLO_DA);
  audioAccoda(CLIP_NUMERO0 + punti);
  audioAccoda(CLIP_PUNTI);
  aspettaAudio();
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
.hero{text-align:center;padding-top:6px}.hero img{width:110px;height:110px;border-radius:50%;display:block;margin:0 auto;border:3px solid #4a3480}
.add{display:flex;gap:8px;margin:10px 0 4px}.add input{flex:1;min-width:0}.add button{width:auto;margin:0;padding:12px 16px;font-size:1rem;background:#4a3480}
.n{cursor:pointer}.n:hover{text-decoration:underline}
</style></head><body><main><div class="hero"><img alt="La mascotte del Mostrometro" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCADIAMgDASIAAhEBAxEB/8QAHAABAAICAwEAAAAAAAAAAAAAAAUGBAcBAwgC/8QARxAAAQMDAQUEBgUICQQDAAAAAQACAwQFEQYSITFBUQcTYXEUFSKBkaEjMkJSsRY0Q2JydJKyJDM1U4LB0eHwCBcloiZz0v/EABsBAQACAwEBAAAAAAAAAAAAAAACAwEEBQYH/8QALxEAAgIBAwMBBgYDAQAAAAAAAAECAxEEEjEFIUFxExQzUWGBBiIykaHBQrHh8P/aAAwDAQACEQMRAD8A9KIiLlG6EREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEyqP2mamrrU222XT5jF/u8hjge8bTaeNv15iOeOXj5KD09cr5pjW1ss9+vk95tt4je2Ceqja18NSwZ2QR9lw4BSxHKg5Lc02l5aXP9+uGSUG1u8G1ERPJRIhFX79rPTdgcW3e9UNNKP0RlDpP4W5PyVXl7Y9NFxFDT3qv6Gmt78H3uwr4ae2zvGLYw2bIRay/7vUWc/kzqfZ6+iN//S7Yu2PTQcBXU96oOpqbe/A97cqb0V6/wZnazZCKv2HWem7+4NtF7oamQ/ohKGyfwuwfkrAteUZReJLBgIi1XqO5X3U2t7lZbDe57NbbREwVFRTRtc+WoeM7GT9lo4hYbjGLnN4iuX/BmMXJ4RtRFRuzPU1bdBcrLqAsN/tEgjnkYNltRG76koHLPPx81eVmUdrMNYeGERFEBERAEREAREQBERAEREBqK4P9L7brnLKci222mgiB+z3ji9xU1rLT7dR2gU7J3UtbBK2opKpvGGZu9rvLkfBQms4jZO1qmrpvZor7RNpQ88BURHIafNpGE1brGa1xQWu0wtqtQVQ+hY76kTOcsnQDpzXL1tOps6hX7svzNR2/bn7Zzk6NW10JnbF2tSWeM2zVdkrW6kY0d3DRtEkdaeAex2fZB47xu3+Sr15ueptSOd+UFzdaLe7hbLY/DyOkkvE+Q3LAtlCy3PmqHTvrLrUHaqa+Xe+Q9G/db4LIPzX0LSdMhUlOxJy8/LP0yURpXLOigt1pte+22umif/eyN7x58S471IOrqk7u9IHQbljIuoopcFqSR3elVGf65/xX22uqQMd6SOjt6xkTCMnRX261XP8AtK100ruUrG928eIcN6zbPc9TabLTp+6Ou1vZxtd0dl4HSOXiPI7l0oqrdPXcts1kjKtS5LRJ2tSXiMWzStkrXake095DWNEcVGRuLnuz7QHHcN+7yUto2wDTtpMEk7qquqJXVNZVO4zTO+s7y5DwWuLlQsuL4Z2zvo7rTnNNXxbnxno77zfBWzSOsprpHPa7tC2m1BSj6ZjfqSs5Sx9QenJeE/E3T76Kk6fhefnnxn6f+YprUZY8n1QvFH23WqWLcLlbqmCXH2u7Ie0rbi1Do2P152tz1sPtUdhonUxeOBqJTvb5hoOVt5VURlHT1Rlzt/ttfxg19Tj2rwERFMpCIiAIiIAiIgCIiAIiICldsTbOdAXKS/teYYwHQGM4lFRwj7s8nZ+WVqHTtBU0lNJU3WV095rAHVUzzlwAAxGPAc/HyVl7ULn6+17T2ljtq32FoqJ28n1Tx7AP7Ld/mSo4r1XSdLsqVkuXx9F/02aY9sny7cCeQ4lc2C33nVDJKjT1HB6siJa+410phgJHHYwC54HXGPFROpg6S3R0jHmM11TDRl44tbI8NJ+GV9f9R16lobrQ6PtpNJY7fSRH0dh2WyOOdna6gADA6klb2oulGSrhyxbZJNRiT81iu9PDJNE+03iCIbUrrPV98+IdTGRkj9nJ8FhMc17GvY4Oa4ZBByCFE9nl50HZezerqKktptYxd66KZjHekd5v7oxOG4N+rkcOO0CCrHXvjq6a13SKNkIulFFXPiYMNZI8HbAHTaDj71HT3zlJwn+5Gm2Te2RiL5e5rGuc9wa1oySTgAdV9LNt746WG5XOaJk7bXRS1zYnjLZHsA2AR02iD7ltTlsi5F8pbVk+YrDd54o5ZJLRaIJhtQuu9X3L5R1EYGQPMg+Cw7/b71pgRz6goYPVchAbcqGYzQAnht5AcwHqRjxWpbLcqS5a3oq/WssldSSVTX173kvc5vPON+znG4csgL0TpzUGlLtrd2kNMtgqNN3C2S+kwQsLYGSgj6gI3ZYTtY3ZDTxyudPUXVyy+69OxqSusi8lPG8ZByD0UbqChqaumjqbXK6C80YLqSZhw47t8ZPQ8vHzXzphrobdLRveZDQ1M1GHni5sby0H4YUtzyug4xthiSymbie5ZNldjbLO3s/t0lha8RygvqTKcymo4Sd4fvZ+WFdlpHswunqLXs9rkds2+/NM8LeTKtg9oD9pu/zAW7l4zXUSpvlF+poyW14YREWmYCIiAIiIAiIgCIiALGudbDbbdVV1ScQU0T5nn9VoJP4LJWuu3m4updAy0ELsVF2njoGAccOOX/8Aq0/FW01+1sjD5sYz2NWaWMtRb5bnV5NZdJ31sxPHLzkD3DCmV8QxthhjiYMMjaGN8gMLMtzWOqfpADgZAPVe3smtPU5Y7RR0qq90lBEHqSgq7jaXwULWCUva5sj3FvdlpyHDAOSCAu27XjUldqWnv9XZdOVVfHRPonteXuZK08HFrtwcN/Dk4hW/gou6NaJmlv1yPaC5Om18NbaoThj7mxqunxhHe3k1Dp/RlVW3yChvE3qqkdlz6lzDICBxazZyC8jgCQPwW27nUQzzxtpIjDRU8TKamiJyWRMbstB8eZ8SVSrhqCaK708ncV0Fpp3PZUyuhOy9x3Dx2Qd+VY6Ksp66ES0c8c8Z5sdldaEIqWUaMIpPJ3rLttRFBUPbVxGajnifTVMQOC+J7dlwHjg5HiAsXf0Kx62rp6KIy1k8cEY+1I4BWyipJp8E2k1hlS1xaa2YWrT9op6CuorVG4RXCmgMUkrXnIE5dgbYxvAyMknngZnZ3T6h0Xcam40NJapa2aAwMfUyvPcgnJIDRjJwOPTxXxQ6hmku88ggrai0TuZHTSthOyx/A+OyeqvFrawzOLsF4HshaVyrpplNptIjTpo2yUM8lf01QVdvtTYa5rTMHue6Rji7vC45LjkDBJJUorCoi5NY2oxGADjLgOq19B1P3mfsnHB0L9H7GG5PJXNUd9Bbo7jR5FZbJmVsJHHLDkj3jK9HWuuhudspK+mOYKqJk7P2XAEfitDyxtlifG8ZY9pafIjCvnYLcHVOgmW6Z2ai0VElC8Hjsg7TP/V3yVHXKcwjYvHY5N8eGbGREXmigIiIAiIgCIiAIixrlXU1st9RW10zYaWnjMssjuDWgbyspZ7IGLqK+W7TtpmuV4qWU9JFxcd5ceTWjiXHkAvP981dVa91nRmegdQW61xvqKeGQ5kc54Aa9/IEjeByHVdlwudXrW+Nv12a6O3RE+raJ/CJn964c3nj/wACjdI/0ptxurvrVtS4tP6jfZb/AJr1HT+mqnFln6v9F9dfdNli5LgHBBXCLsmyd/pU+Md67C6i4kkuOT1K+UUIVQh3hFL0ROU5S5eQfayDvB3EFQtdpi1VDzK2lMMvEupnmIn4blOxsdI7DGlx8Asllvndx2WeZU2k+StpPkpv5Pw/V9Ovmz9zvz+Ky6LTNqgeJX0pnl4h1S8ykfHcrX6rl++P4Sup9vnb9XZd5FR2xG1GI0bIwNwG4AclzkgggkEcCFzIx8bsPaWnxC+VLkkd5q59nHeuXTkk5O8lcIoQqhX+iKXoiUpyl+p5OVF2TV1XoPWdW6ChdXW+6xsnqIYziQOZkOezkSAckcx0Umq9q/8AosdvujR7VDUtc4/qO9l3+SjqKo3VuE+CmyO6Pc9H6dvtu1FaYblZ6ltRSy8HDcWnm1w4hw5gqTXnCgudXou9m/WhrpLfIR6yomcJo/7xo5PHH/hXoa2V9Nc7fTV1BM2alqIxLFI3g5p4FeR12ilpJ45T4NScHB4ZkoiLQIhERAEREAWm+2y6uu14oNJUzyKZoFdctk8Wg/RxnzO/4LchxzOBzPRearVWOvV0vd/kyXXKteWZ5RMOywfALrdI06tu3PiJOqO6R96hqfQ7BXzDDe7gcG45HGB+K509SCisdBT82Qtz5kZPzKjtdu/+PPjH6aaKP4u/2VgaMNAHADC9X5NzycoiKRILOo6EvAfNkN5N5lLbTCQ97IPZB3DqVKLDZg63uhpYHveWRQxtLnOO4NA4krVeoNa3C6TPitMrqGgBw2Vo+llHXP2R4BWTtWrHQ6ehpGEj02cROI+6BtEfILWwGAAOAVMn3wcvqOrlTiEOWSfqu7G3es/TKzYxtbfpTtvGfrYzwUjp/W1wtczIrrM6ut+cOkcMyxDrn7Q8Cpx0TxoAvdG/u/Q87WycY81Aalmu7KCkpLvQUNLDIxssRipII3vaBgEvYMnjwJ3rmaDVzvc847Sa+yOJouo6jdKU32TNsRvhq6dkkbmSwyNDmuG8OB4EKPrKEsBfDkt5t5hV7sorHz6fnpJCSKOoMbM/cI2gPdkq6rrxeVk9bCSlFSXkrqLOuVNsHvYxhpO8DkVgqZMLAv8AS+m2Supjv7yFwHmBkfMLPXB3gg8DuWMZ7GGR2naj0zT9BMfaL4Gh2eZAwfwVu7FLq60Xqv0lUPPosgdXW3aPBpP0kY8j7Q96oOhCfyfER/Qzyx/B2f8ANZt3rHWa42W/R7n22tjc/HOJ52XjywVp62hajTuPn+yqcd0D0siAgjLTkcj1CLxJphERDIREQGFe3ujs1wfH9dtNKW46hhXnDRLQ3SdrxzhyfMkr01IxsjHMkGWOBa4dQeK8xWqOTTldctO14d31uqHtZ+tETljh4EELv9CmlKcfPYuof5jq1z/ZtH09Niz8SrDG7aja7qAqrracz2V7mAhsEjJd/E4d/urDbZRLStLTkD8OI/FeiXLNlcsy1yxpe9rW8XHAXysq2N2qtpPIEqRImI2CNjWN4NGFyhQKBgoHa7+a2b95f/IqCDwV97XfzWzfvL/5FQQqpcs8/wBV+KvQ3mDjsR6/+L4LT9xp7NFRRvttdXTVbiO8ilo2xMG7fhweScHwVg9eXEaNNCax4o/Ru77vAxs9OGVFagoLs2jpqyt0+LZSBojbNFRuhZKSMguJJ2nEDivN9BolQ79z5m2bPWdLLTqnd33QTLB2Rfmt5/eWfyLYC1/2Rfmt5/eWfyK/r08ODoaf4UfQ4kYJGOY7gRgqAe0se5ruLTgqwhQ1ybs1bj94AqxF5jL5kdsxud0BXKxrjKIqVxJwD+HErJkhtDf2dW44emy4+SydaNDtKXQO5QkjzBGFG6JqDBZmueCWzSvl3cRl3+yzrqyTUVZbtO0AcZ7jUMY/9WIHL3HwABVUpKFbk+MFecQPSNie6SyW58n13U0Rd57AWcvmNjY42sjGGNAa0dANwX0vBN5eTRCIiwAiIhkKldoHZ9QaufDWNnkt94p27EVbC0Elv3Ht+035hXVFZXZKqW6DwwaGn7H9VVjZKWpvlnFK8FpeyneXuHkdw+KqWk6l7aRlPUgsngc6mmYeLXsON69TLz92tWI6b1p63ibs2q9uxKRwiqgOfQPG/wA8rvdN6jO23Zc+eC6ux7u58rNtR/pJHVpUTRziVuw7+sHzWfRSd3UxuPDOD716E2ydREUDBQe1381s37y/+RQWmtPRXChqbrd6026y0zxE+cR95JNKRkRRM+08/ADeVO9rgPolndjcKpwPvYua/DLPoiGLAp2W6asaMbnVDpy17j1IAA8itDXXuitzRoe5LXa+uhvCZ3Ol082jbSSaY1CyiLdgVLrhEJyOvd7Oznwyq5qWwsoqGmudor33KxVDzEyZzSySGUDJilYfqvA9xG8Kbq6uercDO/axwGMAe5fNreH2fXNK4D0U26CqJI3CoZMGsI8SCR4gLhdM1zdrhhLPfsd38R9EjVpFfvbcMLu89vpwfXZH+a3n95Z/ItgKgdkYPol4djcapoB8mK/L1UODl6f4UfQ5URdSPSh4NCl1A1sneVUjhwzge5WIuOpVvVlS80j4KcF88xFNC0cXPecblNVdR3Tdlp+kPyWX2TWM6l1oLrK3atVjd9G48Jaojdjrsjf546qjVXqipzZCyW2JkU/Y/qqjZHS0t8s5pWAND307w9nuG4/FbE7P+z2g0i+asfPJcLxUN2Ja2VoGG/cY37LfmVdUXkLtffdHZOXY03JtYbCIi0zAREQBERAEREAUXqWx0Oo7JVWq6R95S1Ddk4+s08nNPJwO8KURZTcXlA8vXKguGkr0LLfSe8G+jrQMMqo+RB5OHAj/AIZOnqw72ZfZd15Fb11Zpy3aps01tutOyaN4Jjcdzon43PaeII/2Xk+23Wvt3e09zifOynkdBI5u+SNzTggjmNy9d03X+8R2z5RtVW57M3DQz9/ACT7Y3H/VZCoNmvTHgS26pZI3m3j8RxCsUGoGHAnhIPVhz8iulj5FxzrOyuvtgnpYiBUtIlgJ++3gPfvHvVDsl2pq6zjT97mfb56Od0tHWFhcaSR26SORvExuxk43g71siO70Un6YN/bBCib9YLHfnd9NI2KrxgVEEga/38j71TdSrVho17qZSlGyt4lHhlefY7wY8i5af9Hx+dC5s2MdcY2/djKi7zdKWgs50/ZJX18tXOyWrq2xlpqpG7o4428RG3JxniTlSI7PYu9z+UB7v/6mbXxyrJYrBYrC/voZGS1eMGonkDn+7kPctPT9NrolugsE9VfrtelDVT/KvC8mToyzOsVghpZSDUuJlnI++7iPcMD3KcWBJdqKP9MHHowErBqNQMAIp4ST1ecD4BdFLwWJYWES1dP3EBIPtO3D/VVioqwwFsXtO68go+83prB3txqWRt5N4fAcSqpcrrX3ARwWyJ8DJ5GwRvdukkc44AA5DesuSgu4cki0W6guGrL16lsRPenfWVhGWUsZ4knm48AP+D0bpmxUOm7HS2q1x93S07cDP1nniXOPNxO8rq0npy3aWs0NttVOyGNgBkcN7pX43vceJJ/2UyvH6/XS1UvlFcGlObm8hERc4iEREAREWQEREAREQwEREAXmrtgspsHaFPPGzZor030qMjgJhukb79zv8S9Kqodp+mKfVmmZaIyshr4Xd/RzH7Eo4Z/VI3HzzyW7oNT7vcpPjhk4S2yyeY57fTyyd4Guim5SRnZd8l2Rz3am3RVcdQwfZqGb/wCILkSSw1MtHcYjSXCB2xNBJuc0+HUeK7l7GLjJZibiSfdHLb7Wxj6e2bfjDKD8isuhvEldK+KmtF0mmjaHvZDB3pa3OMkDko6aeKBhdNIxjRzcVtjsDttTRw3W/wA0RjZcNiKmDwQTEzJ2sdCTu8lq6zVe61uecsjOTiuzKH6VV8PUN9z09Xyf6LErrw+hljiqrTdIZpGl7GTQd2XNBxkA8l6j9YTeHzWpO3221NZT2q/wxGRtuL4qkMBJEL8e1joCN/mudpusytsUJLCZWrZN9zVrr7Wyf1FsLfGaUD5BY8lRdqndLVx0zD9mnZv+JXMFRFOwOhkY9p5tK7Mruc+S/GfJiw0EEcneEOlm5ySnad81deyGzG/dodPK9m1RWZvpUhPAzHdG345d/hVPMkk1RFSW+I1VwndsQwR73OPj0HivS3Zfpin0npmKjEjJrhM7v6yVv25TxA/VA3DyzzXL6pqo01OuPLKbpJLai4IiLyhqhERDIREQBERZAREQBERAEREAWFNQh7i5j8E78Hes1FgZwVTUOjbZf2tF4tdJWlow17xh7R4OGCPiqtJ2PaW2si11TB0ZVyY/FbURWwusgsRk19zO5mubZ2b6YtcrZaewwOlbvD5w6Yg/4iQrSGOaANkgDdjCnUyoTnKbzJ5G4gtk/dPwXOwSMbJIPgpxFDA3Gurp2caYusrpamwwNldvL4A6En+AgLAZ2PaV2sm11Th911XJj8VtRFetRbFYU3+5ncVPT2jLXYGuFmtdJRFww57Rl7h0Ljk/NT8NCGuDnvyRvwNyzUVUm5PMnlmMsIiIRCIiGQiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiID//Z"></div><h1>MOSTROMETRO</h1><div class="s" id="bat"></div>
<div class="c"><input id="nome" list="l" maxlength="14" placeholder="Chi si misura?" autocomplete="off"><datalist id="l"></datalist>
<div class="big" id="pct">--%</div><div class="m" id="msg">Scrivi il tuo nome e premi il bottone, anche quello sul Mostrometro.</div>
<button id="go">MISURA LA MOSTRUOSITÀ</button></div>
<div class="c"><h3>Cosa ha combinato?</h3><div class="a" id="az"></div><button id="urlo">&#127908; URLA! Il Mostrometro ti ascolta</button>
<div class="s" id="azmsg">Scrivi il nome, tocca cosa hai fatto e poi premi di nuovo il bottone: la tua mostruosità sale.</div></div>
<div class="c"><h3>La famiglia</h3><div class="add"><input id="nuovo" maxlength="14" placeholder="Nome nuovo" autocomplete="off"><button id="agg">Aggiungi</button></div><div class="s" id="addmsg">Tocca un nome per scegliere chi si misura.</div><div id="lista"></div><div class="s" id="crown"></div><div class="s" id="avg"></div></div></main>
<script>
const $=s=>document.querySelector(s);
const pul=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^\x20-\x7e]/g,'').replace(/[:;"\\<>&'%]/g,'').trim().slice(0,14);
const FR=['Angelo? Mah...','Mostrino da divano','Mostro medio','Mostro serio! Papa ha ragione','Mostro GIGANTE','SUPER MOSTRO!'];
const liv=v=>v<10?0:v<30?1:v<50?2:v<70?3:v<90?4:5;
let ult=-1,aspetto=false;
async function api(p){const r=await fetch(p,{method:'POST'});return r.json()}
async function stato(){try{const d=await(await fetch('/api/stato')).json();disegna(d)}catch(e){$('#msg').textContent='Nessuna risposta. Collegati al WiFi Mostrometro. Se lo sei, il Mostrometro dorme: premi il bottone per svegliarlo.'}}
function disegna(d){
  const nm=$('#nome');if(document.activeElement!==nm&&!nm.value)nm.value=d.chi;
  $('#go').disabled=d.misurando;$('#urlo').disabled=d.misurando;
  $('#bat').textContent='Batteria '+d.bat+'%'+(d.bat<15?' - da ricaricare!':'');
  if(d.misurando){$('#pct').textContent='...';$('#msg').textContent='Misuro...';aspetto=true}
  else if(d.val>=0){$('#pct').textContent=d.val+'%';$('#msg').textContent=FR[liv(d.val)]}
  $('#l').innerHTML=d.fam.map(f=>'<option value="'+f.n+'">').join('');
  const L=$('#lista');L.innerHTML='';
  const o=[...d.fam].sort((a,b)=>b.v-a.v);
  if(!o.length){L.textContent='Nessun mostro ancora!';$('#crown').textContent='';$('#avg').textContent='';return}
  o.forEach(f=>{const r=document.createElement('div');r.className='r';
    r.innerHTML='<div class="n"></div><div class="b"><i style="width:'+Math.max(0,f.v)+'%"></i></div><div class="v">'+(f.v<0?'?':f.v+'%')+'</div><button class="x">&#10005;</button>';
    const ne=r.querySelector('.n');ne.textContent=f.n;ne.title='Scegli '+f.n;ne.onclick=async()=>{$('#nome').value=f.n;await api('/api/chi?nome='+encodeURIComponent(f.n));$('#addmsg').textContent='Ora si misura '+f.n+'.';window.scrollTo({top:0,behavior:'smooth'});stato()};
    if(f.p>0){const s=document.createElement('div');s.className='p';s.textContent='+'+f.p+' in attesa';ne.appendChild(s)}
    r.querySelector('.x').onclick=async()=>{if(confirm('Togliere '+f.n+'?')){await api('/api/elimina?nome='+encodeURIComponent(f.n));stato()}};
    L.appendChild(r)});
  const mis=o.filter(f=>f.v>=0);
  $('#crown').textContent=mis.length?'\u{1F451} Mostro della famiglia: '+mis[0].n+' ('+mis[0].v+'%)':'';
  $('#avg').textContent=mis.length?'Mostruosità media: '+Math.round(mis.reduce((s,f)=>s+f.v,0)/mis.length)+'%':'';
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
async function aggiungi(){const n=pul($('#nuovo').value),m=$('#addmsg');
  if(!n){m.textContent='Scrivi prima un nome.';$('#nuovo').focus();return}
  const d=await api('/api/aggiungi?nome='+encodeURIComponent(n));
  if(d.ok){m.textContent=n+' fa parte della famiglia!';$('#nuovo').value=''}
  else if(d.pieno){m.textContent='La famiglia è piena (12 persone): togline una con la X.'}
  else{m.textContent='Non ci sono riuscito, riprova.'}
  stato()}
$('#agg').onclick=aggiungi;$('#nuovo').onkeydown=e=>{if(e.key==='Enter')aggiungi()};
$('#nome').onchange=()=>api('/api/chi?nome='+encodeURIComponent(pul($('#nome').value)));
$('#urlo').onclick=async()=>{await api('/api/chi?nome='+encodeURIComponent(pul($('#nome').value)));await api('/api/urlo');stato()};
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
  schedaInit();                                          // schermo, audio, batteria: vedi scheda.h

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
    if (!misurando) { disegnaNome(); mostra(); }
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/aggiungi", HTTP_POST, []() {           // aggiunge una persona alla famiglia, senza misurarla
    String nome = pulisci(server.arg("nome"));
    if (nome.length() == 0) { server.send(400, "application/json", "{\"ok\":false}"); return; }
    if (trova(nome) < 0) {
      if (nFam >= MAX_FAM) { server.send(409, "application/json", "{\"ok\":false,\"pieno\":true}"); return; }
      crea(nome);
    }
    attivita();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/misura", HTTP_POST, []() {
    if (misurando || richiestaMisura || richiestaUrlo) { server.send(409, "application/json", "{\"ok\":false}"); return; }
    richiestaMisura = true;
    attivita();
    server.send(200, "application/json", "{\"ok\":true}");
  });
  server.on("/api/urlo", HTTP_POST, []() {
    if (misurando || richiestaMisura || richiestaUrlo) { server.send(409, "application/json", "{\"ok\":false}"); return; }
    richiestaUrlo = true;
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
  if (schedaSvegliataDaTasto()) {                        // svegliato dal naso: niente benvenuto, misura subito
    while (tastoPremuto()) delay(10);
    schermataCompleta(-1);
    richiestaMisura = true;
    return;
  }

  // schermata di benvenuto
  tft.fillScreen(BG);
  tft.setTextColor(BIANCO, BG); tft.setTextSize(4);
  tft.setCursor(12, 40);  tft.print("MOSTRO");
  tft.setCursor(12, 80);  tft.print("METRO");
  tft.setTextSize(2); tft.setTextColor(0xFFE0, BG);
  tft.setCursor(12, 160); tft.print("WiFi:");
  tft.setCursor(12, 184); tft.print(WIFI_SSID);
  tft.setCursor(12, 230); tft.print("Password:");
  tft.setCursor(12, 254); tft.print(WIFI_PASS);
  mostra();
  uint32_t t0 = millis();
  while (millis() - t0 < 4000) { servizi(); delay(5); }
  schermataCompleta(-1);
}

void loop() {
  servizi();
  if (richiestaMisura) { richiestaMisura = false; misura(); }
  if (richiestaUrlo) { richiestaUrlo = false; urla(); }
  if (pwrTenutoPremuto()) {                              // PWR tenuto premuto 3 secondi: spegne (a batteria)
    tft.fillScreen(BG); tft.setTextSize(2); tft.setTextColor(BIANCO, BG);
    tft.setCursor(20, 300); tft.print("Spengo..."); mostra();
    delay(800);
    spegniTutto();
  }
  if (!misurando && !richiestaMisura && !richiestaUrlo && millis() - ultimaAttivita > IDLE_MS) dormi();   // risparmia la batteria
  static uint32_t ultimoTasto = 0;
  if (tastoPremuto() && millis() - ultimoTasto > 500) {
    uint32_t t0 = millis();
    while (tastoPremuto() && millis() - t0 < 1200) servizi();
    ultimoTasto = millis();
    if (tastoPremuto()) { urla(); while (tastoPremuto()) servizi(); }   // tenuto premuto: urlo
    else misura();                                                      // premuto e rilasciato: misura
  }
}
