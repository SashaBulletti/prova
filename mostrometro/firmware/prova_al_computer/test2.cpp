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

  std::cout << "\nAggiungere persone dall'app\n";
  int prima = nFam;
  call("/api/aggiungi", {{"nome", "Nonna"}});
  verifica(nFam == prima + 1 && trova("Nonna") >= 0 && fam[trova("Nonna")].val == -1, "Nonna aggiunta, non ancora misurata");
  call("/api/aggiungi", {{"nome", "nonna"}});
  verifica(nFam == prima + 1, "'nonna' minuscolo non crea un doppione");
  for (int i = 0; nFam < MAX_FAM; i++) call("/api/aggiungi", {{"nome", "Zio" + std::to_string(i)}});
  call("/api/aggiungi", {{"nome", "Tredicesimo"}});
  verifica(nFam == MAX_FAM && trova("Tredicesimo") < 0 && server.last.find("pieno") != std::string::npos,
           "con 12 persone la tredicesima non entra e l'app lo dice");

  std::cout << "\nGioco delle carte\n";
  auto cod = [](int n) { return std::string(CARTE[n - 1].codice); };
  call("/api/carta", {{"n", "1"}, {"k", "ZZZZ"}});
  verifica(server.code == 404, "un QR con il codice sbagliato non vale");
  call("/api/carta", {{"n", "1"}, {"k", cod(1)}});
  std::cout << "   " << server.last << "\n";
  verifica(server.code == 200 && server.last.find("Rutta a tavola!") != std::string::npos && server.last.find("\"da\":\"\"") != std::string::npos,
           "la carta 1 si legge ed e' ancora da giocare");
  int bPapa = fam[trova("Papa")].bonus;
  clipLog.clear();
  call("/api/gioca", {{"n", "1"}, {"k", cod(1)}, {"nome", "papa"}});
  aspetta();
  verifica(server.code == 200 && fam[trova("Papa")].bonus == bPapa + 5 && clipLog.size() == 1 && clipLog[0] == CLIP_BIP,
           "Papa gioca la carta 1: +5 e un bip");
  call("/api/gioca", {{"n", "1"}, {"k", cod(1)}, {"nome", "Nonna"}});
  verifica(server.code == 409 && server.last.find("Papa") != std::string::npos && fam[trova("Papa")].bonus == bPapa + 5,
           "la stessa carta non vale due volte, e l'app dice chi l'ha gia' giocata");
  call("/api/stato");
  verifica(server.last.find("\"carte\":1,") != std::string::npos && server.last.find("\"n\":\"Papa\",\"v\":47,\"p\":5,\"c\":1}") != std::string::npos,
           "lo stato dice 1 carta giocata, e Papa ha 1 carta e +5 in attesa");
  call("/api/gioca", {{"n", "2"}, {"k", cod(2)}, {"nome", "Sconosciuto"}});
  verifica(server.code == 409 && server.last.find("pieno") != std::string::npos && trova("Sconosciuto") < 0, "con la famiglia piena un nome nuovo non entra");

  std::cout << "\nMostro Supremo (carta 57)\n";
  verifica(CARTE[56].speciale == CARTA_SPECIALE_MOSTRO_SUPREMO && std::string(CARTE[29].titolo) == "Artigli da mostro", "la 57 e' speciale e la 30 e' Artigli da mostro");
  int bN = fam[trova("Nonna")].bonus; bPapa = fam[trova("Papa")].bonus;
  call("/api/gioca", {{"n", "57"}, {"k", cod(57)}, {"nome", "Nonna"}, {"altro", "Papa"}});
  verifica(fam[trova("Nonna")].bonus == bN + 2 && fam[trova("Papa")].bonus == bPapa, "senza gli artigli: Nonna +2, Papa niente");
  call("/api/nuovaserata");
  call("/api/carta", {{"n", "1"}, {"k", cod(1)}});
  verifica(server.last.find("\"da\":\"\"") != std::string::npos && fam[trova("Papa")].bonus == bPapa, "nuova serata: le carte tornano giocabili, i punti restano");
  bN = fam[trova("Nonna")].bonus;
  call("/api/gioca", {{"n", "57"}, {"k", cod(57)}, {"nome", "Nonna"}, {"altro", "papa"}, {"artigli", "1"}});
  std::cout << "   " << server.last << "\n";
  verifica(fam[trova("Nonna")].bonus == bN + 5 && fam[trova("Papa")].bonus == bPapa + 5, "con gli artigli: 5 punti a testa");
  call("/api/gioca", {{"n", "30"}, {"k", cod(30)}, {"nome", "Papa"}});
  verifica(server.code == 200 && fam[trova("Papa")].bonus == bPapa + 10, "Papa puo' ancora giocare la sua carta Artigli da mostro");
  caricaCarte();
  verifica(cartaDa[57] == String("Nonna") && cartaDa[30] == String("Papa") && cartaDa[1].length() == 0, "le carte giocate restano salvate in memoria");

  std::cout << "\n" << ok << " controlli su " << tot << " superati\n";
  return ok == tot ? 0 : 1;
}
