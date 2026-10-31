"""Indirizzi e endpoint ricavati dall'app ufficiale "Celsius Panel" v1.4.9.

Tutto quello che c'è qui è stato letto dall'app (Flutter, pacchetto
it.celsiuspanel.celsius). I NOMI degli endpoint sono certi; il CONTENUTO
esatto delle richieste va confermato dal vivo col primo login.
"""

# Server REST principale (produzione). L'app usa il prefisso /api:
# la pagina web del gestionale sta sulla radice, l'API dell'app sotto /api.
BASE_URL = "https://crmapp.celsiuspanel.it/api"

# Server di sviluppo dell'agenzia, lasciato nell'app. Da non usare, solo nota.
DEV_URL = "https://celsius.simbiosidev.it"

# Broker MQTT su AWS IoT Core. Le credenziali per collegarsi le fornisce
# il server REST tramite l'endpoint MQTT_SERVER (sotto).
MQTT_HOST_PROD = "a3mrfdlotu8zoh-ats.iot.eu-west-1.amazonaws.com"
MQTT_HOST_DEV = "a16c8rrijbloih-ats.iot.eu-west-1.amazonaws.com"

# Indirizzo del pannello quando è in modalità hotspot "CELSIUS_PANEL"
# (configurazione Wi-Fi). Tipico di un chip ESP32.
PANEL_AP_IP = "192.168.4.1"
PANEL_AP_SSID = "CELSIUS_PANEL"

# --- Endpoint del server REST ---------------------------------------------
# Autenticazione / account
LOGIN = "/login"
LOGIN_CHECK = "/login-check"
REGISTRATION = "/registration"
RETRIEVE_PASSWORD = "/retrieve-password"
PASSWORD_RESET_REQUEST = "/password/reset-request"
APP_VERSION = "/app-version"

# Case e pannelli (lettura)
BUILDINGS = "/buildings"
PANELS = "/panels"
PANEL_SETTINGS = "/panel/settings"
PANEL_STATS = "/panel/settings/stats"

# Comandi sul pannello
MODE_MANUAL_ON = "/mode-manual-on"    # accendi (manuale)
MODE_MANUAL_OFF = "/mode-manual-off"  # spegni (manuale)
MODE_SCHEDULED = "/mode-scheduled"    # modalità programmata (AUTO)
RESTART = "/restart"
FIRMWARE_UPGRADE = "/firmwareupgrade"
SETTINGS_UPDATE = "/settings-update"

# Programmi (scheduling)
SET_SCHEDULING = "/set-scheduling"
PANEL_SCHEDULING = "/panel/scheduling"
BUILDING_SCHEDULING = "/building/scheduling"

# Credenziali per il broker MQTT (dati in tempo reale)
MQTT_SERVER = "/mqtt-server"

# Condivisione casa
BUILDING_SHARINGS = "/building-sharings"
SHARINGS = "/sharings"
