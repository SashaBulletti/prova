#pragma once
// finta libreria dell'espansore: ricorda lo stato dei pin per i test
#include <map>
typedef int i2c_master_bus_handle_t;
typedef int esp_err_t;
#define ESP_OK 0
#define ESP_ERROR_CHECK(x) ((void)(x))
inline esp_err_t i2c_master_get_bus_handle(int, i2c_master_bus_handle_t*) { return 0; }
typedef void* esp_io_expander_handle_t;
#define ESP_IO_EXPANDER_I2C_TCA9554_ADDRESS_000 0x20
#define IO_EXPANDER_OUTPUT 1
#define IO_EXPANDER_PIN_NUM_1 (1u << 1)
#define IO_EXPANDER_PIN_NUM_5 (1u << 5)
#define IO_EXPANDER_PIN_NUM_6 (1u << 6)
#define IO_EXPANDER_PIN_NUM_7 (1u << 7)
static unsigned exioLivelli = 0;
inline esp_err_t esp_io_expander_new_i2c_tca9554(i2c_master_bus_handle_t, int, esp_io_expander_handle_t* h) { *h = (void*)1; return 0; }
inline esp_err_t esp_io_expander_set_dir(esp_io_expander_handle_t, unsigned, int) { return 0; }
inline esp_err_t esp_io_expander_set_level(esp_io_expander_handle_t, unsigned mask, int lv) { if (lv) exioLivelli |= mask; else exioLivelli &= ~mask; return 0; }
