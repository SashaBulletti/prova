#!/usr/bin/env python3
"""Aggiunge un riquadro "Riscaldamento" alla tua dashboard "casa".

Mette in cima alla pagina "casa" un riquadro con i pulsanti
(Spegni tutti / Tutti 20-22-25°) e l'elenco dei pannelli (toccabili per
aprire il termostato). Prima di modificare, salva una copia di sicurezza
della dashboard in un file locale, così si può sempre tornare indietro.

Serve il token di Home Assistant.
Uso:  python3 aggiungi_a_casa.py
"""

import json
import sys
import time

from ha_ws import connect

# Indirizzo interno della dashboard "casa" (dalla barra: /dashboard-casa/casa)
DASHBOARD = "dashboard-casa"


def main() -> None:
    ws, call = connect()
    print("Collegato a Home Assistant ✓")

    # Termostati Celsius.
    entities = call({"type": "config/entity_registry/list"})
    climates = sorted(
        e["entity_id"] for e in entities
        if e.get("platform") == "celsius" and e["entity_id"].startswith("climate.")
    )
    if not climates:
        print("Non trovo i termostati Celsius.")
        return

    # Scarica la configurazione attuale della dashboard "casa".
    try:
        cfg = call({"type": "lovelace/config", "url_path": DASHBOARD, "force": False})
    except RuntimeError as e:
        print(f"Non riesco a leggere la dashboard '{DASHBOARD}': {e}")
        print("Forse l'indirizzo è diverso. Dimmi cosa c'è nella barra quando "
              "apri la tua pagina 'casa' (es. /dashboard-xxx/...).")
        return

    # Copia di sicurezza su file locale.
    backup = f"casa_backup_{int(time.time())}.json"
    with open(backup, "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
    print(f"Copia di sicurezza salvata in: {backup}")

    def button(name, icon, service, data=None):
        tap = {"action": "perform-action", "perform_action": service,
               "target": {"entity_id": climates}}
        if data:
            tap["data"] = data
        return {"type": "button", "name": name, "icon": icon,
                "show_state": False, "tap_action": tap}

    card = {
        "type": "vertical-stack",
        "cards": [
            {"type": "markdown", "content": "## 🔥 Riscaldamento"},
            {"type": "horizontal-stack", "cards": [
                button("Spegni tutti", "mdi:radiator-off", "climate.turn_off"),
                button("Tutti 20°", "mdi:thermometer", "climate.set_temperature",
                       {"temperature": 20}),
                button("Tutti 22°", "mdi:thermometer", "climate.set_temperature",
                       {"temperature": 22}),
                button("Tutti 25°", "mdi:thermometer-high",
                       "climate.set_temperature", {"temperature": 25}),
            ]},
            {"type": "entities", "entities": [{"entity": e} for e in climates]},
        ],
    }

    # Mette il riquadro in cima alla prima pagina della dashboard.
    views = cfg.get("views") or [{"cards": []}]
    views[0].setdefault("cards", [])
    views[0]["cards"].insert(0, card)
    cfg["views"] = views

    call({"type": "lovelace/config/save", "url_path": DASHBOARD, "config": cfg})
    ws.close()
    print("\n✅ Fatto! Ricarica Home Assistant (Cmd+R) e apri la tua pagina "
          "'casa': il riquadro Riscaldamento è in alto. In modalità modifica "
          "(matita) puoi trascinarlo dove preferisci.")
    print(f"   Se qualcosa non va, la copia di sicurezza è in {backup}.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Errore: {e}")
        sys.exit(1)
