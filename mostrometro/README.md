# 👹 Mostrometro

Un termometro **fisico** stampato in 3D che misura la percentuale di mostruosità.
Premi il bottone: il mercurio sale sullo schermino, scende alla tua percentuale e il mostriciattolo si trasforma.
Dal telefono vedi la classifica di tutta la famiglia.

```
index.html                       anteprima/simulatore nel browser (senza hardware)
hardware/mostrometro.scad        modello 3D parametrico (OpenSCAD)
hardware/stl/fronte.stl, retro.stl   STL pronti da stampare
firmware/mostrometro/mostrometro.ino firmware ESP32
```

## Cosa serve (circa 20 €)
| Pezzo | Note |
|---|---|
| ESP32 con caricabatteria LiPo (tipo LOLIN D32) | ~58×25 mm, connettore JST per la batteria. Una ESP32 normale non va bene |
| Batteria LiPo piatta 3,7 V, tipo 603048 | 6×30×48 mm (~850 mAh), con circuito di protezione e connettore JST. Max 7 mm di spessore |
| Prolunga USB femmina da pannello | micro-USB o USB-C come la scheda; per ricaricare senza aprire |
| Schermo ST7789 1.3" 240×240 | SPI, 7 pin |
| Bottone arcade 30 mm | foro 24 mm |
| 3 viti M3×30 | per chiudere i gusci |
| Cavo USB + caricatore | solo per ricaricare la batteria |
| 2 occhietti adesivi da 12 mm | opzionali ma obbligatori 😈 |

## Collegamenti
| Schermo | ESP32 |
|---|---|
| GND / VCC | GND / 3V3 |
| SCL | GPIO18 |
| SDA | GPIO23 |
| RES | GPIO17 |
| DC | GPIO16 |
| BLK | GPIO4 |
| CS (se c'è) | GPIO5 |

Bottone: un filo a **GPIO27**, l'altro a **GND**.

## Stampa
- Alto 200 mm, largo 70 mm: serve un piatto da almeno 220 mm (altrimenti ridimensiona/accorcia `tube_h`).
- Stampa ogni guscio con la **faccia esterna sul piatto**, niente supporti, 0.2 mm, 3 pareti.
- **Prima misura schermo, ESP32 e bottone e correggi i parametri in cima a `mostrometro.scad`**, poi fai una prova veloce.
- Il fondo del bulbo è piatto, quindi sta in piedi. Il cavo USB esce da una tacca in basso.

## Firmware
1. Arduino IDE → installa il pacchetto **esp32** (Espressif), poi le librerie *Adafruit GFX* e *Adafruit ST7735 and ST7789*.
2. Apri `firmware/mostrometro/mostrometro.ino`, scheda "ESP32 Dev Module", carica.
3. Se lo schermo è girato cambia `ROTAZIONE`; se il tuo schermo non ha il pin CS metti `TFT_CS -1`.

## Uso
L'ESP32 crea il WiFi **Mostrometro** (password `mostro1234`, cambiala nel `.ino`).
Collegati dal telefono: la pagina si apre da sola, oppure vai su `http://192.168.4.1`.
Scrivi chi si misura e premi il bottone (sul telefono o sul termometro). La classifica resta salvata anche senza corrente (max 12 persone).

## A batteria
- La batteria LiPo va nel bulbo, dietro al bottone, e si collega al connettore JST della scheda. **Prima controlla che rosso e nero coincidano con + e − della scheda**: la polarità dei connettori non è sempre la stessa.
- Si ricarica dalla prolunga USB in basso. La carica si vede sull'iconcina in alto a destra dello schermo e sulla pagina del telefono (il pin di lettura è `PIN_BAT`, di solito GPIO35).
- Dopo 5 minuti senza uso va in **standby profondo** (schermo e WiFi spenti). Premendo il bottone si sveglia e misura subito l'ultima persona scelta. Non serve un interruttore.
- Durata (stime): circa 6 ore di uso continuo con una batteria da 850 mAh, settimane in standby. Non misurata su una batteria vera.

## Come si misura la mostruosità
Non è a caso:
- Ognuno ha una mostruosità **di base fissa** (10–65%) che dipende solo dal nome (maiuscole e accenti non contano). Se ti misuri due volte, esce lo stesso numero.
- Dal telefono si segnano le **azioni da mostro** (rutto a tavola +3, spaventa qualcuno +8…). I punti restano "in attesa".
- Alla pressione successiva del bottone il mercurio si ferma su **base + punti** (massimo 100) e lo schermo scrive di quanto sei salito, per esempio «+8 mostro!».

Le azioni e i punti si cambiano nella lista `AZ` dentro `mostrometro.ino`.

## Stato della verifica
- ✅ Modello 3D: STL validi, ingombri controllati, anteprima vista.
- ✅ Pagina web: provata nel browser con un Mostrometro simulato.
- ⚠️ Firmware: **non compilato né provato su una vera ESP32** (nessun toolchain disponibile quando è stato scritto). Può servire qualche ritocco, specie ai pin e all'orientamento dello schermo.
- ⚠️ Modello 3D non ancora stampato: le misure di schermo/bottone/scheda vanno verificate sui pezzi reali.
