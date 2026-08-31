#!/bin/sh

export X2IOT_CONFIG_PATH="/data/configuration.yaml"
export LEPTOS_SITE_ADDR="0.0.0.0:8356"
export LEPTOS_SITE_ROOT="/app/site"
export LEPTOS_OUTPUT_NAME="x2iot"
export LEPTOS_SITE_PKG_DIR="pkg"

echo "Rozpoczynam serwer RUST x2iot na porcie 8356..."

exec /app/x2iot-app
