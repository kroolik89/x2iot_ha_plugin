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

# Test wydajnosci (opcja dodatku load_test_secs > 0): x2iot robi test zamiast pracy, wynik w logu i w /data/load_test_*.txt,
# potem zwykly start. Po tescie ustaw load_test_secs = 0 - inaczej test powtorzy sie przy kazdym starcie dodatku.
OPTIONS=/data/options.json
opt() {
    jq -r ".$1 // empty" "$OPTIONS" 2>/dev/null
}
LOAD_SECS=$(opt load_test_secs)
if [ -n "$LOAD_SECS" ] && [ "$LOAD_SECS" -gt 0 ] 2>/dev/null; then
    echo "TEST WYDAJNOSCI: ${LOAD_SECS} s - x2iot nie dziala w tym czasie (integracje i GUI wylaczone)."
    # Puste zmienne program pomija (wartosci domyslne).
    X2IOT_LOAD_DI=$(opt load_di) X2IOT_LOAD_DI_PERIOD_MS=$(opt load_di_period_ms) \
    X2IOT_LOAD_DO=$(opt load_do) X2IOT_LOAD_DO_PERIOD_MS=$(opt load_do_period_ms) \
    X2IOT_LOAD_TI=$(opt load_ti) X2IOT_LOAD_TI_PERIOD_MS=$(opt load_ti_period_ms) \
        /app/x2iot-app --load-test "$LOAD_SECS"
    echo "TEST WYDAJNOSCI zakonczony (kod $?). Ustaw load_test_secs = 0 w opcjach dodatku. Start normalnej pracy..."
fi

exec /app/x2iot-app
