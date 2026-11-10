#!/bin/sh
# Prova il programma del Mostrometro AL COMPUTER, con una scheda finta (nessuna scheda vera serve).
# Controlla: accensione a batteria, ordine dei suoni, "sei al / sei all'", punti dell'urlo, standby, spegnimento, batteria.
# Serve solo g++.   Uso:  sh prova.sh
cd "$(dirname "$0")" && g++ -std=c++17 -Wall -pthread -include Arduino.h -I. -o prova_mostrometro_bin test2.cpp && ./prova_mostrometro_bin
