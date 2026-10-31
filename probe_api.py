#!/usr/bin/env python3
"""Quarta sonda: scarica il "manuale automatico" dell'API (OpenAPI).

Il sistema e' API Platform: espone la lista completa di indirizzi, metodi
(GET/POST/PUT/PATCH) e comandi. Qui la scarichiamo e stampiamo solo le
parti utili (pannelli, modalita', temperatura, programmi, consumi, mqtt).
Salva anche il file intero in openapi.json nella cartella, per riferimento.

Solo letture. Solo libreria standard: `python3 probe_api.py`.
"""

import getpass
import json
import os
import urllib.error
import urllib.request

from celsius import CelsiusClient

BASE = "https://crmapp.celsiuspanel.it/api"


def raw_get(token: str, path: str, accept: str = "*/*"):
    url = BASE + path
    req = urllib.request.Request(url, method="GET", headers={
        "Accept": accept,
        "Authorization": f"Bearer {token}",
        "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
    })
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except urllib.error.URLError as e:
        return -1, f"(rete) {e.reason}"


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

    # Proviamo i soliti indirizzi del "manuale automatico" di API Platform.
    spec = None
    for path in ("/docs.json", "/docs.jsonopenapi", "/docs", ".json", "/index.json"):
        status, body = raw_get(token, path)
        if status == 200 and body.strip().startswith("{"):
            try:
                data = json.loads(body)
            except ValueError:
                continue
            if "paths" in data or "openapi" in data or "swagger" in data:
                spec = data
                print(f"Manuale trovato su: /api{path}")
                break

    if not spec:
        print("Manuale OpenAPI non trovato sugli indirizzi soliti.")
        print("Provo l'elenco risorse (entrypoint)...")
        status, body = raw_get(token, "")
        print(f"\n--- GET /api → {status}")
        print(body[:3000])
        return

    # Salva il file intero.
    with open("openapi.json", "w") as f:
        json.dump(spec, f, indent=2, ensure_ascii=False)
    print("Salvato openapi.json (completo).\n")

    paths = spec.get("paths", {})
    print(f"===== TUTTI GLI INDIRIZZI ({len(paths)}) =====")
    for p in sorted(paths):
        methods = ",".join(sorted(m.upper() for m in paths[p] if m.lower() in
                   ("get", "post", "put", "patch", "delete")))
        print(f"  {methods:<20} {p}")

    # Cerca le parole chiave che ci interessano.
    print("\n===== INDIRIZZI INTERESSANTI (modalita'/temp/mqtt/consumi) =====")
    kw = ("mode", "mqtt", "scheduling", "measurement", "temperature",
          "manual", "restart", "firmware", "stat")
    for p in sorted(paths):
        if any(k in p.lower() for k in kw):
            for m, info in paths[p].items():
                if m.lower() in ("get", "post", "put", "patch", "delete"):
                    summary = (info.get("summary") or
                               info.get("description") or "")[:70]
                    print(f"  {m.upper():<7} {p}   {summary}")

    # Schema del Panel: quali campi si possono scrivere.
    schemas = spec.get("components", {}).get("schemas", {})
    for name in schemas:
        if name.lower() in ("panel", "panel-write", "panel.jsonld",
                             "panel-panel.write"):
            print(f"\n===== SCHEMA {name} =====")
            props = schemas[name].get("properties", {})
            for prop, meta in props.items():
                t = meta.get("type", meta.get("$ref", "?"))
                ro = " (sola lettura)" if meta.get("readOnly") else ""
                print(f"  {prop}: {t}{ro}")

    print("\nIncolla in chat la parte 'TUTTI GLI INDIRIZZI' e "
          "'INDIRIZZI INTERESSANTI'. (openapi.json resta sul tuo Mac.)")


if __name__ == "__main__":
    main()
