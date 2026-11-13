// GENERATO da carte/genera_carte.py a partire da carte/azioni.py: non modificare a mano.
#pragma once
#include <stdint.h>

#define N_CARTE 100
#define CARTA_SPECIALE_MOSTRO_SUPREMO 1   // +5 a tutti e due se l'altro ha la carta Artigli da mostro, altrimenti +2
#define PUNTI_MOSTRO_SUPREMO_DA_SOLO 2

struct Carta { const char* titolo; const char* come; uint8_t punti; uint8_t speciale; const char* codice; };

const Carta CARTE[N_CARTE] = {
  {"Rutta a tavola!", "Un bel rutto da mostro, davanti a tutti.", 5, 0, "MFYE"},   // 1
  {"Fai una scoreggia!", "Vera o finta, col braccio sotto l'ascella.", 5, 0, "XDRJ"},   // 2
  {"Glu glu glu gigante", "Bevi dalla bottiglia a canna e sbrodolati tutto d'acqua.", 5, 0, "LMFF"},   // 3
  {"Bolle nel bicchiere", "Soffia nella cannuccia finché qualcuno se ne accorge.", 5, 0, "DKRW"},   // 4
  {"Starnuto da gigante", "Un finto starnuto enorme: ETCIÙÙÙ!", 5, 0, "BPUK"},   // 5
  {"Sbadiglio da leone", "Sbadiglia ruggendo, con la bocca spalancata.", 5, 0, "MFBT"},   // 6
  {"Verso del maiale", "Mangia un boccone con le mani, facendo il verso del maiale.", 5, 0, "GYTJ"},   // 7
  {"Mucca assetata", "Chiedi l'acqua muggendo: MUUUU.", 5, 0, "APPJ"},   // 8
  {"Russa a tavola", "Fingi di addormentarti e russa forte.", 5, 0, "BJTE"},   // 9
  {"Mastica rumoroso", "Mastica facendo più rumore che puoi, finché attiri l'attenzione di tutti.", 5, 0, "AGUT"},   // 10
  {"Il cucchiaio parla", "Batti il cucchiaio sul bicchiere e fai un discorso a caso, che non c'entra niente.", 5, 0, "GCEK"},   // 11
  {"Gargarismo", "Fai i gargarismi con un sorso d'acqua, a tavola.", 5, 0, "JWJV"},   // 12
  {"Pernacchia", "Fai una pernacchia lunga e sonora.", 5, 0, "GNEX"},   // 13
  {"Ruggisci!", "All'improvviso, il ruggito più forte che sai fare.", 5, 0, "ZFRL"},   // 14
  {"Ulula alla luna", "Alzati e ulula come un lupo.", 5, 0, "PYBM"},   // 15
  {"Risata da cattivo", "Ridi come il cattivo dei cartoni: MUAHAHA!", 5, 0, "YSHZ"},   // 16
  {"Voce da robot", "Parla come un robot per un minuto intero.", 5, 0, "DZDK"},   // 17
  {"Zombie affamato", "Di' «cervellooo...» con la voce da zombie.", 5, 0, "FMWL"},   // 18
  {"Drago sputafuoco", "Fingi di sputare fuoco verso il centro del tavolo.", 5, 0, "UTAY"},   // 19
  {"Il fantasma", "Fai «UUUUH» da fantasma alle spalle di qualcuno.", 5, 0, "XNCR"},   // 20
  {"Verso della scimmia", "Fai la scimmia per 5 secondi, con i versi.", 5, 0, "ELJC"},   // 21
  {"Gallina che cova", "Fai la gallina che ha appena fatto l'uovo.", 5, 0, "DYVD"},   // 22
  {"Tarzan", "Batti i pugni sul petto e fai l'urlo di Tarzan.", 5, 0, "ATXC"},   // 23
  {"Ringhio da cane", "Ringhia a una forchetta come se fosse un nemico.", 5, 0, "QYQK"},   // 24
  {"Gatto arrabbiato", "Soffia come un gatto quando qualcuno ti parla.", 5, 0, "GMAN"},   // 25
  {"La faccia più brutta", "Fai la faccia più brutta del mondo a qualcuno.", 5, 0, "QYKU"},   // 26
  {"Occhi storti", "Guarda con gli occhi storti qualcuno che sta facendo un discorso serio.", 5, 0, "CYTK"},   // 27
  {"Lingua da serpente", "Fai uscire e rientrare la lingua come un serpente.", 5, 0, "WJJW"},   // 28
  {"Orecchie da elefante", "Fai le orecchie da elefante con le mani.", 5, 0, "TVFJ"},   // 29
  {"Artigli da mostro", "Mani ad artiglio e ringhia piano verso qualcuno.", 5, 0, "NEXM"},   // 30
  {"Narici da maiale", "Spingi su il naso col dito e grugnisci.", 5, 0, "DKPU"},   // 31
  {"Sopracciglia ballerine", "Muovi le sopracciglia su e giù guardando qualcuno.", 5, 0, "RJAE"},   // 32
  {"Faccia da pesce", "Fai la bocca da pesce mentre ti parlano.", 5, 0, "QRKA"},   // 33
  {"Statua di sale", "Resta immobile come una statua, seduto sulla sedia, per 30 secondi.", 5, 0, "URAH"},   // 34
  {"Occhiolino a tutti", "Fai l'occhiolino a ognuno, uno per uno.", 5, 0, "ANNU"},   // 35
  {"Baffi finti", "Fatti i baffi con quello che trovi in giro e parla come un signore.", 5, 0, "AEDP"},   // 36
  {"Corna da mostro", "Usa qualcosa che trovi in giro come corna e incorna gli altri invitati.", 5, 0, "UJUR"},   // 37
  {"Ruba una patatina", "Prendi qualcosa dal piatto di qualcuno senza farti vedere, e continua finché non ti scopre.", 5, 0, "DYSN"},   // 38
  {"Sposta il bicchiere", "Sposta il bicchiere di qualcuno senza farti vedere e mettici al suo posto qualcos'altro.", 5, 0, "CZJD"},   // 39
  {"Cambia posto alle cose", "Scambia di posto il sale e il pepe (o due oggetti).", 5, 0, "ZSSV"},   // 40
  {"Il solletico", "Fai il solletico a qualcuno finché tutta la tavolata non se ne accorge.", 5, 0, "ZXAZ"},   // 41
  {"Nascondi la forchetta", "Nascondi la forchetta di qualcuno e fai l'innocente.", 5, 0, "KKMF"},   // 42
  {"Tocca e scappa", "Tocca la spalla di qualcuno e guarda dall'altra parte.", 5, 0, "TBCR"},   // 43
  {"Ripeti come un pappagallo", "Ripeti tutto quello che dice qualcuno per un minuto.", 5, 0, "KCZL"},   // 44
  {"BLEAH!", "Rispondi «BLEAH» alla prossima domanda che ti fanno.", 5, 0, "XUJQ"},   // 45
  {"Copia i gesti", "Imita di nascosto i gesti di qualcuno finché se ne accorge.", 5, 0, "BPYJ"},   // 46
  {"Soffio sul collo", "Soffia piano sul collo di qualcuno.", 5, 0, "MFJW"},   // 47
  {"Saluta il nulla", "Saluta con la mano qualcuno che non c'è.", 5, 0, "NHKK"},   // 48
  {"Chi è stato?", "Indica qualcuno e chiedi: «Chi ha scoreggiato?!»", 5, 0, "YUHE"},   // 49
  {"Il dito nel naso", "Fai finta di metterti il dito nel naso guardando qualcuno.", 5, 0, "VGTF"},   // 50
  {"Io sono un mostro!", "Alzati e dillo a voce alta, con orgoglio.", 5, 0, "AUSP"},   // 51
  {"Parla in rima", "Le prossime tre frasi che dici devono fare rima.", 5, 0, "HWCF"},   // 52
  {"Accento straniero", "Parla con un accento straniero per 2 minuti.", 5, 0, "QXMB"},   // 53
  {"Domanda con domanda", "Rispondi a ogni domanda con un'altra domanda.", 5, 0, "VCZB"},   // 54
  {"Canta la risposta", "La prossima risposta la devi cantare.", 5, 0, "TLJS"},   // 55
  {"Parola inventata", "Inventa una parola e usala tre volte.", 5, 0, "XCEM"},   // 56
  {"Mostro Supremo", "Chiama qualcuno «Mostro Supremo» davanti a tutti. Se ha la carta «Artigli da mostro» prendete 5 punti a testa, altrimenti tu ne prendi 2.", 5, 1, "UABV"},   // 57
  {"Barzelletta pessima", "Racconta la barzelletta più brutta che conosci. Puoi anche inventarla.", 5, 0, "MZQL"},   // 58
  {"Telecronaca", "Fai la telecronaca di qualcuno che mangia.", 5, 0, "LABL"},   // 59
  {"Annuncio importante", "Alzati e annuncia «È arrivata l'ora del mostro!», imitando Michael Jackson.", 5, 0, "LJMK"},   // 60
  {"Parla in terza persona", "Parla di te in terza persona per 2 minuti, facendo capire che sei tu il mostro più mostro.", 5, 0, "SQZD"},   // 61
  {"Complimento mostruoso", "Fai a qualcuno un complimento stranissimo.", 5, 0, "BZLW"},   // 62
  {"Sussurro misterioso", "Sussurra all'orecchio di qualcuno le risposte alle prossime 4 domande.", 5, 0, "JGGW"},   // 63
  {"Previsioni del tempo", "Rispondi alle prossime domande che ti fanno imitando il meteorologo del telegiornale.", 5, 0, "QXGK"},   // 64
  {"Balla senza musica", "Alzati e balla per 30 secondi, in silenzio.", 5, 0, "LYGW"},   // 65
  {"Passo del dinosauro", "Hai le braccine corte da T-rex e non arrivi alle posate: imitalo finché qualcuno non ti aiuta. Puoi parlare solo ruggendo.", 5, 0, "LDCD"},   // 66
  {"Giravolta", "Fai una giravolta prima di sederti.", 5, 0, "ALMW"},   // 67
  {"Il pollo", "Fai il pollo con le braccia e gira intorno al tavolo.", 5, 0, "EYTZ"},   // 68
  {"Saltella", "Fai il giro del tavolo saltellando su un piede.", 5, 0, "VRJR"},   // 69
  {"Robot che balla", "Balla come un robot per 10 secondi.", 5, 0, "EFLD"},   // 70
  {"Moonwalk", "Cammina all'indietro come Michael Jackson.", 5, 0, "EBJT"},   // 71
  {"Inchino reale", "Fai un inchino enorme a qualcuno.", 5, 0, "PFXR"},   // 72
  {"Supereroe in volo", "Fingi di volare come un supereroe per la stanza.", 5, 0, "NJFP"},   // 73
  {"Ginnastica", "Fai 5 saltelli a braccia aperte, all'improvviso.", 5, 0, "GSPN"},   // 74
  {"Pinguino", "Cammina come un pinguino fino alla cucina.", 5, 0, "QHQU"},   // 75
  {"Mossa da ninja", "Fai una mossa da ninja con il verso: HIA!", 5, 0, "ATEJ"},   // 76
  {"Zanne di patatine", "Mettiti due patatine (o due grissini) come zanne.", 5, 0, "NQWV"},   // 77
  {"Telefono di pane", "Usa un pezzo di pane come telefono: «Pronto?»", 5, 0, "PKME"},   // 78
  {"Parla al cibo", "Dai un nome al tuo cibo e parlagli.", 5, 0, "CMEN"},   // 79
  {"Annusa come un cane", "Annusa il piatto come un cane, molto da vicino.", 5, 0, "DDPD"},   // 80
  {"Brindisi al mostro", "Alza il bicchiere e brinda: «Al Mostrometro!»", 5, 0, "RVNP"},   // 81
  {"Assaggiatore", "Assaggia un boccone e dai un voto da giudice di cucina.", 5, 0, "HGKT"},   // 82
  {"Bocca piena", "Prova a dire «sopra la panca la capra campa» dopo un boccone.", 5, 0, "LQZM"},   // 83
  {"Il pirata", "Parla al cibo come un pirata: «Arrr, ti mangerò!»", 5, 0, "LZFE"},   // 84
  {"Occhi di oliva", "Metti due olive (o due cose rotonde) davanti agli occhi.", 5, 0, "HPZK"},   // 85
  {"Chef matto", "Racconta come hai «cucinato» il tuo piatto, inventando tutto.", 5, 0, "MCYA"},   // 86
  {"Sono pieno!", "Gonfia la pancia e di': «Non ce la faccio più!»", 5, 0, "ELLN"},   // 87
  {"Mangia a occhi chiusi", "Mangia un boccone a occhi chiusi, facendo «mmmh».", 5, 0, "LFMZ"},   // 88
  {"Cappello di tovagliolo", "Mettiti il tovagliolo in testa come un cappello.", 5, 0, "EWQM"},   // 89
  {"Abbraccio da orso", "Abbraccia qualcuno ruggendo come un orso.", 5, 0, "GSAS"},   // 90
  {"Applauso infinito", "Applaudi da solo finché qualcuno ti chiede perché.", 5, 0, "VBQS"},   // 91
  {"Risata contagiosa", "Ridi forte senza motivo per 10 secondi.", 5, 0, "XFDP"},   // 92
  {"Sono stato io!", "Alzati e confessa una marachella inventata.", 5, 0, "SYKH"},   // 93
  {"Selfie con faccia", "Fai un selfie con qualcuno facendo la faccia da mostro.", 5, 0, "CSDQ"},   // 94
  {"Interrogatorio", "Chiedi a qualcuno: «Dov'eri ieri alle 8?» molto serio.", 5, 0, "YSJD"},   // 95
  {"Coro da stadio", "Fai partire un coro da stadio per il Mostrometro.", 5, 0, "YBUA"},   // 96
  {"Il mago", "Fai una «magia»: tocca un oggetto e di' «abracadabra».", 5, 0, "EBGH"},   // 97
  {"Poeta", "Recita una poesia di due righe dedicata a qualcuno.", 5, 0, "PHFQ"},   // 98
  {"Pausa drammatica", "Alzati, guarda tutti, poi risiediti senza dire niente.", 5, 0, "PZJD"},   // 99
  {"Saluto militare", "Fai il saluto militare a ogni persona che parla.", 5, 0, "XQEN"},   // 100
};
