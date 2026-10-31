#!/usr/bin/env python3
"""Crea in Home Assistant una pagina "Riscaldamento" con tutti i pannelli
e i pulsantoni per comandarli tutti insieme.

La pagina contiene:
  - "Spegni tutti", "Tutti a 20°", "Tutti a 22°", "Tutti a 25°"
  - un termostato per ogni pannello

Non tocca la tua pagina "casa": crea una pagina nuova dedicata.

Serve il token di Home Assistant (come per assegna_stanze.py).
Uso:  python3 crea_scheda.py
"""

import sys

from ha_ws import connect

URL_PATH = "pannelli-casa"       # indirizzo interno della pagina
TITLE = "Riscaldamento"          # nome che appare nel menù a sinistra


def main() -> None:
    ws, call = connect()
    print("Collegato a Home Assistant ✓")

    entities = call({"type": "config/entity_registry/list"})
    climates = sorted(
        e["entity_id"] for e in entities
        if e.get("platform") == "celsius" and e["entity_id"].startswith("climate.")
    )
    if not climates:
        print("Non trovo i termostati Celsius. L'integrazione è installata?")
        return
    print(f"Trovati {len(climates)} termostati.")

    def button(name, icon, service, data=None):
        tap = {"action": "perform-action", "perform_action": service,
               "target": {"entity_id": climates}}
        if data:
            tap["data"] = data
        return {"type": "button", "name": name, "icon": icon,
                "show_state": False, "tap_action": tap}

    comandi = {
        "type": "horizontal-stack",
        "cards": [
            button("Spegni tutti", "mdi:radiator-off", "climate.turn_off"),
            button("Tutti 20°", "mdi:thermometer", "climate.set_temperature",
                   {"temperature": 20}),
            button("Tutti 22°", "mdi:thermometer", "climate.set_temperature",
                   {"temperature": 22}),
            button("Tutti 25°", "mdi:thermometer-high", "climate.set_temperature",
                   {"temperature": 25}),
        ],
    }
    termostati = {
        "type": "grid",
        "columns": 2,
        "square": False,
        "cards": [{"type": "thermostat", "entity": e} for e in climates],
    }
    config = {
        "title": TITLE,
        "views": [{
            "title": TITLE,
            "path": "riscaldamento",
            "icon": "mdi:radiator",
            "cards": [
                {"type": "markdown", "content": "## 🔥 Riscaldamento\n"
                 "Comanda tutti i pannelli con un tocco, o uno per uno qui sotto."},
                comandi,
                termostati,
            ],
        }],
    }

    # Crea la pagina (se c'è già, la riusa) e salva il contenuto.
    try:
        call({"type": "lovelace/dashboards/create", "url_path": URL_PATH,
              "title": TITLE, "mode": "storage", "show_in_sidebar": True,
              "icon": "mdi:radiator", "require_admin": False})
        print(f"+ creata pagina '{TITLE}'")
    except RuntimeError as e:
        print(f"(la pagina esiste già, la aggiorno) [{e}]")

    call({"type": "lovelace/config/save", "url_path": URL_PATH, "config": config})
    ws.close()
    print(f"\n✅ Fatto! Nel menù a sinistra di Home Assistant trovi "
          f"'{TITLE}'. Se non appare subito, ricarica la pagina (Cmd+R).")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Errore: {e}")
        sys.exit(1)
