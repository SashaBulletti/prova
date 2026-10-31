#!/usr/bin/env bash
# Installa (o aggiorna) l'integrazione Celsius dentro Home Assistant.
# Home Assistant gira sullo Zima come container Docker; la sua cartella
# di configurazione e' /DATA/AppData/homeassistant/config.
#
# Uso dal Mac, dentro la cartella "prova":   bash installa-home-assistant.sh

ZIMA="Sasha@192.168.1.20"
CONTAINER="homeassistant"

cd "$(dirname "$0")" || exit 1

echo "▶ Prendo l'ultima versione dell'integrazione"
git pull --quiet || echo "  (git pull saltato, uso quella che ho)"

if [ ! -d custom_components/celsius ]; then
  echo "✗ Non trovo custom_components/celsius. Sei nella cartella 'prova'?"
  exit 1
fi

echo "▶ Copio l'integrazione sullo Zima e riavvio Home Assistant"
echo "  (ti chiede la password dello ZIMA)"

tar czf - -C custom_components celsius | ssh "$ZIMA" '
  set -e
  cd /tmp
  rm -rf celsius celsius.tgz
  cat > celsius.tgz
  tar xzf celsius.tgz
  docker exec '"$CONTAINER"' mkdir -p /config/custom_components
  docker exec '"$CONTAINER"' rm -rf /config/custom_components/celsius
  docker cp celsius '"$CONTAINER"':/config/custom_components/
  rm -rf celsius celsius.tgz
  docker restart '"$CONTAINER"' >/dev/null
  echo "  ✓ Integrazione copiata e Home Assistant riavviato."
'

echo
echo "✅ Fatto! Aspetta circa 1 minuto che Home Assistant riparta, poi apri HA:"
echo "   Impostazioni → Dispositivi e servizi → Aggiungi integrazione → Celsius Panel"
echo "   (ti chiede email e password del tuo account Celsius)"
