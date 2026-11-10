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
# potem zwykly start. Parametry testu (liczby elementow, mieszanka, okresy) sa wbudowane w program - w dodatku tylko czas.
# Opcja wraca na 0 PRZED testem (API Supervisora), zeby test nie powtarzal sie przy kolejnym starcie - takze gdy dodatek
# zostanie zatrzymany albo padnie w trakcie testu.
OPTIONS=/data/options.json
LOAD_SECS=$(jq -r ".load_test_secs // empty" "$OPTIONS" 2>/dev/null)
if [ -n "$LOAD_SECS" ] && [ "$LOAD_SECS" -gt 0 ] 2>/dev/null; then
    if curl -sSf -X POST \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"options":{"load_test_secs":0}}' \
        http://supervisor/addons/self/options >/dev/null; then
        echo "Opcja load_test_secs ustawiona z powrotem na 0 (nastepny start bez testu)."
    else
        echo "UWAGA: nie udalo sie ustawic load_test_secs = 0 przez API Supervisora - ustaw recznie w opcjach dodatku."
    fi
    echo "TEST WYDAJNOSCI: ${LOAD_SECS} s - x2iot nie dziala w tym czasie (integracje i GUI wylaczone)."
    /app/x2iot-app --load-test "$LOAD_SECS"
    CODE=$?
    # Podsumowanie jeszcze raz na koniec (log dodatku pokazuje koniec, probki co 10 s sa wyzej i w pliku).
    LAST=$(ls -t /data/load_test_*.txt 2>/dev/null | head -1)
    if [ -n "$LAST" ]; then
        echo "---------------- podsumowanie: $LAST ----------------"
        sed '/^samples every/,$d' "$LAST"
    fi
    echo "TEST WYDAJNOSCI zakonczony (kod $CODE). Start normalnej pracy..."
fi

exec /app/x2iot-app
