// finte parti di FreeRTOS e di ESP32 che servono al nuovo firmware
#pragma once
#include <thread>
#include <mutex>
#include <condition_variable>
#include <deque>
#include <vector>
#include <cmath>
typedef void* QueueHandle_t;
#define pdTRUE 1
#define portMAX_DELAY 0xFFFFFFFF
struct CodaFinta { std::mutex m; std::condition_variable cv; std::deque<int> q; };
static std::vector<int> clipLog;                       // ordine in cui i suoni vengono messi in coda
inline QueueHandle_t xQueueCreate(int, int) { return new CodaFinta(); }
inline int xQueueSend(QueueHandle_t q, void* item, int) { auto* c = (CodaFinta*)q; std::lock_guard<std::mutex> l(c->m); c->q.push_back(*(int*)item); clipLog.push_back(*(int*)item); c->cv.notify_all(); return pdTRUE; }
inline int xQueueReceive(QueueHandle_t q, void* item, unsigned) { auto* c = (CodaFinta*)q; std::unique_lock<std::mutex> l(c->m); c->cv.wait(l, [&] { return !c->q.empty(); }); *(int*)item = c->q.front(); c->q.pop_front(); return pdTRUE; }
inline int uxQueueMessagesWaiting(QueueHandle_t q) { auto* c = (CodaFinta*)q; std::lock_guard<std::mutex> l(c->m); return (int)c->q.size(); }
inline void xTaskCreatePinnedToCore(void (*f)(void*), const char*, int, void* a, int, void*, int) { std::thread([f, a] { f(a); }).detach(); }
#define ADC_11db 3
inline void analogSetPinAttenuation(int, int) {}
