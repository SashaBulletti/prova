# Celsius Panel — client non ufficiale

App alternativa per gestire i pannelli riscaldanti **Celsius Panel**
(Tesi Group), pensata per collegarli ad **Alexa, Google Home e Home Assistant**.

> Progetto personale per i propri pannelli. Non affiliato a Tesi Group / Celsius Panel.

## Com'è fatto il sistema Celsius (quello che sappiamo)

Ricavato dall'app ufficiale (Flutter, `it.celsiuspanel.celsius` v1.4.9):

- **Server REST** `https://crmapp.celsiuspanel.it` — login (token JWT), lista
  case e pannelli, comandi (on/off/auto, temperatura, programmi).
- **MQTT su AWS IoT Core** (`...eu-west-1.amazonaws.com`) — dati in tempo reale:
  temperatura interna/esterna, umidità, consumo in W, stato online/offline.
  Le credenziali per il broker arrivano dall'endpoint `/mqtt-server`.
- **Pannello = dispositivo ESP32** (probabile): in configurazione crea un
  hotspot `CELSIUS_PANEL` e risponde su `192.168.4.1`.

Gli endpoint sono mappati in [`celsius/const.py`](celsius/const.py).

## A che punto siamo

- [x] Mappati host ed endpoint dall'app
- [x] Scheletro del client REST + script di scoperta
- [ ] Confermare dal vivo login e formato dei dati (`discover.py`)
- [ ] Comandi (on/off/auto, temperatura) verificati
- [ ] Canale MQTT per i dati in tempo reale
- [ ] Integrazione Home Assistant (ogni pannello = termostato)
- [ ] Funzioni extra: "spegni/accendi tutto", stessa temperatura a tutti,
      taglio carichi quando si carica l'auto (anti–salto contatore)

## Come provare il login

```bash
pip install -r requirements.txt
python discover.py
```

Fa **solo letture** (non comanda i pannelli) e stampa cosa risponde il
server, così tariamo il client sui dati reali. Email e password non vengono
salvate.
