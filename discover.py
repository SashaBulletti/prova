#!/usr/bin/env python3
"""Script per scoprire come rispondono i server Celsius.

Fa login col tuo account e stampa, in chiaro, cosa risponde ogni chiamata.
Serve a tarare il client sul comportamento reale, senza indovinare i campi.
NON manda comandi ai pannelli: legge soltanto.

Uso:
    pip install -r requirements.txt
    python discover.py

Email e password si inseriscono al momento (non vengono salvate).
In alternativa si possono passare con le variabili d'ambiente
CELSIUS_EMAIL e CELSIUS_PASSWORD.
"""

import getpass
import os

from celsius import CelsiusClient, CelsiusError


def main() -> None:
    email = os.environ.get("CELSIUS_EMAIL") or input("Email Celsius: ").strip()
    password = os.environ.get("CELSIUS_PASSWORD") or getpass.getpass("Password: ")

    client = CelsiusClient(verbose=True)

    print("\n===== LOGIN =====")
    try:
        client.login(email, password)
    except CelsiusError as e:
        print(f"\nLogin fallito: {e}")
        print("Se i campi del login sono diversi, lo vediamo qui sopra e li correggiamo.")
        return

    if not client.token:
        print("\nLogin passato ma non ho trovato il token nella risposta.")
        print("Guarda la risposta qui sopra: dimmi dov'è il token e lo aggancio.")
        return

    print(f"\nToken ottenuto ✓ (inizia con: {client.token[:12]}...)")

    for label, fn in (
        ("CASE (buildings)", client.get_buildings),
        ("PANNELLI (panels)", client.get_panels),
        ("MQTT SERVER", client.get_mqtt_server),
    ):
        print(f"\n===== {label} =====")
        try:
            fn()
        except CelsiusError as e:
            print(f"(non disponibile: {e})")


if __name__ == "__main__":
    main()
