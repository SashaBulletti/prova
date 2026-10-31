"""Indirizzi ed endpoint dell'API Celsius Panel (confermati dal vivo).

Backend: API Platform (Symfony), formato JSON-LD/Hydra.
Login ricavato e verificato con l'account reale. Tutti gli endpoint qui
sotto sono stati letti dal "manuale automatico" OpenAPI dell'API.
"""

# Server REST dell'app (produzione), con prefisso /api.
BASE_URL = "https://crmapp.celsiuspanel.it/api"

# Grafici/statistiche (consumi storici). Dominio separato.
GRAPH_URL = "https://graph.celsiuspanel.it"

# Broker MQTT su AWS IoT Core (dati in tempo reale "push", opzionale).
# L'indirizzo esatto lo restituisce l'endpoint MQTT_SERVER.
MQTT_HOST_PROD = "a3mrfdlotu8zoh-ats.iot.eu-west-1.amazonaws.com"

# Configurazione in rete locale: il pannello in hotspot "CELSIUS_PANEL"
# risponde su questo IP. Dentro c'è un ESP32 (MAC Espressif confermato).
PANEL_AP_IP = "192.168.4.1"
PANEL_AP_SSID = "CELSIUS_PANEL"

# --- Autenticazione --------------------------------------------------------
LOGIN_CHECK = "/login-check"              # POST {username, password} -> {token}

# --- Case (building) -------------------------------------------------------
BUILDINGS = "/buildings"                  # GET lista
def building(uuid): return f"/buildings/{uuid}"            # GET dettaglio
def building_panels(uuid): return f"/buildings/{uuid}/panels"   # GET pannelli+dati
def building_set_scheduling(uuid): return f"/buildings/{uuid}/set-scheduling"
def building_settings_update(uuid): return f"/buildings/{uuid}/settings-update"

# --- Pannelli --------------------------------------------------------------
def panel(uuid): return f"/panels/{uuid}"                  # GET dettaglio + dati live
def panel_manual_on(uuid): return f"/panels/{uuid}/mode-manual-on"    # {setTemperature}
def panel_manual_off(uuid): return f"/panels/{uuid}/mode-manual-off"  # {}
def panel_scheduled(uuid): return f"/panels/{uuid}/mode-scheduled"    # {}
def panel_set_tmax(uuid): return f"/panels/{uuid}/mode-set-tmax"
def panel_update(uuid): return f"/panels/{uuid}/update"    # {name,min,max,comfort}
def panel_set_scheduling(uuid): return f"/panels/{uuid}/set-scheduling"
def panel_scheduling_from_building(uuid): return f"/panels/{uuid}/scheduling-from-building"
def panel_restart(uuid): return f"/panels/{uuid}/restart"
def panel_firmware_upgrade(uuid): return f"/panels/{uuid}/firmwareupgrade"

# --- Pubblici / vari -------------------------------------------------------
MQTT_SERVER = "/public/mqtt-server"       # POST {host} -> dati broker MQTT
APP_VERSION = "/public/app-version"

# --- Significato dei codici ------------------------------------------------
# operationMode nel pannello:
OPERATION_MODE = {0: "Spento", 1: "Manuale", 2: "Programmato"}
# status: 1 = sta riscaldando / attivo, 0 = fermo (da confermare).
# Le temperature viaggiano come stringhe ("20", "30.5", "8").
# scheduling: per ogni giorno (1=lun ... 7=dom) 24 valori orari in DECIMI
# di grado (200 = 20.0 °C).
