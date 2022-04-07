# syntax = docker/dockerfile:experimental

FROM pfelipefeitosa/criu:alpine-v3.13 as criu

FROM pfelipefeitosa/of-watchdog:criu-light as watchdog

FROM skharban/pypy:alpine-v3.11

ARG ADDITIONAL_PACKAGE

# Alternatively use ADD https:// (which will not be cached by Docker builder)
RUN apk --no-cache add openssl-dev ${ADDITIONAL_PACKAGE}

WORKDIR /home/app
COPY . /home/app/

ENV PATH=$PATH:/home/app/.local/bin

COPY --from=criu /usr/local/sbin/criu /usr/local/sbin/criu
COPY --from=criu /usr/lib/libprotobuf-c.so.1 /usr/lib/libprotobuf-c.so.1
COPY --from=criu /usr/lib/libnl-3.so.200 /usr/lib/libnl-3.so.200
COPY --from=criu /usr/lib/libnet.so.1 /usr/lib/libnet.so.1
RUN chmod +x /usr/local/sbin/criu

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

RUN pip install -r requirements.txt

WORKDIR /home/app/function/
RUN pip install --user -r requirements.txt

COPY warmup.sh .
RUN chmod +x warmup.sh
RUN apk --no-cache add curl

# COPY resource.* .

WORKDIR /home/app/

ENV cgi_headers="true"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:5000"
ENV mode="http"
ENV WARM_REQ="YES"
ENV criu_exec="true"
ENV restore_log_path="./restore.log"

ENV fprocess="python index.py"
EXPOSE 8080

RUN --security=insecure (setsid fwatchdog < /dev/null &> app.log &) && ./warmup.sh && (criu dump -t $(pgrep fwatchdog) -o dump.log -v3)

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

CMD criu restore -d -v3 -o restore.log && tail -f /dev/null