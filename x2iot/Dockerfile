ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64

# Kopiuj pre-built binary odpowiedni dla architektury
COPY rootfs/app/bin/${BUILD_ARCH}/x2iot-app /app/x2iot-app
RUN chmod +x /app/x2iot-app

# Kopiuj site assets (WASM/CSS/JS - wspólne dla wszystkich architektur)
COPY rootfs/app/site/ /app/site/

# Kopiuj skrypt startowy
COPY run.sh /run.sh
RUN chmod +x /run.sh

LABEL \
    io.hass.name="x2iot Hub" \
    io.hass.version="0.1.0" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64"

CMD ["/run.sh"]
