# 👹 Mostrometro

Un mostro-totem stampato in 3D, **a batteria**, che misura la percentuale di mostruosità.
Premi il suo naso rosso: il mercurio sale lungo lo schermo, scende alla tua percentuale e il mostriciattolo si trasforma.
Dal telefono vedi la classifica di tutta la famiglia.

```
progetto.html                    guida passo passo (si legge meglio pubblicata), con il 3D da girare e aprire
index.html                       anteprima nel browser (senza hardware)
hardware/mostrometro.scad        modello 3D parametrico (OpenSCAD)
hardware/stl/                    STL pronti: fronte.stl + retro.stl + piedistallo.stl (totem B), A_fronte.stl + A_retro.stl (mostro tondo A)
hardware/bake_modello.py         rigenera modello.js (il 3D della pagina) dopo aver cambiato gli STL
firmware/mostrometro/mostrometro.ino firmware
```

## Cosa serve (circa 45 €)
| Pezzo | Note |
|---|---|
| **LilyGO T-Display S3 Long** | Una sola scheda: ESP32-S3 con WiFi, schermo lungo 3,4" (180×640), presa USB-C e caricabatteria. ~92×28 mm |
| Batteria LiPo piatta 3,7 V, tipo 603048 | 6×30×48 mm (~850 mAh), con protezione e il connettore della scheda (JST-GH 1,25 mm: controlla). Max 7 mm di spessore |
| Bottone arcade 30 mm | è il naso; foro da 24 mm |
| 3 viti M3×25 | chiudono i gusci da dietro |
| 2 occhietti adesivi da 14 mm | |
| Due fili sottili e stagno | per collegare il bottone |
| Cavo USB-C + caricatore | solo per ricaricare |

## Collegamenti
Schermo e ricarica sono già sulla scheda. Resta solo il bottone: **due fili in parallelo al pulsantino BOOT** della scheda (GPIO0).
Se premi il bottone mentre la scheda si sta accendendo entra nel modo "download" (schermo nero): rilascia e riaccendi.
Batteria nel connettore della scheda (**controlla rosso/nero e + / −**) e interruttore della scheda su ON.

## Stampa
- **Due forme, come nei disegni:** B = totem col sorriso (70×193 mm, alto e stretto), A = mostro tondo con braccia e piedi (142×203 mm). Dall'alto: occhi, schermo lungo, bottone-naso. Per cambiare nel modello scrivi `forma = "A"` o `"B"` in cima a `mostrometro.scad`; il 3D di `progetto.html` le mostra entrambe.
- Servono almeno 210 mm di piatto (B: 70×193 mm, A: 142×203 mm). La A impiega molto più filo e tempo.
- Ogni guscio con la **faccia esterna sul piatto**, niente supporti, 0,2 mm, 3 pareti.
- **Prima misura scheda, bottone e batteria e correggi i parametri in cima a `mostrometro.scad`**, poi fai una prova veloce.
- Il totem B sta in piedi nel **piedistallo** (da stampare a parte), la A sui suoi piedini. La presa USB-C è **in cima alla testa**, tra le corna: monta la scheda con la presa verso l'alto (in basso il corpo del bottone bloccherebbe il cavo).

## Firmware
1. Dal repository del produttore (`Xinyuan-LilyGO/T-Display-S3-Long`) copia la cartella `lib/` nelle librerie di Arduino.
2. **Prova prima l'esempio ufficiale `GFX_AXS15231B_Image`**: lo schermo deve accendersi. Se l'esempio inizializza anche il chip di alimentazione, copia quella parte in `schedaInit()` del nostro programma.
3. Apri `firmware/mostrometro/mostrometro.ino`, scheda "ESP32S3 Dev Module", PSRAM OPI, flash 16 MB, e carica.
4. Se la percentuale della batteria è sbagliata cambia `BAT_DIV` (il rapporto del partitore non l'ho trovato nei documenti).

## Uso
La scheda crea il WiFi **Mostrometro** (password `mostro1234`, cambiala nel `.ino`).
Collegati dal telefono: la pagina si apre da sola, oppure vai su `http://192.168.4.1`.
Scrivi chi si misura e premi il bottone (sul telefono o sul mostro). La classifica resta salvata anche senza corrente (max 12 persone).

## A batteria
- Si ricarica dalla presa USB-C in cima alla testa. La carica si vede in basso sullo schermo e sulla pagina del telefono.
- Dopo 5 minuti senza uso va in **standby profondo** (schermo e WiFi spenti). Premendo il bottone si sveglia e misura subito l'ultima persona scelta.
- Durata (dati del produttore: 90–350 mA acceso, ~1,1 mA in standby): da 2 a 9 ore di uso continuo con 850 mAh, circa un mese in standby. Non misurata su una batteria vera.

## Come si misura la mostruosità
Non è a caso:
- Ognuno ha una mostruosità **di base fissa** (10–65%) che dipende solo dal nome (maiuscole e accenti non contano). Se ti misuri due volte, esce lo stesso numero.
- Dal telefono si segnano le **azioni da mostro** (rutto a tavola +3, spaventa qualcuno +8…). I punti restano "in attesa".
- Alla pressione successiva del bottone il mercurio si ferma su **base + punti** (massimo 100) e lo schermo scrive di quanto sei salito, per esempio «+8 mostro!».

Le azioni e i punti si cambiano nella lista `AZ` dentro `mostrometro.ino`.

## Stato della verifica
- ✅ Modello 3D: STL validi, ingombri controllati, anteprima vista.
- ✅ Pagina web: provata nel browser con un Mostrometro simulato.
- ✅ Regole di misura, batteria, standby e frasi sullo schermo: provate al computer con una scheda simulata.
- ⚠️ **Schermo e scheda: il firmware segue l'esempio del produttore ma non è mai girato su una vera LilyGO S3 Long.** Può servire qualche ritocco (pin, alimentazione, orientamento).
- ⚠️ Non so da che parte sta la presa USB-C sulla scheda (qui è messa in cima) né dove sta l'interruttore: vanno controllati prima di stampare.
- ⚠️ Modello 3D non ancora stampato: le misure di scheda, bottone e batteria vanno verificate sui pezzi reali.
