ARG BUILD_FROM
FROM $BUILD_FROM
ARG BUILD_ARCH

COPY rootfs/app/bin/${BUILD_ARCH}/x2iot-app /app/x2iot-app
RUN chmod +x /app/x2iot-app

COPY rootfs/app/site/ /app/site/

# Tlumaczenia dostarczane z programem (pl i inne; angielski jest wkompilowany)
COPY rootfs/app/lang/ /app/lang/

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
