// Finte librerie Arduino/ESP32: servono solo a compilare e provare la logica del firmware sul PC.
#pragma once
#include <string>
#include <map>
#include <functional>
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <iostream>

#define PROGMEM
#define HIGH 1
#define LOW 0
#define OUTPUT 1
#define INPUT_PULLUP 2
#define SPI_MODE3 3

static unsigned long fakeClock = 0;
inline unsigned long millis() { return fakeClock; }
inline void delay(unsigned long ms) { fakeClock += ms; }
inline void pinMode(int, int) {}
inline void digitalWrite(int, int) {}
static int pinState[64];
struct InitPin { InitPin() { for (int& p : pinState) p = HIGH; } } initPin_;
inline int digitalRead(int pin) { return pinState[pin]; }
inline uint32_t esp_random() { return 4; }
template <class T> T map(T x, T a, T b, T c, T d) { return (x - a) * (d - c) / (b - a) + c; }
template <class T> T constrain(T x, T lo, T hi) { return x < lo ? lo : (x > hi ? hi : x); }
using std::min;
using std::max;

class String {
 public:
  std::string s;
  String() {}
  String(const char* c) : s(c) {}
  String(int v) : s(std::to_string(v)) {}
  String(const std::string& x) : s(x) {}
  unsigned length() const { return s.size(); }
  String substring(int a, int b = -1) const { return b < 0 ? String(s.substr(a)) : String(s.substr(a, b - a)); }
  int indexOf(char c, int from = 0) const { auto p = s.find(c, from); return p == std::string::npos ? -1 : (int)p; }
  long toInt() const { return atol(s.c_str()); }
  bool equalsIgnoreCase(const String& o) const {
    if (s.size() != o.s.size()) return false;
    for (size_t i = 0; i < s.size(); i++) if (tolower(s[i]) != tolower(o.s[i])) return false;
    return true;
  }
  void toLowerCase() { for (auto& c : s) c = tolower(c); }
  void trim() {
    size_t a = s.find_first_not_of(' '); size_t b = s.find_last_not_of(' ');
    s = (a == std::string::npos) ? "" : s.substr(a, b - a + 1);
  }
  const char* c_str() const { return s.c_str(); }
  char operator[](size_t i) const { return s[i]; }
  String& operator+=(const String& o) { s += o.s; return *this; }
  String& operator+=(char c) { s += c; return *this; }
  bool operator==(const String& o) const { return s == o.s; }
};
inline String operator+(const String& a, const String& b) { return String(a.s + b.s); }
inline String operator+(const char* a, const String& b) { return String(std::string(a) + b.s); }
inline String operator+(const String& a, const char* b) { return String(a.s + b); }
inline String operator+(const String& a, char b) { return String(a.s + b); }

struct IPAddress {};
struct SerialStub { void begin(int) {} } Serial;
struct WiFiStub { void mode(int) {} void softAP(const char*, const char*) {} IPAddress softAPIP() { return {}; } } WiFi;
#define WIFI_AP 1
struct DNSServer { void start(int, const char*, IPAddress) {} void processNextRequest() {} };
struct Preferences {
  std::map<std::string, std::string> kv;
  void begin(const char*, bool) {}
  String getString(const char* k, const char* d) { return kv.count(k) ? String(kv[k]) : String(d); }
  void putString(const char* k, const String& v) { kv[k] = v.s; }
};
enum HTTPMethod { HTTP_GET, HTTP_POST };
struct WebServer {
  std::map<std::string, std::function<void()>> handlers;
  std::function<void()> nf;
  std::map<std::string, std::string> args;
  std::string last;
  WebServer(int) {}
  void on(const char* p, HTTPMethod, std::function<void()> f) { handlers[p] = f; }
  void onNotFound(std::function<void()> f) { nf = f; }
  void begin() {}
  void handleClient() {}
  int code = 0;
  void send(int c, const char*, const String& b) { code = c; last = b.s; }
  void send_P(int, const char*, const char*) {}
  void sendHeader(const char*, const char*) {}
  String arg(const char* n) { return String(args.count(n) ? args[n] : ""); }
};
struct Adafruit_ST7789 {
  Adafruit_ST7789(int, int, int) {}
  void init(int, int, int) {}
  void setRotation(int) {}
  void fillScreen(int) {}
  void fillRect(int, int, int, int, int) { fills++; }
  void fillRoundRect(int, int, int, int, int, int) {}
  void fillCircle(int, int, int, int) {}
  void drawFastHLine(int, int, int, int) { hlines++; }
  void fillTriangle(int, int, int, int, int, int, int) {}
  void drawLine(int, int, int, int, int) {}
  uint16_t color565(uint8_t r, uint8_t g, uint8_t b) { return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3); }
  void enableDisplay(bool) {}
  void enableSleep(bool) {}
  void drawRect(int, int, int, int, int) {}
  void setTextSize(int) {}
  void setTextColor(int, int) {}
  void setCursor(int, int) {}
  std::string log;
  int hlines = 0, fills = 0;
  void print(const char* t) { log += std::string("[") + t + "]"; }
  void print(const String& t) { log += "[" + t.s + "]"; }
};

// --- batteria e standby ---
#define WIFI_OFF 0
static uint32_t fakeBatMv = 2000;              // millivolt letti sul pin (meta' della tensione LiPo)
inline uint32_t analogReadMilliVolts(int) { return fakeBatMv; }
typedef int gpio_num_t;
inline void rtc_gpio_pullup_en(int) {}
inline void rtc_gpio_pulldown_dis(int) {}
enum { ESP_SLEEP_WAKEUP_UNDEFINED = 0, ESP_SLEEP_WAKEUP_EXT0 = 2 };
static int fakeWake = ESP_SLEEP_WAKEUP_UNDEFINED;
static bool fakeSleeping = false;
inline int esp_sleep_get_wakeup_cause() { return fakeWake; }
inline void esp_sleep_enable_ext0_wakeup(int, int) {}
inline void esp_deep_sleep_start() { fakeSleeping = true; }

// --- GFX Library for Arduino (LilyGO S3 Long) ---
struct Arduino_DataBus {};
struct Arduino_ESP32QSPI : Arduino_DataBus { Arduino_ESP32QSPI(int, int, int, int, int, int) {} };
struct Arduino_GFX : Adafruit_ST7789 {
  Arduino_GFX() : Adafruit_ST7789(0, 0, 0) {}
  bool begin() { return true; }
  void displayOff() {}
};
struct Arduino_AXS15231 : Arduino_GFX { Arduino_AXS15231(Arduino_DataBus*, int, int, bool, int, int) {} };

struct Arduino_Canvas : Arduino_GFX {
  Arduino_Canvas(int, int, Arduino_GFX*, int, int, int) : Arduino_GFX() {}
  bool begin() { return true; }
  void flush() {}
};
struct Arduino_AXS15231B : Arduino_GFX { Arduino_AXS15231B(Arduino_DataBus*, int, int, bool, int, int) {} };
#define GFX_NOT_DEFINED -1
#define INPUT 0
