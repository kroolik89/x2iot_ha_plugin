ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH

# Kopiuj pre-built binary odpowiedni dla architektury
COPY rootfs/app/bin/${BUILD_ARCH}/x2iot-app /app/x2iot-app
RUN chmod +x /app/x2iot-app

# Kopiuj site assets (WASM/CSS/JS - wspólne dla wszystkich architektur)
COPY rootfs/app/site/ /app/site/

# Standardowe uruchomienie jako demon za pomocą mechanizmów HA S6-Overlay
COPY run.sh /etc/services.d/x2iot/run
RUN chmod +x /etc/services.d/x2iot/run

LABEL \
    io.hass.name="x2iot Hub" \
    io.hass.version="0.1.0" \
    io.hass.type="addon"
