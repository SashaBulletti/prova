"""Client per parlare con i server Celsius Panel.

Primo obiettivo: fare login e leggere case/pannelli. I comandi sono già
mappati ma vanno confermati dal vivo. Ogni chiamata passa da _request(),
che in modalità verbose stampa richiesta e risposta grezze: così vediamo
i campi reali e correggiamo senza indovinare.

Usa solo la libreria standard di Python (urllib): nessun pip, nessuna
installazione. Basta Python 3 (già presente sul Mac come `python3`).
"""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

from . import const


class CelsiusError(Exception):
    """Errore parlando col server Celsius."""


class CelsiusClient:
    def __init__(self, base_url: str = const.BASE_URL, *, verbose: bool = False,
                 timeout: int = 20) -> None:
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose
        self.timeout = timeout
        self.token: str | None = None

    # -- infrastruttura -----------------------------------------------------
    def _request(self, method: str, path: str, *, json_body: Any = None,
                 params: dict | None = None, auth: bool = True) -> Any:
        url = self.base_url + path
        if params:
            query = urllib.parse.urlencode(params)
            url = f"{url}?{query}"

        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
        }
        if auth and self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        data = None
        if json_body is not None:
            data = json.dumps(json_body).encode("utf-8")

        if self.verbose:
            print(f"\n→ {method} {url}")
            if json_body is not None:
                print(f"  body:  {json.dumps(json_body, ensure_ascii=False)}")

        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                status = resp.status
                reason = resp.reason
                body = resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            # Il server ha risposto con un errore: leggiamo comunque il corpo,
            # perché spesso spiega cosa manca (es. campi del login sbagliati).
            status = e.code
            reason = e.reason
            body = e.read().decode("utf-8", "replace")
            if self.verbose:
                print(f"← {status} {reason}")
                print(f"  {body[:2000]}")
            raise CelsiusError(f"{method} {path} → {status}: {body[:300]}") from None
        except urllib.error.URLError as e:
            raise CelsiusError(f"{method} {path} → rete non raggiungibile: {e.reason}") from None

        if self.verbose:
            print(f"← {status} {reason}")
            print(f"  {body[:2000]}")

        if not body:
            return None
        try:
            return json.loads(body)
        except ValueError:
            return body

    # -- autenticazione -----------------------------------------------------
    def login(self, email: str, password: str) -> Any:
        """Prova il login. I nomi dei campi ('email'/'password') sono
        un'ipotesi ragionevole: con verbose=True vediamo subito se il
        server li accetta o chiede altro.
        """
        data = self._request(
            "POST", const.LOGIN,
            json_body={"email": email, "password": password},
            auth=False,
        )
        token = self._extract_token(data)
        if token:
            self.token = token
        return data

    @staticmethod
    def _extract_token(data: Any) -> str | None:
        if not isinstance(data, dict):
            return None
        # Il token può stare in posti diversi; proviamo i nomi più comuni.
        for key in ("token", "accessToken", "access_token", "jwt"):
            if key in data and isinstance(data[key], str):
                return data[key]
        # A volte è annidato dentro "data" o "user".
        for outer in ("data", "user", "result"):
            inner = data.get(outer)
            if isinstance(inner, dict):
                t = CelsiusClient._extract_token(inner)
                if t:
                    return t
        return None

    # -- lettura ------------------------------------------------------------
    def get_buildings(self) -> Any:
        return self._request("GET", const.BUILDINGS)

    def get_panels(self) -> Any:
        return self._request("GET", const.PANELS)

    def get_panel_settings(self, panel_id: str) -> Any:
        return self._request("GET", const.PANEL_SETTINGS, params={"panelId": panel_id})

    def get_mqtt_server(self) -> Any:
        """Credenziali per collegarsi al broker MQTT (dati in tempo reale)."""
        return self._request("GET", const.MQTT_SERVER)

    # -- comandi (DA CONFERMARE prima di usarli sul serio) ------------------
    def turn_on(self, panel_id: str) -> Any:
        return self._request("POST", const.MODE_MANUAL_ON, json_body={"panelId": panel_id})

    def turn_off(self, panel_id: str) -> Any:
        return self._request("POST", const.MODE_MANUAL_OFF, json_body={"panelId": panel_id})

    def set_scheduled(self, panel_id: str) -> Any:
        return self._request("POST", const.MODE_SCHEDULED, json_body={"panelId": panel_id})
