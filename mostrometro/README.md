# 👹 Mostrometro

Un mostro stampato in 3D, **a batteria**, che misura la percentuale di mostruosità.
Premi il suo naso rosso: fa il suo verso, il mercurio sale lungo lo schermo e il mostro dice «sei al sessanta per cento».
Tieni premuto il naso e urla: il microfono ascolta e ti dà dei punti. Dal telefono vedi la classifica di tutta la famiglia.

**Per costruirlo leggi `progetto.html`**: è la guida passo passo (cosa comprare, dove saldare, come caricare il programma), con il modello 3D da girare e aprire.

```
progetto.html                        la guida (si legge meglio pubblicata)
app_anteprima.html                   l'app del telefono con un Mostrometro simulato (si rigenera con firmware/anteprima_app.py)
mascotte/                            la mascotte: in piedi, adesivo e versione piccola per l'app
hardware/mostrometro.scad            modello 3D parametrico (OpenSCAD), forme A e B
hardware/stl/                        STL pronti: fronte.stl + retro.stl + piedistallo.stl (totem B), A_fronte.stl + A_retro.stl (mostro tondo A)
hardware/bake_modello.py             rigenera modello.js (il 3D della guida) dopo aver cambiato gli STL
firmware/mostrometro/                il programma (mostrometro.ino, scheda.h, audio_dati.h) e LEGGIMI.txt
firmware/prova_bottone/              prova per controllare le saldature del bottone
firmware/genera_audio.py             genera la voce e i versi (audio_dati.h)
firmware/prova_al_computer/          prova il programma al computer con una scheda finta (sh prova.sh)
```

## Cosa serve (circa 60 €)
| Pezzo | Note |
|---|---|
| **Waveshare ESP32-S3-Touch-LCD-3.49, versione V2** | Una sola scheda: ESP32-S3 con WiFi, schermo lungo 3,49", 2 microfoni, uscita altoparlante, USB-C e caricabatteria. Quella senza batteria (nome che finisce con `-EN`) |
| Batteria LiPo piatta 3,7 V, circa 6×34×50 mm (tipo 603450) | Almeno 1000 mAh (la scheda carica a circa 1 A), spina MX1.25 a 2 poli |
| Altoparlante rotondo 28 mm, 8 Ω, 1 W | Con spina MX1.25 a 2 poli |
| Bottone arcade 30 mm | È il naso; foro da 24 mm; microinterruttore con linguette C, NO, NC |
| 2 fili sottili, saldatore e stagno | Servono **4 saldature**, solo per il bottone |
| 4 viti M3×25, 2 occhietti adesivi | |
| Cavo USB-C + caricatore | Per ricaricare e per caricare il programma |

## Collegamenti: solo 4 saldature
- Filo **nero**: piazzola **G** della scheda ↔ linguetta **C** del bottone.
- Filo **rosso**: piazzola **1** della scheda ↔ linguetta **NO** del bottone.
- Altoparlante e batteria si infilano nelle loro prese sul retro della scheda (controlla il + e il − della batteria).
- Schermo, microfoni, ricarica e USB-C sono già sulla scheda.

Il disegno e la spiegazione da zero sono in `progetto.html`, fase 4.

## Cosa fa
- Ognuno ha una mostruosità **di base fissa** (10–65%) che dipende solo dal nome. Se ti misuri due volte, esce lo stesso numero.
- Dal telefono si segnano le **azioni da mostro** (rutto a tavola +3, spaventa qualcuno +8…) e si può **urlare** nel microfono (0–10 punti). I punti restano "in attesa".
- Alla pressione successiva del naso il mercurio si ferma su **base + punti** (massimo 100) e lo schermo scrive di quanto sei salito, per esempio «+8 mostro!».
- 6 versi di mostro (uno per livello) e la voce che dice la percentuale. La voce è sintetica (`espeak-ng`), abbassata e rauca; si cambia con `firmware/genera_audio.py`.
- Dall'app si aggiungono le persone della famiglia (fino a 12) e si tocca un nome per scegliere chi si misura.
- La classifica resta salvata anche senza corrente.
- A batteria: dopo 5 minuti senza uso va in **standby** (schermo, suoni e WiFi spenti); il naso lo risveglia.

## Come si carica il programma (in breve)
Passo passo, con le immagini, in `progetto.html` (fase 5). In sintesi:
1. Arduino IDE 2, pacchetto **esp32 di Espressif versione 3.3.0**, libreria **GFX Library for Arduino**.
2. Dal repository `waveshareteam/ESP32-S3-Touch-LCD-3.49-V2` copia nella cartella del programma `i2c_bsp.c/.h`, `user_config.h` e `src/` (solo `codec_board`, `esp_codec_dev`, `tca9554`) da `Arduino/examples/08_Audio_Test`.
3. Strumenti: ESP32S3 Dev Module, USB CDC On Boot Enabled, Flash 16MB, PSRAM OPI, Partition Scheme *Huge APP*.
4. Prima carica `prova_bottone` per controllare le saldature, poi `mostrometro`.

## Uso
Non c'è niente da installare sul telefono: l'app è una pagina che sta dentro il Mostrometro.
La scheda crea il WiFi **Mostrometro** (password `mostro1234`, cambiala nel `.ino`). Collegati dal telefono: la pagina si apre da sola, oppure vai su `http://192.168.4.1`.
Scrivi chi si misura e premi il naso (sul telefono o sul mostro).

## Come si misura la mostruosità
Non è a caso: base fissa dal nome + punti delle azioni e dell'urlo. Le azioni e i punti si cambiano nella lista `AZ` dentro `mostrometro.ino`.

## Stato della verifica
- ✅ Modello 3D: STL validi, misure della scheda dal modello 3D del produttore.
- ✅ Pin, indirizzi e accensione a batteria: letti dallo schema e dagli esempi ufficiali Waveshare (V2).
- ✅ Pagina web: provata nel browser.
- ✅ Logica del programma: 18 controlli al computer con una scheda finta (`firmware/prova_al_computer`).
- ⚠️ **Il programma non è mai girato sulla scheda vera.** Schermo, audio e microfoni possono richiedere ritocchi; volume e sensibilità del microfono vanno regolati (`scheda.h`).
- ⚠️ Non so lo spessore esatto della scheda con lo schermo, da che parte guardano i microfoni, quanto consuma né la corrente di ricarica della V2: vanno controllati con la scheda in mano.
- ⚠️ Modello 3D non ancora stampato: le misure di scheda, bottone, altoparlante e batteria vanno verificate sui pezzi reali.
