# Celsius Panel — client non ufficiale

App alternativa per gestire i pannelli riscaldanti **Celsius Panel**
(Tesi Group), pensata per collegarli ad **Alexa, Google Home e Home Assistant**.

> Progetto personale per i propri pannelli. Non affiliato a Tesi Group / Celsius Panel.

## Come funziona il sistema Celsius

Ricavato e verificato analizzando l'app ufficiale (Flutter, v1.4.9):

- **API REST** `https://crmapp.celsiuspanel.it/api` — è un backend
  **API Platform** (Symfony, JSON-LD). Login con token JWT
  (`POST /api/login-check`, campo `username` + `password`).
- **Dati in tempo reale già nell'API**: `GET /api/buildings/<uuid>/panels`
  restituisce ogni pannello con `lastMeasurement` (consumo in W, umidità,
  temperatura interna ed esterna). Per leggere basta interrogare l'API, non
  serve per forza MQTT.
- **MQTT su AWS IoT Core** disponibile (`POST /api/public/mqtt-server`) per
  gli aggiornamenti "push" istantanei — utile più avanti.
- **Pannello = ESP32**: in configurazione crea l'hotspot `CELSIUS_PANEL` su
  `192.168.4.1`; i MAC dei pannelli sono Espressif.

Mappa completa degli endpoint in [`celsius/const.py`](celsius/const.py).

### Comandi principali (tutti POST sotto `/api/panels/<uuid>/`)

| Azione | Endpoint | Body |
|---|---|---|
| Accendi (manuale) | `mode-manual-on` | `{"setTemperature":"21"}` |
| Spegni | `mode-manual-off` | `{}` |
| Programmato (auto) | `mode-scheduled` | `{}` |
| Comfort/antigelo/max | `update` | `{"comfortTemperature","minTemperature","maxTemperature"}` |
| Programma settimanale | `set-scheduling` | calendario 7×24 |
| Riavvia | `restart` | `{}` |

## Uso (dal computer)

Serve solo Python 3 (già sul Mac). Nessuna installazione.

```bash
python3 celsius_cli.py list            # mostra tutti i pannelli e i dati
python3 celsius_cli.py on cucina 21    # accendi "cucina" a 21°
python3 celsius_cli.py off bagno       # spegni "bagno"
python3 celsius_cli.py auto salotto    # "salotto" in programmato
python3 celsius_cli.py all-off         # spegni TUTTI
python3 celsius_cli.py all-on 20       # accendi TUTTI a 20°
python3 celsius_cli.py comfort camera 19
```

La prima volta chiede email e password; poi salva il token in `.token`
(non versionato) e non li richiede più finché è valido (~1 settimana).

## Home Assistant

In [`custom_components/celsius/`](custom_components/celsius) c'è
l'integrazione per Home Assistant: ogni pannello diventa un **termostato**
(climate) con modalità Spento/Manuale/Programmato, temperatura e umidità,
più sensori di **consumo (W)**, umidità e temperatura esterna. Una volta
dentro Home Assistant, i termostati si espongono ad Alexa e Google Home.

### Installazione — con HACS (consigliata)

1. HACS → menù in alto a destra → **Repository personalizzati**.
2. Incolla `https://github.com/SashaBulletti/prova`, categoria **Integrazione**.
3. Cerca **Celsius Panel**, installa, **riavvia** Home Assistant.
4. Impostazioni → Dispositivi e servizi → **Aggiungi integrazione** →
   *Celsius Panel* → inserisci email e password.

### Installazione — manuale

1. Copia la cartella `custom_components/celsius` dentro la cartella
   `config` di Home Assistant (accanto a `configuration.yaml`).
2. Riavvia Home Assistant.
3. Aggiungi l'integrazione come sopra.

## A che punto siamo

- [x] API mappata e login funzionante
- [x] Lettura pannelli + dati in tempo reale
- [x] Client Python e comando da terminale (on/off/auto/temperature)
- [x] Funzioni "spegni tutto" / "accendi tutto"
- [x] Comandi di scrittura verificati sul pannello reale
- [x] Integrazione Home Assistant (ogni pannello = termostato + sensori)
- [ ] Installazione in Home Assistant e verifica
- [ ] Alexa / Google Home (via Home Assistant)
- [ ] Taglio carichi quando si carica l'auto (anti–salto contatore)

## Script di scoperta (storici)

`discover.py`, `probe_login.py`, `probe_api.py`, `show_api.py` sono gli
strumenti usati per ricostruire l'API. Non servono all'uso normale, ma
restano utili se l'app cambia.
