#!/usr/bin/env python3
"""Seconda sonda: a login fatto, cerca gli indirizzi giusti per i dati
dei pannelli, per le credenziali MQTT e per i comandi.

Fa login (rotta confermata), prende la prima casa e il primo pannello dai
tuoi dati veri, poi prova tanti indirizzi probabili e stampa un riepilogo.
Le GET sono innocue (leggono). I comandi (POST on/off) NON vengono
lanciati: li prova solo "a vuoto" per vedere se l'indirizzo esiste, ma per
sicurezza di default sono DISATTIVATI (vedi PROVA_COMANDI in fondo).

Solo libreria standard: `python3 probe_api.py`.
"""

import getpass
import json
import os

from celsius import CelsiusClient, CelsiusError


def probe(client: CelsiusClient, method: str, path: str, body=None) -> str:
    try:
        client._request(method, path, json_body=body)
        return "esiste"
    except CelsiusError as e:
        msg = str(e)
        if "→ 404" in msg:
            return "404"
        return msg.split(": ", 1)[-1][:160]


def main() -> None:
    email = os.environ.get("CELSIUS_EMAIL") or input("Email Celsius: ").strip()
    password = os.environ.get("CELSIUS_PASSWORD") or getpass.getpass("Password: ")

    client = CelsiusClient(verbose=False)
    client.login(email, password)
    if not client.token:
        print("Login non riuscito.")
        return
    print("Login OK ✓")

    buildings = client.get_buildings()
    b = buildings[0]
    buuid = b["uuid"]
    p = b["panels"][0]
    puuid = p["uuid"]
    pid = p.get("celsiusAppId")
    ident = p.get("identifier")
    print(f"Casa: {buuid}")
    print(f"Pannello di prova: {puuid}  (celsiusAppId={pid}, identifier={ident})\n")

    # Indirizzi da provare per LEGGERE i dati / dettagli del pannello.
    get_candidates = [
        f"/buildings/{buuid}",
        f"/building/{buuid}",
        f"/buildings/{buuid}/panels",
        f"/building/{buuid}/panels",
        f"/panels/{puuid}",
        f"/panel/{puuid}",
        f"/panel/{puuid}/settings",
        f"/panel/{puuid}/stats",
        f"/panel/{puuid}/details",
        f"/panels/{pid}",
        f"/panel/{pid}",
        "/panel/settings?uuid=" + puuid,
        "/panel/settings?panelUuid=" + puuid,
        f"/user", "/users", "/me", "/profile", "/account",
        "/app-version",
    ]
    print("===== LETTURA (GET) =====")
    for path in get_candidates:
        print(f"{probe(client, 'GET', path):>10}  GET {path}")

    # Credenziali MQTT (dati in tempo reale). Proviamo GET e POST, con e
    # senza parametri.
    print("\n===== MQTT =====")
    mqtt_candidates = [
        ("GET", "/mqtt-server", None),
        ("POST", "/mqtt-server", {}),
        ("POST", "/mqtt-server", {"buildingUuid": buuid}),
        ("GET", "/mqtt", None),
        ("POST", "/mqtt", {}),
        ("GET", "/mqtt-credentials", None),
        ("POST", "/mqtt-credentials", {}),
        ("GET", "/iot", None),
        ("GET", f"/mqtt-server/{buuid}", None),
    ]
    for method, path, body in mqtt_candidates:
        print(f"{probe(client, method, path, body):>10}  {method} {path}")

    print("\nIncolla tutto questo output in chat.")


if __name__ == "__main__":
    main()
