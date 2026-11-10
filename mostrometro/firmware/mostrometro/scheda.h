// scheda.h - tutto cio' che riguarda la SCHEDA Waveshare ESP32-S3-Touch-LCD-3.49 (versione V2):
// schermo, accensione a batteria, ricarica, bottone, altoparlante e microfono.
// Il programma principale (mostrometro.ino) non sa niente di questi dettagli.
//
// I pin e i valori vengono dallo schema elettrico e dagli esempi ufficiali del produttore
// (cartella Arduino/examples/ del repository waveshareteam/ESP32-S3-Touch-LCD-3.49-V2).
// NON e' stato provato su una scheda vera: se qualcosa non va, confronta con gli esempi 07_BATT_PWR_Test e 08_Audio_Test.
//
// ATTENZIONE: i file del produttore (i2c_bsp.*, src/codec_board, src/esp_codec_dev, src/tca9554) vanno copiati
// nella cartella di questo programma, vedi la guida. Non si usa la libreria Wire: la tiene occupata il produttore.
#pragma once
#include <Arduino.h>
#include <Arduino_GFX_Library.h>
#include "driver/rtc_io.h"
#include "esp_sleep.h"
#include "i2c_bsp.h"
#include "src/tca9554/esp_io_expander_tca9554.h"
#include "src/codec_board/codec_board.h"
#include "src/codec_board/codec_init.h"
#include "audio_dati.h"

// ---------------- pin (dallo schema e dagli esempi del produttore) ----------------
#define PIN_BTN      1      // il bottone grosso: un filo sulla piazzola "1", l'altro sulla piazzola "G" (massa)
#define PIN_LCD_BL   42     // retroilluminazione (V2)
#define PIN_BAT      4      // misura della batteria (la tensione e' divisa per 3)
#define PIN_SYS_OUT  16     // segnala che il pulsante PWR e' premuto (basso = premuto)
#define BAT_DIV      3.0

#define LCD_W 172
#define LCD_H 640

// ---------------- audio e microfono: valori da regolare ----------------
#define AUDIO_VOLUME  85        // 0..100
#define MIC_GAIN      35.0f     // come nell'esempio del produttore
#define URLO_DB_MIN  -45.0f     // sotto questo livello l'urlo vale 0 punti
#define URLO_DB_MAX  -15.0f     // da questo livello in su l'urlo vale 10 punti (10 e' il massimo)

// ---------------- schermo ----------------
Arduino_DataBus *bus = new Arduino_ESP32QSPI(9 /* CS */, 10 /* SCK */, 11, 12, 13, 14 /* D0..D3 */);
Arduino_GFX *schermoFisico = new Arduino_AXS15231B(bus, GFX_NOT_DEFINED /* il reset e' sull'espansore */, 0, false, LCD_W, LCD_H);
// Il disegno avviene in memoria (nella PSRAM) e poi si manda tutto allo schermo con mostra().
Arduino_Canvas *gfx = new Arduino_Canvas(LCD_W, LCD_H, schermoFisico, 0, 0, 0 /* 0 = in verticale */);
#define tft (*gfx)             // cosi' il resto del programma scrive tft.fillRect(...)
static inline void mostra() { gfx->flush(); }

// ---------------- espansore di pin (TCA9554, indirizzo 0x20) ----------------
static esp_io_expander_handle_t io_exp = NULL;
#define EXIO_BL_EN    IO_EXPANDER_PIN_NUM_1   // abilita la retroilluminazione
#define EXIO_LCD_RST  IO_EXPANDER_PIN_NUM_5   // reset dello schermo
#define EXIO_SYS_EN   IO_EXPANDER_PIN_NUM_6   // tiene accesa la scheda quando va a batteria
#define EXIO_NS_MODE  IO_EXPANDER_PIN_NUM_7   // accende l'amplificatore dell'altoparlante

static void exio(uint32_t pin, int livello) { esp_io_expander_set_level(io_exp, pin, livello); }

