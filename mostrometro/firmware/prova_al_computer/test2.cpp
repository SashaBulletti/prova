#include "Arduino.h"
#include "extra.h"
#include "../mostrometro/mostrometro.ino"

static void call(const char* path, std::map<std::string, std::string> a = {}) {
  server.args = a;
  server.handlers[path]();
}
static std::string elenco(const std::vector<int>& v) {
  std::string o;
  for (int id : v) {
    if (id <= 100) o += "n" + std::to_string(id) + " ";
    else if (id == CLIP_SEI_AL) o += "[sei al] ";
    else if (id == CLIP_SEI_ALL) o += "[sei all'] ";
    else if (id == CLIP_PER_CENTO) o += "[per cento] ";
    else if (id == CLIP_URLA) o += "[urla] ";
    else if (id == CLIP_URLO_DA) o += "[urlo da] ";
    else if (id == CLIP_PUNTI) o += "[punti] ";
    else if (id == CLIP_BIP) o += "[bip] ";
    else if (id >= CLIP_VERSO0) o += "[verso " + std::to_string(id - CLIP_VERSO0) + "] ";
  }
  return o;
}
static void aspetta() { while (audioOccupato()) std::this_thread::sleep_for(std::chrono::milliseconds(1)); }
static int ok = 0, tot = 0;
static void verifica(bool c, const char* t) { tot++; ok += c; std::cout << (c ? "  OK  " : "  ERRORE  ") << t << "\n"; }

int main() {
  setup();
  std::cout << "Avvio\n";
  verifica((exioLivelli & IO_EXPANDER_PIN_NUM_6) != 0, "SYS_EN (tiene accesa la scheda a batteria) e' alto");
  verifica((exioLivelli & IO_EXPANDER_PIN_NUM_7) == 0, "amplificatore spento all'avvio");
  verifica((exioLivelli & IO_EXPANDER_PIN_NUM_1) != 0, "retroilluminazione accesa");

  std::cout << "\nMisura di Papa (base 39%)\n";
  call("/api/chi", {{"nome", "Papa"}});
  clipLog.clear();
  call("/api/misura");
  loop();
  aspetta();
  std::cout << "   suoni in ordine: " << elenco(clipLog) << "\n";
  verifica(clipLog.size() == 4 && clipLog[0] == CLIP_VERSO0 + 2 && clipLog[1] == CLIP_SEI_AL && clipLog[2] == CLIP_NUMERO0 + 39 && clipLog[3] == CLIP_PER_CENTO,
           "verso del livello 2, poi 'sei al trentanove per cento'");
  verifica(byteSuonati > 0, "e' arrivato audio all'altoparlante");

  std::cout << "\n'sei al' o 'sei all'' davanti ai numeri\n";
  bool bene = true;
  for (int n : {1, 8, 11, 80, 85, 89}) { clipLog.clear(); dilloIn(n); aspetta(); bene &= clipLog[0] == CLIP_SEI_ALL; }
  for (int n : {0, 2, 10, 12, 21, 28, 60, 79, 90, 100}) { clipLog.clear(); dilloIn(n); aspetta(); bene &= clipLog[0] == CLIP_SEI_AL; }
  verifica(bene, "all' per 1, 8, 11 e 80-89; al per tutti gli altri");

  std::cout << "\nUrlo (microfono finto con volume diverso)\n";
  struct { int amp; const char* nome; } prove[] = {{0, "silenzio"}, {300, "sussurro"}, {1036, "voce normale"}, {4000, "voce alta"}, {20000, "urlo"}};
  int ultimaP = -1; bool crescente = true;
  for (auto& p : prove) {
    fakeMicAmp = p.amp;
    int bonusPrima = fam[trova("Papa")].bonus;
    clipLog.clear();
    call("/api/urlo");
    loop();
    aspetta();
    int punti = fam[trova("Papa")].bonus - bonusPrima;
    std::cout << "   " << p.nome << " (ampiezza " << p.amp << ") -> " << punti << " punti\n";
    if (punti < ultimaP) crescente = false;
    ultimaP = punti;
    if (p.amp == 20000) verifica(elenco(clipLog).find("[urla]") == 0, "dice 'urla' prima di ascoltare");
  }
  verifica(crescente && ultimaP >= 9, "piu' forte = piu' punti, e un vero urlo prende 9 o 10");

  std::cout << "\nPunti in attesa e nuova misura\n";
  fam[trova("Papa")].bonus = 8;
  call("/api/stato");
  std::cout << "   " << server.last << "\n";
  clipLog.clear();
  call("/api/misura"); loop(); aspetta();
  verifica(fam[trova("Papa")].val == 39 + 8, "dopo +8 punti Papa sale da 39% a 47%");
  verifica(clipLog[2] == CLIP_NUMERO0 + 47, "e dice 'quarantasette'");

  std::cout << "\nStandby\n";
  fakeClock += 400000;
  loop();
  verifica(fakeSleeping, "va in standby dopo 5 minuti");
  verifica((exioLivelli & IO_EXPANDER_PIN_NUM_7) == 0 && (exioLivelli & IO_EXPANDER_PIN_NUM_1) == 0, "amplificatore e retroilluminazione spenti");
  verifica((exioLivelli & IO_EXPANDER_PIN_NUM_6) != 0, "SYS_EN resta alto: la scheda dorme, non si spegne");

  std::cout << "\nSpegnimento con PWR\n";
  fakeSleeping = false;
  pinState[PIN_SYS_OUT] = HIGH;
  for (int i = 0; i < 25; i++) { fakeClock += 100; pwrTenutoPremuto(); }     // PWR lasciato per 2,5 secondi: la scheda e' "armata"
  pinState[PIN_SYS_OUT] = LOW;
  bool a2 = false, a5 = false;
  for (int i = 0; i < 45; i++) { fakeClock += 100; bool r = pwrTenutoPremuto(); if (i == 20) a2 = r; if (i == 33) a5 = r; }
  verifica(!a2 && a5, "PWR tenuto 2 secondi non spegne, tenuto 3 secondi spegne");
  pinState[PIN_SYS_OUT] = HIGH;

  std::cout << "\nBatteria\n";
  fakeBatMv = 1250; verifica(batteriaPct() == 35, "3,75 V -> 35%");
  fakeBatMv = 1384; verifica(batteriaPct() == 100, "4,15 V -> 100%");
  fakeBatMv = 1050; verifica(batteriaPct() == 0, "3,15 V -> 0%");

  std::cout << "\nSchermo: le frasi vanno a capo tra le parole (max 8 lettere per riga)\n";
  bool largo = true;
  for (int l = 0; l < 6; l++) {
    gfx->log = ""; disegnaFrase(FRASI[l], BIANCO);
    size_t a = 0;
    while ((a = gfx->log.find('[', a)) != std::string::npos) { size_t b = gfx->log.find(']', a); if (b - a - 1 > 8) largo = false; a = b; }
  }
  verifica(largo, "nessuna riga e' piu' larga del pannello");

  std::cout << "\n" << ok << " controlli su " << tot << " superati\n";
  return ok == tot ? 0 : 1;
}
