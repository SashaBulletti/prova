#!/usr/bin/env python3
"""Segna i disegni pronti (presi dal risultato di jobs_wait). Uso: python3 aggiungi.py 14:202515 18:202515 ...
(numero della carta : ora che compare nell'indirizzo del risultato)"""
import os, sys
QUI = os.path.dirname(os.path.abspath(__file__))
BASE = "https://d8j0ntlcm91z4.cloudfront.net/user_3FHUKaBe728kYxp60It1RuqPDJ3/hf_20261114_"
jobs = {}
for l in open(os.path.join(QUI, "jobs.txt")):
    if l.strip():
        n, j = l.split()
        jobs[n] = j            # per la carta 3 vale l'ultimo lavoro (il nuovo tentativo)
fatti = {l.split()[0] for l in open(os.path.join(QUI, "urls.txt")) if l.strip()}
with open(os.path.join(QUI, "urls.txt"), "a") as f:
    for a in sys.argv[1:]:
        n, ora = a.split(":")
        if n not in fatti:
            f.write(f"{n} {BASE}{ora}_{jobs[n]}.png\n")
            fatti.add(n)
print(len(fatti), "pronti; mancano:", " ".join(sorted(set(jobs) - fatti, key=int)))