static void espansoreInit() {
  i2c_master_bus_handle_t i2c;
  ESP_ERROR_CHECK(i2c_master_get_bus_handle(0, &i2c));
  ESP_ERROR_CHECK(esp_io_expander_new_i2c_tca9554(i2c, ESP_IO_EXPANDER_I2C_TCA9554_ADDRESS_000, &io_exp));
  esp_io_expander_set_dir(io_exp, EXIO_BL_EN | EXIO_LCD_RST | EXIO_SYS_EN | EXIO_NS_MODE, IO_EXPANDER_OUTPUT);
  exio(EXIO_SYS_EN, 1);      // IMPORTANTE: senza questo, a batteria la scheda si spegne appena lasci il pulsante PWR
  exio(EXIO_NS_MODE, 0);     // amplificatore spento finche' non serve
  exio(EXIO_BL_EN, 0);
}

static void schermoReset() {                // sequenza dell'esempio del produttore
  exio(EXIO_LCD_RST, 1); delay(30);
  exio(EXIO_LCD_RST, 0); delay(250);
  exio(EXIO_LCD_RST, 1); delay(30);
}

// ---------------- batteria ----------------
int batteriaPct() {
  float v = analogReadMilliVolts(PIN_BAT) * BAT_DIV / 1000.0;
  static const float V[] = {3.30, 3.50, 3.65, 3.75, 3.85, 4.00, 4.15};
  static const int   P[] = {0,    5,    15,   35,   55,   80,   100};
  if (v <= V[0]) return 0;
  for (int i = 1; i < 7; i++)
    if (v <= V[i]) return P[i - 1] + (int)((v - V[i - 1]) * (P[i] - P[i - 1]) / (V[i] - V[i - 1]));
  return 100;
}

// ---------------- audio ----------------
static esp_codec_dev_handle_t playback = NULL, record = NULL;
static int16_t tabMulaw[256];
static QueueHandle_t codaAudio = NULL;
static volatile bool audioAttivo = false;

static void audioInit() {
  for (int b = 0; b < 256; b++) {                       // tabella per decomprimere i suoni (mu-law)
    float y = (b / 255.0f) * 2 - 1;
    float x = (y < 0 ? -1.0f : 1.0f) * (powf(256.0f, fabsf(y)) - 1) / 255.0f;
    tabMulaw[b] = (int16_t)(x * 32000);
  }
  set_codec_board_type("S3_LCD_3_49");
  codec_init_cfg_t cfg = {};
  cfg.in_mode = CODEC_I2S_MODE_TDM;
  cfg.out_mode = CODEC_I2S_MODE_TDM;
  cfg.in_use_tdm = false;
  cfg.reuse_dev = false;
  init_codec(&cfg);
  playback = get_playback_handle();
  record = get_record_handle();
  esp_codec_dev_set_out_vol(playback, AUDIO_VOLUME);
  esp_codec_dev_set_in_gain(record, MIC_GAIN);
  esp_codec_dev_sample_info_t fs = {};
  fs.sample_rate = 24000; fs.channel = 2; fs.bits_per_sample = 16;
  esp_codec_dev_open(playback, &fs);
  esp_codec_dev_open(record, &fs);
}

// Suona un suono: lo porta da 12 kHz mono a 24 kHz stereo (il doppio dei campioni) e lo manda all'altoparlante.
static void suonaClip(int id) {
  if (id < 0 || id >= AUDIO_NCLIP) return;
  const uint8_t* d = AUDIO_POOL + AUDIO_OFFSET[id];
  uint32_t n = AUDIO_LUNGH[id], i = 0;
  static int16_t buf[256 * 4];                         // 256 campioni -> 512 frame stereo
  int16_t prima = 0;
  while (i < n) {
    uint32_t m = min<uint32_t>(256, n - i);
    int k = 0;
    for (uint32_t j = 0; j < m; j++) {
      int16_t s = tabMulaw[d[i + j]];
      int16_t mezzo = (int16_t)((prima + s) / 2);
      buf[k++] = mezzo; buf[k++] = mezzo; buf[k++] = s; buf[k++] = s;
      prima = s;
    }
    esp_codec_dev_write(playback, buf, k * sizeof(int16_t));
    i += m;
  }
}

static void taskAudio(void*) {
  int id;
  for (;;) {
    if (xQueueReceive(codaAudio, &id, portMAX_DELAY) == pdTRUE) {
      audioAttivo = true;
      exio(EXIO_NS_MODE, 1);                           // accende l'amplificatore
      suonaClip(id);
      audioAttivo = uxQueueMessagesWaiting(codaAudio) > 0;
    }
  }
}

