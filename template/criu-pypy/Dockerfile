# syntax = docker/dockerfile:experimental

FROM pfelipefeitosa/criu:alpine-v3.13 as criu

FROM pfelipefeitosa/of-watchdog:criu-light as watchdog

FROM skharban/pypy:alpine-v3.11

# Allows you to add additional packages via build-arg
ARG ADDITIONAL_PACKAGE

COPY --from=criu /usr/local/sbin/criu /usr/local/sbin/criu
COPY --from=criu /usr/lib/libprotobuf-c.so.1 /usr/lib/libprotobuf-c.so.1
COPY --from=criu /usr/lib/libnl-3.so.200 /usr/lib/libnl-3.so.200
COPY --from=criu /usr/lib/libnet.so.1 /usr/lib/libnet.so.1
RUN chmod +x /usr/local/sbin/criu

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

# Add non root user
RUN addgroup -S app && adduser app -S -G app

WORKDIR /home/app/

COPY index.py           .
COPY requirements.txt   .

RUN chown -R app /home/app && \
  mkdir -p /home/app/python && chown -R app /home/app
ENV PATH=$PATH:/home/app/.local/bin:/home/app/python/bin/
ENV PYTHONPATH=$PYTHONPATH:/home/app/python

RUN pip install -r requirements.txt --target=/home/app/python

RUN mkdir -p function
RUN touch ./function/__init__.py

WORKDIR /home/app/function/
COPY function/requirements.txt	.

RUN pip install -r requirements.txt --target=/home/app/python

WORKDIR /home/app/

COPY function           function

RUN chown -R app:app ./ && \
  chmod -R 777 /home/app/python

ENV upstream_url="http://127.0.0.1:8082"
ENV mode="http"
ENV WARM_REQ="YES"
ENV HTTP_SERVER_ADDRESS="localhost:8082"
ENV criu_exec="true"
ENV restore_log_path="./restore.log"

ENV fprocess="pypy3 index.py"
EXPOSE 8080

RUN --security=insecure (setsid fwatchdog < /dev/null &> app.log &) && ./warmup.sh && (criu dump -t $(pgrep fwatchdog) -o dump.log -v3)

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

CMD criu restore -d -v3 -o restore.log && tail -f /dev/null
