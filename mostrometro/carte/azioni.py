"""Le 100 azioni da mostro delle carte del Mostrometro.

Ogni carta: (titolo, come farlo). Il titolo e' la scritta grande sulla carta, "come" e' la riga piccola sotto.
Ogni carta fatta vale PUNTI_CARTA punti di mostruosita'.
Le azioni sono pensate per una serata in famiglia: buffe e a sorpresa, mai pericolose, senza sprecare cibo
e senza mettere davvero in imbarazzo nessuno. Si possono cambiare liberamente qui e poi rigenerare le carte.
"""

PUNTI_CARTA = 5

GRUPPI = {
    "Rumori a tavola": [
        ("Rutta a tavola!", "Un bel rutto da mostro, davanti a tutti."),
        ("Fai una scoreggia!", "Vera o finta, col braccio sotto l'ascella."),
        ("Slurp gigante", "Bevi facendo il rumore più forte possibile."),
        ("Bolle nel bicchiere", "Soffia nella cannuccia finché qualcuno se ne accorge."),
        ("Starnuto da gigante", "Un finto starnuto enorme: ETCIÙÙÙ!"),
        ("Sbadiglio da leone", "Sbadiglia ruggendo, con la bocca spalancata."),
        ("Verso del maiale", "Mangia un boccone facendo il verso del maiale."),
        ("Mucca assetata", "Chiedi l'acqua muggendo: MUUUU."),
        ("Russa a tavola", "Fingi di addormentarti e russa forte."),
        ("Mastica rumoroso", "Mastica facendo più rumore che puoi per 10 secondi."),
        ("Il cucchiaio parla", "Batti il cucchiaio sul bicchiere e annuncia: «Ho un discorso!»"),
        ("Gargarismo", "Fai i gargarismi con un sorso d'acqua, a tavola."),
        ("Pernacchia", "Fai una pernacchia lunga e sonora."),
    ],
    "Versi da mostro": [
        ("Ruggisci!", "All'improvviso, il ruggito più forte che sai fare."),
        ("Ulula alla luna", "Alzati e ulula come un lupo."),
        ("Risata da cattivo", "Ridi come il cattivo dei cartoni: MUAHAHA!"),
        ("Voce da robot", "Parla come un robot per un minuto intero."),
        ("Zombie affamato", "Di' «cervellooo...» con la voce da zombie."),
        ("Drago sputafuoco", "Fingi di sputare fuoco verso il centro del tavolo."),
        ("Il fantasma", "Fai «UUUUH» da fantasma alle spalle di qualcuno."),
        ("Verso della scimmia", "Fai la scimmia per 5 secondi, con i versi."),
        ("Gallina che cova", "Fai la gallina che ha appena fatto l'uovo."),
        ("Tarzan", "Batti i pugni sul petto e fai l'urlo di Tarzan."),
        ("Ringhio da cane", "Ringhia a una forchetta come se fosse un nemico."),
        ("Gatto arrabbiato", "Soffia come un gatto quando qualcuno ti parla."),
    ],
    "Facce e gesti": [
        ("La faccia più brutta", "Fai la faccia più brutta del mondo a qualcuno."),
        ("Occhi storti", "Guarda qualcuno con gli occhi storti per 5 secondi."),
        ("Lingua da serpente", "Fai uscire e rientrare la lingua come un serpente."),
        ("Orecchie da elefante", "Fai le orecchie da elefante con le mani."),
        ("Artigli da mostro", "Mani ad artiglio e ringhia piano verso qualcuno."),
        ("Narici da maiale", "Spingi su il naso col dito e grugnisci."),
        ("Sopracciglia ballerine", "Muovi le sopracciglia su e giù guardando qualcuno."),
        ("Faccia da pesce", "Fai la bocca da pesce mentre ti parlano."),
        ("Statua di sale", "Resta immobile come una statua per 20 secondi."),
        ("Occhiolino a tutti", "Fai l'occhiolino a ognuno, uno per uno."),
        ("Baffi finti", "Fatti i baffi con un dito e parla come un signore."),
        ("Corna da mostro", "Metti due dita sulla testa come corna per un minuto."),
    ],
    "Dispetti innocui": [
        ("Ruba una patatina", "Prendi qualcosa dal piatto di qualcuno, senza farti vedere."),
        ("Sposta il bicchiere", "Sposta il bicchiere di qualcuno senza che se ne accorga."),
        ("Cambia posto alle cose", "Scambia di posto il sale e il pepe (o due oggetti)."),
        ("Il solletico", "Fai il solletico a qualcuno, solo un attimo."),
        ("Nascondi la forchetta", "Nascondi la forchetta di qualcuno e fai l'innocente."),
        ("Tocca e scappa", "Tocca la spalla di qualcuno e guarda dall'altra parte."),
        ("Ripeti come un pappagallo", "Ripeti tutto quello che dice qualcuno per un minuto."),
        ("BLEAH!", "Rispondi «BLEAH» alla prossima domanda che ti fanno."),
        ("Copia i gesti", "Imita di nascosto i gesti di qualcuno finché se ne accorge."),
        ("Soffio sul collo", "Soffia piano sul collo di qualcuno."),
        ("Saluta il nulla", "Saluta con la mano qualcuno che non c'è."),
        ("Chi è stato?", "Indica qualcuno e chiedi: «Chi ha scoreggiato?!»"),
        ("Il dito nel naso", "Fai finta di metterti il dito nel naso guardando qualcuno."),
    ],
    "Parole e frasi": [
        ("Io sono un mostro!", "Alzati e dillo a voce alta, con orgoglio."),
        ("Parla in rima", "Le prossime tre frasi che dici devono fare rima."),
        ("Accento straniero", "Parla con un accento straniero per 2 minuti."),
        ("Domanda con domanda", "Rispondi a ogni domanda con un'altra domanda."),
        ("Canta la risposta", "La prossima risposta la devi cantare."),
        ("Parola inventata", "Inventa una parola e usala tre volte."),
        ("Mostro Supremo", "Chiama qualcuno «Mostro Supremo» davanti a tutti."),
        ("Barzelletta pessima", "Racconta la barzelletta più brutta che conosci."),
        ("Telecronaca", "Fai la telecronaca di qualcuno che mangia."),
        ("Annuncio importante", "Alzati e annuncia: «È arrivata l'ora del mostro!»"),
        ("Parla in terza persona", "Parla di te come «il Mostro» per 2 minuti."),
        ("Complimento mostruoso", "Fai un complimento strano: «Hai un naso magnifico!»"),
        ("Sussurro misterioso", "Sussurra all'orecchio di qualcuno: «Lo so...»"),
        ("Previsioni del tempo", "Annuncia che domani pioveranno polpette."),
    ],
    "Movimento e ballo": [
        ("Balla senza musica", "Alzati e balla 10 secondi, in silenzio."),
        ("Passo del dinosauro", "Cammina per la stanza come un T-rex."),
        ("Giravolta", "Fai una giravolta prima di sederti."),
        ("Il pollo", "Fai il pollo con le braccia e gira intorno al tavolo."),
        ("Saltella", "Fai il giro del tavolo saltellando su un piede."),
        ("Robot che balla", "Balla come un robot per 10 secondi."),
        ("Moonwalk", "Cammina all'indietro come Michael Jackson."),
        ("Inchino reale", "Fai un inchino enorme a qualcuno."),
        ("Supereroe in volo", "Fingi di volare come un supereroe per la stanza."),
        ("Ginnastica", "Fai 5 saltelli a braccia aperte, all'improvviso."),
        ("Pinguino", "Cammina come un pinguino fino alla cucina."),
        ("Mossa da ninja", "Fai una mossa da ninja con il verso: HIA!"),
    ],
    "Cibo da mostro": [
        ("Zanne di patatine", "Mettiti due patatine (o due grissini) come zanne."),
        ("Telefono di pane", "Usa un pezzo di pane come telefono: «Pronto?»"),
        ("Parla al cibo", "Dai un nome al tuo cibo e parlagli."),
        ("Annusa come un cane", "Annusa il piatto come un cane, molto da vicino."),
        ("Brindisi al mostro", "Alza il bicchiere e brinda: «Al Mostrometro!»"),
        ("Assaggiatore", "Assaggia un boccone e dai un voto da giudice di cucina."),
        ("Bocca piena", "Prova a dire «sopra la panca la capra campa» dopo un boccone."),
        ("Il pirata", "Parla al cibo come un pirata: «Arrr, ti mangerò!»"),
        ("Occhi di oliva", "Metti due olive (o due cose rotonde) davanti agli occhi."),
        ("Chef matto", "Racconta come hai «cucinato» il tuo piatto, inventando tutto."),
        ("Sono pieno!", "Gonfia la pancia e di': «Non ce la faccio più!»"),
        ("Mangia a occhi chiusi", "Mangia un boccone a occhi chiusi, facendo «mmmh»."),
        ("Cappello di tovagliolo", "Mettiti il tovagliolo in testa come un cappello."),
    ],
    "A sorpresa": [
        ("Abbraccio da orso", "Abbraccia qualcuno ruggendo come un orso."),
        ("Applauso infinito", "Applaudi da solo finché qualcuno ti chiede perché."),
        ("Risata contagiosa", "Ridi forte senza motivo per 10 secondi."),
        ("Sono stato io!", "Alzati e confessa una marachella inventata."),
        ("Selfie con faccia", "Fai un selfie con qualcuno facendo la faccia da mostro."),
        ("Interrogatorio", "Chiedi a qualcuno: «Dov'eri ieri alle 8?» molto serio."),
        ("Coro da stadio", "Fai partire un coro da stadio per il Mostrometro."),
        ("Il mago", "Fai una «magia»: tocca un oggetto e di' «abracadabra»."),
        ("Poeta", "Recita una poesia di due righe dedicata a qualcuno."),
        ("Pausa drammatica", "Alzati, guarda tutti, poi risiediti senza dire niente."),
        ("Saluto militare", "Fai il saluto militare a ogni persona che parla."),
    ],
}

AZIONI = [(gruppo, titolo, come) for gruppo, carte in GRUPPI.items() for titolo, come in carte]

if __name__ == "__main__":
    print(len(AZIONI), "azioni")
    for g, c in GRUPPI.items():
        print(f"  {g}: {len(c)}")
    titoli = [t for _, t, _ in AZIONI]
    doppi = {t for t in titoli if titoli.count(t) > 1}
    print("doppioni:", doppi or "nessuno")
    print("titolo piu' lungo:", max(titoli, key=len), len(max(titoli, key=len)))
    print("riga piu' lunga:", max(len(c) for _, _, c in AZIONI))