void audioAccoda(int id) { if (codaAudio) xQueueSend(codaAudio, &id, 0); }   // il suono parte da solo, in sottofondo
bool audioOccupato() { return codaAudio && (uxQueueMessagesWaiting(codaAudio) > 0 || audioAttivo); }
void audioAttendi() { while (audioOccupato()) delay(10); }

// Registra col microfono per `ms` millisecondi e dice quanto e' stato forte il momento piu' forte (in dBFS: 0 = massimo, -90 = silenzio).
float microfonoPicco(int ms) {
  audioAttendi();
  const int FRAME = 1200;                              // 50 ms a 24 kHz
  static int16_t buf[FRAME * 2];                       // stereo: due microfoni
  float migliore = -90;
  for (int t = 0; t < ms / 50; t++) {
    esp_codec_dev_read(record, buf, sizeof(buf));
    double somma = 0;
    for (int j = 0; j < FRAME * 2; j++) somma += (double)buf[j] * buf[j];
    float rms = sqrt(somma / (FRAME * 2)) / 32768.0f;
    float db = 20.0f * log10f(max(rms, 3e-5f));
    if (db > migliore) migliore = db;
  }
  return migliore;
}

// Da dBFS a punti da 0 a 10.
int puntiDaDb(float db) {
  float p = (db - URLO_DB_MIN) / (URLO_DB_MAX - URLO_DB_MIN) * 10.0f;
  return constrain((int)(p + 0.5f), 0, 10);
}

// ---------------- bottone e pulsante PWR ----------------
bool tastoPremuto() { return digitalRead(PIN_BTN) == LOW; }

// Tenendo premuto PWR per 3 secondi la scheda si spegne (se non e' collegato l'USB).
// Parte solo dopo che il pulsante e' stato visto rilasciato, cosi' non spegne la scheda mentre la si accende.
bool pwrTenutoPremuto() {
  static uint32_t rilasciatoDa = 0, premutoDa = 0;
  static bool armato = false;
  bool giu = digitalRead(PIN_SYS_OUT) == LOW;
  if (!giu) { if (!rilasciatoDa) rilasciatoDa = millis(); premutoDa = 0; if (millis() - rilasciatoDa > 1000) armato = true; return false; }
  rilasciatoDa = 0;
  if (!armato) return false;
  if (!premutoDa) premutoDa = millis();
  return millis() - premutoDa > 3000;
}
void spegniTutto() { exio(EXIO_SYS_EN, 0); }           // se c'e' l'USB resta acceso, a batteria si spegne

// ---------------- avvio, standby ----------------
bool schedaSvegliataDaTasto() { return esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_EXT0; }

void schedaInit() {
  Serial.begin(115200);
  pinMode(PIN_BTN, INPUT_PULLUP);
  pinMode(PIN_SYS_OUT, INPUT);
  analogSetPinAttenuation(PIN_BAT, ADC_11db);
  i2c_master_Init();
  espansoreInit();
  pinMode(PIN_LCD_BL, OUTPUT); digitalWrite(PIN_LCD_BL, LOW);
  schermoReset();
  gfx->begin();
  gfx->fillScreen(0);
  mostra();
  digitalWrite(PIN_LCD_BL, HIGH);
  exio(EXIO_BL_EN, 1);
  audioInit();
  codaAudio = xQueueCreate(16, sizeof(int));
  xTaskCreatePinnedToCore(taskAudio, "audio", 6144, NULL, 3, NULL, 0);
}

// Standby profondo: tutto spento tranne la memoria. Si risveglia premendo il bottone grosso.
void schedaDormi() {
  audioAttendi();
  exio(EXIO_NS_MODE, 0);
  exio(EXIO_BL_EN, 0);
  digitalWrite(PIN_LCD_BL, LOW);
  schermoFisico->displayOff();
  rtc_gpio_pullup_en((gpio_num_t)PIN_BTN);              // il pull-up deve restare attivo durante il sonno
  rtc_gpio_pulldown_dis((gpio_num_t)PIN_BTN);
  esp_sleep_enable_ext0_wakeup((gpio_num_t)PIN_BTN, 0); // si sveglia quando il bottone va a massa
  esp_deep_sleep_start();                               // SYS_EN resta acceso: la scheda non si spegne, dorme
}
