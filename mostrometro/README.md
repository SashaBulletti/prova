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
| ESP32 DevKit (38 pin) | ~51×28 mm |
| Schermo ST7789 1.3" 240×240 | SPI, 7 pin |
| Bottone arcade 30 mm | foro 24 mm |
| 3 viti M3×30 | per chiudere i gusci |
| Cavo USB + caricatore | alimentazione |
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

## Stato della verifica
- ✅ Modello 3D: STL validi, ingombri controllati, anteprima vista.
- ✅ Pagina web: provata nel browser con un Mostrometro simulato.
- ⚠️ Firmware: **non compilato né provato su una vera ESP32** (nessun toolchain disponibile quando è stato scritto). Può servire qualche ritocco, specie ai pin e all'orientamento dello schermo.
- ⚠️ Modello 3D non ancora stampato: le misure di schermo/bottone/scheda vanno verificate sui pezzi reali.
