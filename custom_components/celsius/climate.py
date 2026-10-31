"""Ogni pannello Celsius diventa un termostato in Home Assistant."""

from __future__ import annotations

from homeassistant.components.climate import (
    ClimateEntity,
    ClimateEntityFeature,
    HVACAction,
    HVACMode,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import ATTR_TEMPERATURE, UnitOfTemperature
from homeassistant.core import HomeAssistant, callback
from homeassistant.helpers.device_registry import DeviceInfo
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .api import Panel
from .const import DOMAIN
from .coordinator import CelsiusCoordinator

# operationMode del pannello  ->  modalità Home Assistant
MODE_TO_HVAC = {0: HVACMode.OFF, 1: HVACMode.HEAT, 2: HVACMode.AUTO}


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    coordinator: CelsiusCoordinator = hass.data[DOMAIN][entry.entry_id]
    async_add_entities(
        CelsiusClimate(coordinator, uuid) for uuid in coordinator.data
    )


class CelsiusClimate(CoordinatorEntity[CelsiusCoordinator], ClimateEntity):
    _attr_has_entity_name = True
    _attr_name = None  # il nome è quello del dispositivo (il pannello)
    _attr_temperature_unit = UnitOfTemperature.CELSIUS
    _attr_hvac_modes = [HVACMode.OFF, HVACMode.HEAT, HVACMode.AUTO]
    _attr_supported_features = (
        ClimateEntityFeature.TARGET_TEMPERATURE
        | ClimateEntityFeature.TURN_ON
        | ClimateEntityFeature.TURN_OFF
    )
    _attr_min_temp = 8
    _attr_max_temp = 30.5
    _attr_target_temperature_step = 0.5

    def __init__(self, coordinator: CelsiusCoordinator, uuid: str) -> None:
        super().__init__(coordinator)
        self._uuid = uuid
        self._attr_unique_id = uuid

    @property
    def panel(self) -> Panel | None:
        return self.coordinator.data.get(self._uuid)

    @property
    def available(self) -> bool:
        return super().available and self.panel is not None

    @property
    def device_info(self) -> DeviceInfo:
        p = self.panel
        return DeviceInfo(
            identifiers={(DOMAIN, self._uuid)},
            name=(p.name if p else self._uuid),
            manufacturer="Celsius Panel (Tesi Group)",
            model="Pannello infrarossi",
        )

    @property
    def current_temperature(self):
        return self.panel.temp_int if self.panel else None

    @property
    def current_humidity(self):
        return self.panel.humidity if self.panel else None

    @property
    def target_temperature(self):
        return self.panel.set_temperature if self.panel else None

    @property
    def hvac_mode(self):
        if not self.panel:
            return None
        return MODE_TO_HVAC.get(self.panel.operation_mode, HVACMode.OFF)

    @property
    def hvac_action(self):
        if not self.panel:
            return None
        if self.panel.operation_mode == 0:
            return HVACAction.OFF
        return HVACAction.HEATING if self.panel.is_heating else HVACAction.IDLE

    async def async_set_temperature(self, **kwargs) -> None:
        temp = kwargs.get(ATTR_TEMPERATURE)
        if temp is None:
            return
        # Impostare una temperatura accende il pannello in manuale.
        await self.coordinator.async_command(
            self.coordinator.client.turn_on, self._uuid, temp
        )

    async def async_set_hvac_mode(self, hvac_mode: HVACMode) -> None:
        client = self.coordinator.client
        if hvac_mode == HVACMode.OFF:
            await self.coordinator.async_command(client.turn_off, self._uuid)
        elif hvac_mode == HVACMode.AUTO:
            await self.coordinator.async_command(client.set_scheduled, self._uuid)
        elif hvac_mode == HVACMode.HEAT:
            p = self.panel
            temp = (p.set_temperature or p.comfort_temperature or 20) if p else 20
            await self.coordinator.async_command(client.turn_on, self._uuid, temp)

    async def async_turn_off(self) -> None:
        await self.coordinator.async_command(
            self.coordinator.client.turn_off, self._uuid
        )

    async def async_turn_on(self) -> None:
        await self.async_set_hvac_mode(HVACMode.HEAT)
