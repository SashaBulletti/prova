#!/usr/bin/env python3
"""Comando semplice per gestire i pannelli Celsius dal computer.

Esempi:
  python3 celsius_cli.py list                 # mostra tutti i pannelli
  python3 celsius_cli.py on cucina 21          # accendi "cucina" a 21°
  python3 celsius_cli.py off bagno             # spegni "bagno"
  python3 celsius_cli.py auto salotto          # metti "salotto" in programmato
  python3 celsius_cli.py all-off               # spegni TUTTI i pannelli
  python3 celsius_cli.py all-on 20             # accendi TUTTI a 20°
  python3 celsius_cli.py comfort camera 19     # imposta comfort "camera" a 19°

Il pannello si indica col numero (quello di "list") o con una parola del
nome (es. "cucina"). La prima volta chiede email e password; poi tiene il
token salvato in .token e non li richiede più finché è valido.

Solo libreria standard: nessuna installazione.
"""

import getpass
import json
import os
import sys
import time

from celsius import CelsiusClient, CelsiusError, Panel

TOKEN_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".token")


# --- login con token salvato ----------------------------------------------
def get_client() -> CelsiusClient:
    client = CelsiusClient()

    # Prova a riusare un token salvato ancora valido.
    try:
        with open(TOKEN_FILE) as f:
            saved = json.load(f)
        token = saved.get("token")
        if token:
            client.set_token(token)
            exp = client.token_expiry()
            if exp and exp > time.time() + 60:
                return client
    except (FileNotFoundError, ValueError):
        pass

    # Serve un login.
    print("Primo accesso (o token scaduto): accedi al tuo account Celsius.")
    email = os.environ.get("CELSIUS_EMAIL") or input("Email: ").strip()
    password = os.environ.get("CELSIUS_PASSWORD") or getpass.getpass("Password: ")
    client.login(email, password)
    try:
        with open(TOKEN_FILE, "w") as f:
            json.dump({"token": client.token}, f)
        os.chmod(TOKEN_FILE, 0o600)
    except OSError:
        pass
    print("Accesso riuscito ✓\n")
    return client


# --- trovare un pannello per numero o nome --------------------------------
def pick_panel(panels: list[Panel], needle: str) -> Panel:
    if needle.isdigit():
        i = int(needle) - 1
        if 0 <= i < len(panels):
            return panels[i]
        raise SystemExit(f"Non esiste il pannello numero {needle}.")
    matches = [p for p in panels if needle.lower() in p.name.lower()]
    if not matches:
        raise SystemExit(f"Nessun pannello con '{needle}' nel nome. "
                         f"Usa 'list' per vedere i nomi.")
    if len(matches) > 1:
        nomi = ", ".join(f"{p.name!r}" for p in matches)
        raise SystemExit(f"'{needle}' corrisponde a più pannelli: {nomi}. "
                         f"Sii più preciso o usa il numero.")
    return matches[0]


def fmt(v, suffix=""):
    return f"{v:g}{suffix}" if v is not None else "—"


def cmd_list(client: CelsiusClient, panels: list[Panel]) -> None:
    print(f"{'#':>2}  {'PANNELLO':<28} {'MODO':<12} {'INT':>6} {'IMP':>6} "
          f"{'UM':>5} {'CONS':>7}")
    print("-" * 74)
    for i, p in enumerate(panels, 1):
        heat = " 🔥" if p.is_heating else ""
        print(f"{i:>2}  {p.name[:28]:<28} {p.mode_label:<12} "
              f"{fmt(p.temp_int,'°'):>6} {fmt(p.set_temperature,'°'):>6} "
              f"{fmt(p.humidity,'%'):>5} {fmt(p.power,'W'):>7}{heat}")


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return

    cmd = args[0].lower()
    client = get_client()
    panels = client.get_all_panels()

    if cmd in ("list", "lista", "ls"):
        cmd_list(client, panels)

    elif cmd in ("on", "accendi"):
        p = pick_panel(panels, args[1])
        temp = float(args[2])
        client.turn_on(p.uuid, temp)
        print(f"✓ '{p.name}' acceso a {temp:g}°.")

    elif cmd in ("off", "spegni"):
        p = pick_panel(panels, args[1])
        client.turn_off(p.uuid)
        print(f"✓ '{p.name}' spento.")

    elif cmd in ("auto", "programmato"):
        p = pick_panel(panels, args[1])
        client.set_scheduled(p.uuid)
        print(f"✓ '{p.name}' in modalità programmata.")

    elif cmd in ("comfort",):
        p = pick_panel(panels, args[1])
        temp = float(args[2])
        client.set_temperatures(p.uuid, comfort=temp)
        print(f"✓ Comfort di '{p.name}' impostato a {temp:g}°.")

    elif cmd == "all-off":
        for p in panels:
            client.turn_off(p.uuid)
            print(f"  spento: {p.name}")
        print(f"✓ Spenti tutti ({len(panels)}).")

    elif cmd == "all-on":
        temp = float(args[1])
        for p in panels:
            client.turn_on(p.uuid, temp)
            print(f"  acceso a {temp:g}°: {p.name}")
        print(f"✓ Accesi tutti a {temp:g}° ({len(panels)}).")

    else:
        print(f"Comando sconosciuto: {cmd}")
        print(__doc__)


if __name__ == "__main__":
    try:
        main()
    except CelsiusError as e:
        print(f"Errore: {e}")
        sys.exit(1)
