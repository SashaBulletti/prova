"""Coordinatore: tiene il login e rilegge i pannelli a intervalli regolari."""

from __future__ import annotations

import logging
from datetime import timedelta

from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed

from .api import CelsiusAuthError, CelsiusClient, CelsiusError, Panel
from .const import CONF_EMAIL, CONF_PASSWORD, DEFAULT_SCAN_INTERVAL, DOMAIN

_LOGGER = logging.getLogger(__name__)


class CelsiusCoordinator(DataUpdateCoordinator[dict[str, Panel]]):
    """Legge periodicamente lo stato di tutti i pannelli."""

    def __init__(self, hass: HomeAssistant, entry: ConfigEntry) -> None:
        super().__init__(
            hass,
            _LOGGER,
            name=DOMAIN,
            update_interval=timedelta(seconds=DEFAULT_SCAN_INTERVAL),
        )
        self.entry = entry
        self.client = CelsiusClient()
        self._email = entry.data[CONF_EMAIL]
        self._password = entry.data[CONF_PASSWORD]

    async def _ensure_login(self) -> None:
        if not self.client.token_valid():
            await self.hass.async_add_executor_job(
                self.client.login, self._email, self._password
            )

    async def _async_update_data(self) -> dict[str, Panel]:
        try:
            await self._ensure_login()
            panels = await self.hass.async_add_executor_job(
                self.client.get_all_panels
            )
        except CelsiusAuthError:
            # Token scaduto o credenziali cambiate: riprova un login pulito.
            try:
                self.client.token = None
                await self._ensure_login()
                panels = await self.hass.async_add_executor_job(
                    self.client.get_all_panels
                )
            except CelsiusError as err:
                raise UpdateFailed(f"Autenticazione Celsius fallita: {err}") from err
        except CelsiusError as err:
            raise UpdateFailed(f"Errore leggendo i pannelli: {err}") from err
        return {p.uuid: p for p in panels}

    # Comandi usati dalle entità: eseguono e poi rinfrescano i dati.
    async def async_command(self, func, *args) -> None:
        await self._ensure_login()
        await self.hass.async_add_executor_job(func, *args)
        await self.async_request_refresh()
