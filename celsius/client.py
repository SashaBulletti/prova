"""Client per i pannelli Celsius Panel.

Parla con l'API ufficiale (API Platform / JSON-LD). Permette di leggere i
pannelli e i loro dati in tempo reale (temperatura, umidità, consumo) e di
comandarli (accendi/spegni/programmato, temperature).

Solo libreria standard di Python (urllib): nessun pip.
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

from . import const


class CelsiusError(Exception):
    """Errore parlando con il server Celsius."""


class Panel:
    """Un pannello, con i suoi dati letti dall'API."""

    def __init__(self, data: dict) -> None:
        self.raw = data
        self.uuid: str = data.get("uuid", "")
        self.name: str = (data.get("name") or "").strip()
        self.identifier: str = data.get("identifier", "")  # MAC
        self.status: int = data.get("status", 0)
        self.operation_mode: int = data.get("operationMode", 0)
        self.set_temperature = _to_float(data.get("setTemperature"))
        self.min_temperature = _to_float(data.get("minTemperature"))   # antigelo
        self.max_temperature = _to_float(data.get("maxTemperature"))
        self.comfort_temperature = _to_float(data.get("comfortTemperature"))
        m = data.get("lastMeasurement") or {}
        self.power = _to_float(m.get("power"))                 # Watt
        self.humidity = _to_float(str(m.get("humidity", "")).replace("%", ""))
        self.temp_int = _to_float(m.get("tempInt"))            # °C interna
        self.temp_ext = _to_float(m.get("tempExt"))            # °C esterna

    @property
    def mode_label(self) -> str:
        return const.OPERATION_MODE.get(self.operation_mode, f"?{self.operation_mode}")

    @property
    def is_heating(self) -> bool:
        return bool(self.power and self.power > 0)

    def __repr__(self) -> str:
        return f"<Panel {self.name!r} {self.mode_label} int={self.temp_int} W={self.power}>"


class CelsiusClient:
    def __init__(self, base_url: str = const.BASE_URL, *, timeout: int = 20) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.token: str | None = None

    # -- rete ---------------------------------------------------------------
    def _request(self, method: str, path: str, *, body: Any = None,
                 auth: bool = True) -> Any:
        url = self.base_url + path
        headers = {
            # */* fa sì che il server risponda sempre in JSON-LD (che è
            # l'unico formato che accetta su alcuni endpoint).
            "Accept": "application/json+ld, application/json, */*",
            "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
        }
        if auth and self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            # Il login vuole application/json; gli altri vogliono il formato
            # (non standard) 'application/json+ld' usato da questo server.
            headers["Content-Type"] = ("application/json" if path == const.LOGIN_CHECK
                                       else "application/json+ld")

        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                text = resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            text = e.read().decode("utf-8", "replace")
            raise CelsiusError(f"{method} {path} → {e.code}: {text[:300]}") from None
        except urllib.error.URLError as e:
            raise CelsiusError(f"{method} {path} → rete: {e.reason}") from None

        if not text:
            return None
        try:
            return json.loads(text)
        except ValueError:
            return text

    # -- login --------------------------------------------------------------
    def login(self, email: str, password: str) -> str:
        data = self._request("POST", const.LOGIN_CHECK,
                              body={"username": email, "password": password},
                              auth=False)
        token = data.get("token") if isinstance(data, dict) else None
        if not token:
            raise CelsiusError("Login riuscito ma nessun token nella risposta.")
        self.token = token
        return token

    def set_token(self, token: str) -> None:
        self.token = token

    def token_expiry(self) -> int | None:
        """Scadenza del token (timestamp epoch), leggendola dal JWT."""
        return _jwt_exp(self.token) if self.token else None

    # -- lettura ------------------------------------------------------------
    def get_buildings(self) -> list[dict]:
        data = self._request("GET", const.BUILDINGS)
        return _as_list(data)

    def get_panels(self, building_uuid: str) -> list[Panel]:
        """Tutti i pannelli di una casa, con i dati in tempo reale."""
        data = self._request("GET", const.building_panels(building_uuid))
        panels = []
        for b in _as_list(data):
            for p in b.get("panels", []):
                panels.append(Panel(p))
        return panels

    def get_all_panels(self) -> list[Panel]:
        """Tutti i pannelli di tutte le case."""
        panels = []
        for b in self.get_buildings():
            panels.extend(self.get_panels(b["uuid"]))
        return panels

    def get_panel(self, uuid: str) -> Panel:
        return Panel(self._request("GET", const.panel(uuid)))

    # -- comandi ------------------------------------------------------------
    def turn_on(self, uuid: str, temperature: float) -> Any:
        """Accende in modalità MANUALE alla temperatura indicata."""
        return self._request("POST", const.panel_manual_on(uuid),
                              body={"setTemperature": _temp_str(temperature)})

    def turn_off(self, uuid: str) -> Any:
        return self._request("POST", const.panel_manual_off(uuid), body={})

    def set_scheduled(self, uuid: str) -> Any:
        """Mette il pannello in modalità PROGRAMMATA (segue il calendario)."""
        return self._request("POST", const.panel_scheduled(uuid), body={})

    def set_temperatures(self, uuid: str, *, comfort: float | None = None,
                         antifreeze: float | None = None,
                         maximum: float | None = None,
                         name: str | None = None) -> Any:
        """Imposta temperatura comfort, antigelo (min) e massima."""
        body: dict[str, str] = {}
        if name is not None:
            body["name"] = name
        if antifreeze is not None:
            body["minTemperature"] = _temp_str(antifreeze)
        if maximum is not None:
            body["maxTemperature"] = _temp_str(maximum)
        if comfort is not None:
            body["comfortTemperature"] = _temp_str(comfort)
        return self._request("POST", const.panel_update(uuid), body=body)

    def restart(self, uuid: str) -> Any:
        return self._request("POST", const.panel_restart(uuid), body={})


# --- funzioni di supporto --------------------------------------------------
def _to_float(v: Any) -> float | None:
    if v is None or v == "":
        return None
    try:
        return float(str(v).replace(",", "."))
    except ValueError:
        return None


def _temp_str(v: float) -> str:
    """Le temperature viaggiano come stringa: '20' o '20.5' (niente '.0')."""
    if float(v).is_integer():
        return str(int(v))
    return str(v)


def _as_list(data: Any) -> list[dict]:
    """Normalizza: l'API a volte risponde con una lista semplice, a volte
    con una collezione Hydra {"hydra:member": [...]}."""
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        if "hydra:member" in data:
            return data["hydra:member"]
        return [data]
    return []


def _jwt_exp(token: str) -> int | None:
    try:
        payload = token.split(".")[1]
        payload += "=" * (-len(payload) % 4)  # padding base64
        import base64
        data = json.loads(base64.urlsafe_b64decode(payload))
        return int(data.get("exp"))
    except Exception:
        return None
