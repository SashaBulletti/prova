#!/usr/bin/env python3
"""Trova l'endpoint di login giusto provandone tanti in un colpo solo.

Sappiamo che l'API sta sotto https://crmapp.celsiuspanel.it/api ma non
sappiamo il nome preciso della rotta di login. Questo script prova una
lista di nomi probabili e di formati di richiesta, poi stampa un riepilogo:
- 404  = quella rotta non esiste
- 200  = funziona (e probabilmente c'è il token)
- 401/422/400 = la rotta ESISTE (ci siamo quasi: è solo questione di campi)

Legge soltanto, non comanda nulla. Email e password non vengono salvate.
Solo libreria standard di Python: basta `python3 probe_login.py`.
"""

import getpass
import json
import os
import urllib.error
import urllib.request

BASE = "https://crmapp.celsiuspanel.it/api"

# Nomi di rotta più probabili per il login.
PATHS = [
    "/login",
    "/login-check",
    "/login_check",
    "/auth",
    "/auth/login",
    "/authentication_token",
    "/token",
    "/user/login",
    "/users/login",
    "/signin",
    "/sign-in",
    "/account/login",
]


def try_login(path: str, body: dict) -> tuple[int, str]:
    url = BASE + path
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, method="POST",
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except urllib.error.URLError as e:
        return -1, f"(rete) {e.reason}"


def main() -> None:
    email = os.environ.get("CELSIUS_EMAIL") or input("Email Celsius: ").strip()
    password = os.environ.get("CELSIUS_PASSWORD") or getpass.getpass("Password: ")

    # Tre modi di nominare i campi: proviamo prima il più probabile (email).
    bodies = {
        "email":       {"email": email, "password": password},
        "username":    {"username": email, "password": password},
        "_username":   {"_username": email, "_password": password},
    }

    print("\n===== PROVO LE ROTTE DI LOGIN =====")
    hits = []
    for path in PATHS:
        status, text = try_login(path, bodies["email"])
        flag = ""
        if status == 200:
            flag = "  ✅ FUNZIONA"
            hits.append((path, "email", status, text))
        elif status in (400, 401, 403, 422):
            flag = "  ⚠️ la rotta esiste (campi da sistemare)"
            hits.append((path, "email", status, text))
        print(f"{status:>4}  POST {path}{flag}")

    # Per le rotte che esistono ma hanno dato errore sui campi,
    # riproviamo con gli altri formati.
    for path, _, status, _ in [h for h in hits if h[2] != 200]:
        for name, body in (("username", bodies["username"]), ("_username", bodies["_username"])):
            s, t = try_login(path, body)
            if s == 200 or s in (400, 401, 403, 422):
                print(f"{s:>4}  POST {path}  (campi: {name})"
                      f"{'  ✅ FUNZIONA' if s == 200 else ''}")
                if s == 200:
                    hits.append((path, name, s, t))

    print("\n===== RISULTATO =====")
    winners = [h for h in hits if h[2] == 200]
    if winners:
        path, name, _, text = winners[0]
        print(f"Login giusto: POST {path}  con campi tipo '{name}'")
        print("\nRisposta del server (qui dentro c'è il token):")
        print(text[:2500])
    elif hits:
        print("Nessun login completato, ma queste rotte ESISTONO:")
        for path, name, status, text in hits:
            print(f"  {status} {path}  → {text[:200]}")
        print("\nIncolla questo in chat: ci siamo quasi.")
    else:
        print("Nessuna rotta ha risposto come login. Incolla tutto l'output qui sopra.")


if __name__ == "__main__":
    main()
