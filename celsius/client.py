"""Client per parlare con i server Celsius Panel.

Primo obiettivo: fare login e leggere case/pannelli. I comandi sono già
mappati ma vanno confermati dal vivo. Ogni chiamata passa da _request(),
che in modalità verbose stampa richiesta e risposta grezze: così vediamo
i campi reali e correggiamo senza indovinare.
"""

from __future__ import annotations

import json
from typing import Any

import requests

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
        self._session = requests.Session()
        self._session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json",
            # L'app è Flutter; non filtra per User-Agent, ma lo teniamo neutro.
            "User-Agent": "CelsiusPanel/1.4.9 (custom-client)",
        })

    # -- infrastruttura -----------------------------------------------------
    def _request(self, method: str, path: str, *, json_body: Any = None,
                 params: dict | None = None, auth: bool = True) -> Any:
        url = self.base_url + path
        headers = {}
        if auth and self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        if self.verbose:
            print(f"\n→ {method} {url}")
            if params:
                print(f"  query: {params}")
            if json_body is not None:
                print(f"  body:  {json.dumps(json_body, ensure_ascii=False)}")

        resp = self._session.request(
            method, url, json=json_body, params=params,
            headers=headers, timeout=self.timeout,
        )

        if self.verbose:
            print(f"← {resp.status_code} {resp.reason}")
            print(f"  {resp.text[:2000]}")

        if resp.status_code >= 400:
            raise CelsiusError(f"{method} {path} → {resp.status_code}: {resp.text[:300]}")

        if not resp.text:
            return None
        try:
            return resp.json()
        except ValueError:
            return resp.text

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
