#!/bin/sh

export X2IOT_CONFIG_PATH="/data/configuration.yaml"
export LEPTOS_SITE_ADDR="0.0.0.0:8356"
export LEPTOS_SITE_ROOT="/app/site"
export LEPTOS_OUTPUT_NAME="x2iot"
export LEPTOS_SITE_PKG_DIR="pkg"
# Tlumaczenia programu; pliki uzytkownika (nowe jezyki, poprawki) w /data/lang/<core|satel>/<kod>.json
export X2IOT_LANG_DIR="/app/lang"

echo "Rozpoczynam serwer RUST x2iot na porcie 8356..."

if [ ! -f /data/configuration.yaml ]; then
    echo "Brak /data/configuration.yaml - serwer wygeneruje czysta konfiguracje domyslna."
else
    echo "Konfiguracja /data/configuration.yaml juz istnieje, zachowuje istniejacy plik."
fi

exec /app/x2iot-app
