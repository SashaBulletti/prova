#!/usr/bin/env python3
"""Terza sonda: stampa il CONTENUTO completo degli indirizzi che funzionano.

Login, poi scarica e mostra per intero:
  - il dettaglio della casa (GET /buildings/<uuid>)
  - il dettaglio del pannello, provando varie intestazioni "Accept"
    (una di queste dovrebbe sbloccare il "formato non supportato")

Solo letture, niente comandi. Solo libreria standard: `python3 probe_api.py`.
"""

import getpass
import json
import os
import urllib.error
import urllib.request

from celsius import CelsiusClient

BASE = "https://crmapp.celsiuspanel.it/api"


def raw_get(token: str, path: str, accept: str) -> None:
    url = BASE + path
    req = urllib.request.Request(url, method="GET", headers={
        "Accept": accept,
        "Authorization": f"Bearer {token}",
        "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
    })
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            status, body = resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        status, body = e.code, e.read().decode("utf-8", "replace")
    except urllib.error.URLError as e:
        status, body = -1, f"(rete) {e.reason}"
    print(f"\n--- GET {path}   [Accept: {accept}]  → {status}")
    # Se è JSON, lo stampo indentato; altrimenti i primi caratteri.
    try:
        print(json.dumps(json.loads(body), indent=2, ensure_ascii=False)[:4000])
    except ValueError:
        print(body[:1500])


def main() -> None:
    email = os.environ.get("CELSIUS_EMAIL") or input("Email Celsius: ").strip()
    password = os.environ.get("CELSIUS_PASSWORD") or getpass.getpass("Password: ")

    client = CelsiusClient()
    client.login(email, password)
    if not client.token:
        print("Login non riuscito.")
        return
    token = client.token
    print("Login OK ✓")

    buildings = client.get_buildings()
    b = buildings[0]
    buuid = b["uuid"]
    p = b["panels"][0]
    puuid = p["uuid"]
    pid = p.get("celsiusAppId")

    # 1) Dettaglio casa completo.
    print("\n===== DETTAGLIO CASA =====")
    raw_get(token, f"/buildings/{buuid}", "application/json")

    # 2) Dettaglio pannello, provando Accept diversi.
    print("\n===== DETTAGLIO PANNELLO (varie intestazioni) =====")
    for accept in ("*/*", "application/json", "application/ld+json",
                   "application/hal+json", "text/html"):
        raw_get(token, f"/panels/{puuid}", accept)

    # 3) Elenco pannelli della casa + pannello via id numerico.
    print("\n===== ALTRI INDIRIZZI =====")
    raw_get(token, f"/buildings/{buuid}/panels", "*/*")
    raw_get(token, f"/panels/{pid}", "*/*")

    print("\n\nIncolla tutto questo output in chat.")


if __name__ == "__main__":
    main()
