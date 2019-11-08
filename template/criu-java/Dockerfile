# syntax = docker/dockerfile:experimental

FROM pfelipefeitosa/criu:alpine-v3.13 as criu

FROM openfaas/of-watchdog:0.7.2 as watchdog

FROM openjdk:8u212-jdk-alpine as builder

RUN apk --no-cache add curl \
    && addgroup -S app && adduser -S -g app app \
    && mkdir -p /opt/ && cd /opt/ \
    && echo "Downloading gradle.." \
    && curl -sSfL https://services.gradle.org/distributions/gradle-5.5.1-bin.zip -o gradle-bin.zip \
    && unzip gradle-bin.zip -d /opt/ \
    && rm gradle-bin.zip \
    && apk del curl

# Export some environment variables
ENV GRADLE_HOME=/opt/gradle-5.5.1/
ENV PATH=$PATH:$GRADLE_HOME/bin

RUN mkdir -p /home/app/libs

ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
WORKDIR /home/app

COPY . /home/app/

RUN gradle build

FROM openjdk:8u212-jdk-alpine as ship

COPY --from=criu /usr/local/sbin/criu /usr/local/sbin/criu
COPY --from=criu /usr/lib/libprotobuf-c.so.1 /usr/lib/libprotobuf-c.so.1
COPY --from=criu /usr/lib/libnl-3.so.200 /usr/lib/libnl-3.so.200
COPY --from=criu /usr/lib/libnet.so.1 /usr/lib/libnet.so.1
RUN chmod +x /usr/local/sbin/criu

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

WORKDIR /home/app
COPY --from=builder /home/app/entrypoint/build/distributions/entrypoint-1.0.zip ./entrypoint-1.0.zip
RUN unzip ./entrypoint-1.0.zip
RUN rm ./entrypoint-1.0.zip

ENV upstream_url="http://127.0.0.1:8082"
ENV mode="http"
ENV CLASSPATH="/home/app/entrypoint-1.0/lib/*"

ENV fprocess="java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap com.openfaas.entrypoint.App"
EXPOSE 8080

RUN --security=insecure (setsid fwatchdog < /dev/null &> app.log &) && sleep 10 && (criu dump -t $(pgrep fwatchdog) -o dump.log -v4) && (echo OK)

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

CMD criu restore -d -v3 -o restore.log && echo OK && tail -f /dev/null