#pragma once
#include <vector>
typedef void* esp_codec_dev_handle_t;
enum { CODEC_I2S_MODE_TDM = 1 };
struct codec_init_cfg_t { int in_mode, out_mode; bool in_use_tdm, reuse_dev; };
struct esp_codec_dev_sample_info_t { int sample_rate, channel, bits_per_sample; };
static int fakeMicAmp = 0;                    // ampiezza del "microfono" nei test
static long byteSuonati = 0;
inline int init_codec(codec_init_cfg_t*) { return 0; }
inline esp_codec_dev_handle_t get_playback_handle() { return (void*)1; }
inline esp_codec_dev_handle_t get_record_handle() { return (void*)2; }
inline int esp_codec_dev_set_out_vol(esp_codec_dev_handle_t, float) { return 0; }
inline int esp_codec_dev_set_in_gain(esp_codec_dev_handle_t, float) { return 0; }
inline int esp_codec_dev_open(esp_codec_dev_handle_t, esp_codec_dev_sample_info_t*) { return 0; }
inline int esp_codec_dev_write(esp_codec_dev_handle_t, void*, int n) { byteSuonati += n; return 0; }
inline int esp_codec_dev_read(esp_codec_dev_handle_t, void* p, int n) {
  short* s = (short*)p;
  for (int i = 0; i < n / 2; i++) s[i] = (short)(fakeMicAmp * ((i / 2) % 2 ? 1 : -1));   // onda quadra: rms = ampiezza
  return 0;
}
