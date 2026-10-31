"""Mini client WebSocket per l'API di Home Assistant (solo libreria standard).

Usato dagli script di configurazione (assegna stanze, crea pagina).
"""

from __future__ import annotations

import base64
import getpass
import json
import os
import socket
import struct


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
        data = b""
        while b"\r\n\r\n" not in data:
            data += self.sock.recv(1024)
        if b" 101 " not in data.split(b"\r\n", 1)[0]:
            raise RuntimeError("Handshake WebSocket fallito.")
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
        header = bytearray([0x81])
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
        header += bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.sock.sendall(bytes(header))

    def recv(self) -> dict:
        b0, b1 = self._recv_exact(2)
        ln = b1 & 0x7F
        if ln == 126:
            ln = struct.unpack(">H", self._recv_exact(2))[0]
        elif ln == 127:
            ln = struct.unpack(">Q", self._recv_exact(8))[0]
        return json.loads(self._recv_exact(ln).decode())

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


def connect(host: str | None = None, port: int | None = None):
    """Si collega e autentica. Restituisce (ws, call) dove call(msg) invia
    un comando e aspetta il risultato."""
    host = host or os.environ.get("HA_HOST", "192.168.1.20")
    port = int(port or os.environ.get("HA_PORT", "8123"))
    token = os.environ.get("HA_TOKEN") or getpass.getpass(
        "Incolla il token di Home Assistant (non si vede mentre incolli): "
    ).strip()
    if not token:
        raise SystemExit("Nessun token.")

    ws = WS(host, port)
    if ws.recv().get("type") != "auth_required":
        raise RuntimeError("Risposta inattesa dal server.")
    ws.send({"type": "auth", "access_token": token})
    if ws.recv().get("type") != "auth_ok":
        raise SystemExit("Token non valido. Ricontrolla di averlo copiato tutto.")

    counter = [0]

    def call(msg: dict):
        counter[0] += 1
        msg["id"] = counter[0]
        ws.send(msg)
        while True:
            r = ws.recv()
            if r.get("id") == counter[0] and r.get("type") == "result":
                if not r.get("success", False):
                    raise RuntimeError(r.get("error"))
                return r.get("result")

    return ws, call
