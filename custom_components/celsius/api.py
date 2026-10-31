"""Client sincrono verso l'API Celsius Panel.

Autosufficiente (solo libreria standard), così il componente Home Assistant
non dipende da nulla di esterno. Le chiamate bloccanti vengono eseguite da
Home Assistant in un thread separato (executor).
"""

from __future__ import annotations

import base64
import json
import time
import urllib.error
import urllib.request

BASE_URL = "https://crmapp.celsiuspanel.it/api"
LOGIN_CHECK = "/login-check"

OPERATION_MODE = {0: "Spento", 1: "Manuale", 2: "Programmato"}


class CelsiusError(Exception):
    """Errore parlando con il server Celsius."""


class CelsiusAuthError(CelsiusError):
    """Credenziali rifiutate o token non valido."""


class Panel:
    def __init__(self, data: dict) -> None:
        self.raw = data
        self.uuid = data.get("uuid", "")
        self.name = (data.get("name") or "").strip()
        self.identifier = data.get("identifier", "")
        self.status = data.get("status", 0)
        self.operation_mode = data.get("operationMode", 0)
        self.set_temperature = _f(data.get("setTemperature"))
        self.min_temperature = _f(data.get("minTemperature"))
        self.max_temperature = _f(data.get("maxTemperature"))
        self.comfort_temperature = _f(data.get("comfortTemperature"))
        self.building_uuid = data.get("buildingUuid", "")
        m = data.get("lastMeasurement") or {}
        self.power = _f(m.get("power"))
        self.humidity = _f(str(m.get("humidity", "")).replace("%", ""))
        self.temp_int = _f(m.get("tempInt"))
        self.temp_ext = _f(m.get("tempExt"))

    @property
    def mode_label(self) -> str:
        return OPERATION_MODE.get(self.operation_mode, f"?{self.operation_mode}")

    @property
    def is_heating(self) -> bool:
        return bool(self.power and self.power > 0)


class CelsiusClient:
    def __init__(self, *, timeout: int = 20) -> None:
        self.base_url = BASE_URL
        self.timeout = timeout
        self.token: str | None = None

    def _request(self, method: str, path: str, *, body=None, auth: bool = True):
        url = self.base_url + path
        headers = {
            "Accept": "application/json+ld, application/json, */*",
            "User-Agent": "CelsiusPanel/1.4.9 (ha-integration)",
        }
        if auth and self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = ("application/json" if path == LOGIN_CHECK
                                       else "application/json+ld")
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                text = resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            text = e.read().decode("utf-8", "replace")
            if e.code in (401, 403):
                raise CelsiusAuthError(f"{method} {path} → {e.code}") from None
            raise CelsiusError(f"{method} {path} → {e.code}: {text[:200]}") from None
        except urllib.error.URLError as e:
            raise CelsiusError(f"{method} {path} → rete: {e.reason}") from None
        if not text:
            return None
        try:
            return json.loads(text)
        except ValueError:
            return text

    # -- login --
    def login(self, email: str, password: str) -> str:
        data = self._request("POST", LOGIN_CHECK,
                              body={"username": email, "password": password},
                              auth=False)
        token = data.get("token") if isinstance(data, dict) else None
        if not token:
            raise CelsiusAuthError("Nessun token nella risposta di login.")
        self.token = token
        return token

    def token_valid(self) -> bool:
        if not self.token:
            return False
        exp = _jwt_exp(self.token)
        return bool(exp and exp > time.time() + 60)

    # -- lettura --
    def get_buildings(self) -> list[dict]:
        return _as_list(self._request("GET", "/buildings"))

    def get_all_panels(self) -> list[Panel]:
        panels: list[Panel] = []
        for b in self.get_buildings():
            data = self._request("GET", f"/buildings/{b['uuid']}/panels")
            for item in _as_list(data):
                for p in item.get("panels", []):
                    panels.append(Panel(p))
        return panels

    # -- comandi --
    def turn_on(self, uuid: str, temperature: float):
        return self._request("POST", f"/panels/{uuid}/mode-manual-on",
                              body={"setTemperature": _temp_str(temperature)})

    def turn_off(self, uuid: str):
        return self._request("POST", f"/panels/{uuid}/mode-manual-off", body={})

    def set_scheduled(self, uuid: str):
        return self._request("POST", f"/panels/{uuid}/mode-scheduled", body={})

    def set_temperatures(self, uuid: str, *, comfort=None, antifreeze=None,
                         maximum=None, name=None):
        body = {}
        if name is not None:
            body["name"] = name
        if antifreeze is not None:
            body["minTemperature"] = _temp_str(antifreeze)
        if maximum is not None:
            body["maxTemperature"] = _temp_str(maximum)
        if comfort is not None:
            body["comfortTemperature"] = _temp_str(comfort)
        return self._request("POST", f"/panels/{uuid}/update", body=body)

    def restart(self, uuid: str):
        return self._request("POST", f"/panels/{uuid}/restart", body={})


def _f(v):
    if v is None or v == "":
        return None
    try:
        return float(str(v).replace(",", "."))
    except ValueError:
        return None


def _temp_str(v: float) -> str:
    return str(int(v)) if float(v).is_integer() else str(v)


def _as_list(data):
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return data.get("hydra:member", [data])
    return []


def _jwt_exp(token: str):
    try:
        payload = token.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        return int(json.loads(base64.urlsafe_b64decode(payload)).get("exp"))
    except Exception:
        return None
