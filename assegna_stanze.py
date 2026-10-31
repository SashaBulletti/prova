#!/usr/bin/env python3
"""Assegna automaticamente ogni pannello Celsius alla sua stanza in HA.

Si collega a Home Assistant (sullo Zima) e, per ogni pannello, crea la
stanza giusta se non esiste e ci mette dentro il dispositivo. Niente da
cliccare a mano.

Serve un "token di accesso a lunga durata" di Home Assistant:
  HA → in basso a sinistra clicca il tuo nome (sasha) → scheda "Sicurezza"
  → in fondo "Token di accesso a lunga durata" → Crea token → dagli un nome
  (es. "stanze") → COPIA la stringa lunga.

Uso:
  python3 assegna_stanze.py
(poi incolla il token quando lo chiede)

Solo libreria standard di Python.
"""

import base64
import getpass
import hashlib
import json
import os
import socket
import struct
import sys

HA_HOST = os.environ.get("HA_HOST", "192.168.1.20")
HA_PORT = int(os.environ.get("HA_PORT", "8123"))

# Regola nome-pannello -> stanza. Si usa la prima parola chiave che compare
# nel nome del pannello (minuscolo). "cabina armadio" prima di "camera".
RULES = [
    ("cabina armadio", "Cabina armadio"),
    ("cucina", "Cucina"),
    ("lavanderia", "Lavanderia"),
    ("disimpegno", "Disimpegno"),
    ("bagno", "Bagno"),
    ("camera", "Camera"),
    ("salotto", "Salotto"),
]


def area_for(name: str) -> str | None:
    low = name.lower()
    for key, area in RULES:
        if key in low:
            return area
    return None


# --- mini client WebSocket (solo quello che serve) ------------------------
class WS:
    def __init__(self, host: str, port: int) -> None:
        self.sock = socket.create_connection((host, port), timeout=15)
        key = base64.b64encode(os.urandom(16)).decode()
        req = (
            f"GET /api/websocket HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(req.encode())
        # leggi gli header della risposta fino a riga vuota
        data = b""
        while b"\r\n\r\n" not in data:
            data += self.sock.recv(1024)
        if b" 101 " not in data.split(b"\r\n", 1)[0]:
            raise RuntimeError("Handshake WebSocket fallito: " + data[:120].decode("replace"))
        self._buf = data.split(b"\r\n\r\n", 1)[1]

    def _recv_exact(self, n: int) -> bytes:
        while len(self._buf) < n:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise RuntimeError("Connessione chiusa dal server.")
            self._buf += chunk
        out, self._buf = self._buf[:n], self._buf[n:]
        return out

    def send(self, obj: dict) -> None:
        payload = json.dumps(obj).encode()
        header = bytearray([0x81])  # FIN + testo
        ln = len(payload)
        mask = os.urandom(4)
        if ln < 126:
            header.append(0x80 | ln)
        elif ln < 65536:
            header.append(0x80 | 126)
            header += struct.pack(">H", ln)
        else:
            header.append(0x80 | 127)
            header += struct.pack(">Q", ln)
        header += mask
        masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.sock.sendall(bytes(header) + masked)

    def recv(self) -> dict:
        b0, b1 = self._recv_exact(2)
        ln = b1 & 0x7F
        if ln == 126:
            ln = struct.unpack(">H", self._recv_exact(2))[0]
        elif ln == 127:
            ln = struct.unpack(">Q", self._recv_exact(8))[0]
        payload = self._recv_exact(ln)
        return json.loads(payload.decode())

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


def main() -> None:
    token = os.environ.get("HA_TOKEN") or getpass.getpass(
        "Incolla il token di Home Assistant (non si vede mentre incolli): "
    ).strip()
    if not token:
        print("Nessun token. Esco.")
        sys.exit(1)

    ws = WS(HA_HOST, HA_PORT)
    hello = ws.recv()
    if hello.get("type") != "auth_required":
        print("Risposta inattesa:", hello)
        sys.exit(1)
    ws.send({"type": "auth", "access_token": token})
    if ws.recv().get("type") != "auth_ok":
        print("Token non valido. Ricontrolla di averlo copiato tutto.")
        sys.exit(1)
    print("Collegato a Home Assistant ✓")

    _id = [0]
    def call(msg):
        _id[0] += 1
        msg["id"] = _id[0]
        ws.send(msg)
        while True:
            r = ws.recv()
            if r.get("id") == _id[0] and r.get("type") == "result":
                if not r.get("success", False):
                    raise RuntimeError(r.get("error"))
                return r.get("result")

    devices = call({"type": "config/device_registry/list"})
    areas = call({"type": "config/area_registry/list"})
    area_id = {a["name"].lower(): a["area_id"] for a in areas}

    # Solo i dispositivi dell'integrazione Celsius.
    celsius = [d for d in devices
               if any(idf[0] == "celsius" for idf in d.get("identifiers", []))]
    if not celsius:
        print("Non ho trovato pannelli Celsius. L'integrazione è installata?")
        return

    print(f"Trovati {len(celsius)} pannelli.\n")
    for d in celsius:
        name = d.get("name_by_user") or d.get("name") or ""
        area = area_for(name)
        if not area:
            print(f"  ? '{name}': non so in che stanza metterlo, lo salto.")
            continue
        # crea la stanza se non esiste
        if area.lower() not in area_id:
            res = call({"type": "config/area_registry/create", "name": area})
            area_id[area.lower()] = res["area_id"]
            print(f"  + creata stanza: {area}")
        # assegna
        call({"type": "config/device_registry/update",
              "device_id": d["id"], "area_id": area_id[area.lower()]})
        print(f"  ✓ '{name}' → {area}")

    ws.close()
    print("\n✅ Fatto! Apri la Panoramica di Home Assistant: i pannelli sono "
          "ora raggruppati per stanza.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Errore: {e}")
        sys.exit(1)
