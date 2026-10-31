"""Sensori extra per ogni pannello: consumo, umidità, temperatura esterna.

Il sensore di consumo (W) serve anche per le automazioni di taglio carichi
(es. spegnere pannelli quando si mette in carica l'auto)."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from homeassistant.components.sensor import (
    SensorDeviceClass,
    SensorEntity,
    SensorEntityDescription,
    SensorStateClass,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import (
    PERCENTAGE,
    UnitOfPower,
    UnitOfTemperature,
)
from homeassistant.core import HomeAssistant
from homeassistant.helpers.device_registry import DeviceInfo
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .api import Panel
from .const import DOMAIN
from .coordinator import CelsiusCoordinator


@dataclass(frozen=True, kw_only=True)
class CelsiusSensorDescription(SensorEntityDescription):
    value_fn: Callable[[Panel], float | None]


SENSORS: tuple[CelsiusSensorDescription, ...] = (
    CelsiusSensorDescription(
        key="power",
        translation_key="power",
        device_class=SensorDeviceClass.POWER,
        native_unit_of_measurement=UnitOfPower.WATT,
        state_class=SensorStateClass.MEASUREMENT,
        value_fn=lambda p: p.power,
    ),
    CelsiusSensorDescription(
        key="humidity",
        translation_key="humidity",
        device_class=SensorDeviceClass.HUMIDITY,
        native_unit_of_measurement=PERCENTAGE,
        state_class=SensorStateClass.MEASUREMENT,
        value_fn=lambda p: p.humidity,
    ),
    CelsiusSensorDescription(
        key="temp_ext",
        translation_key="temp_ext",
        device_class=SensorDeviceClass.TEMPERATURE,
        native_unit_of_measurement=UnitOfTemperature.CELSIUS,
        state_class=SensorStateClass.MEASUREMENT,
        value_fn=lambda p: p.temp_ext,
    ),
)


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    coordinator: CelsiusCoordinator = hass.data[DOMAIN][entry.entry_id]
    entities = [
        CelsiusSensor(coordinator, uuid, desc)
        for uuid in coordinator.data
        for desc in SENSORS
    ]
    async_add_entities(entities)


class CelsiusSensor(CoordinatorEntity[CelsiusCoordinator], SensorEntity):
    _attr_has_entity_name = True
    entity_description: CelsiusSensorDescription

    def __init__(
        self,
        coordinator: CelsiusCoordinator,
        uuid: str,
        description: CelsiusSensorDescription,
    ) -> None:
        super().__init__(coordinator)
        self._uuid = uuid
        self.entity_description = description
        self._attr_unique_id = f"{uuid}_{description.key}"

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
    def native_value(self):
        if not self.panel:
            return None
        return self.entity_description.value_fn(self.panel)
