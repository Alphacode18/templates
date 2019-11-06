FROM openjdk:8u212-jdk-alpine as builder

RUN apk update \
	&& apk --no-cache add curl \
    && addgroup -S app && adduser -S -g app app \
    && mkdir -p /opt/ && cd /opt/ \
    && echo "Downloading gradle.." \
    && curl -sSfL https://services.gradle.org/distributions/gradle-5.5.1-bin.zip -o gradle-bin.zip \
    && unzip gradle-bin.zip -d /opt/ \
    && rm gradle-bin.zip 

RUN apk --no-cache add git wget autoconf automake libtool curl make g++ unzip pkg-config \
	&& mkdir criu-deps

# Install Protocol Buffers	
RUN cd criu-deps \
	&& git clone https://github.com/google/protobuf.git protobuf \
	&& cd protobuf \
	&& ./autogen.sh \
	&& ./configure --prefix=`pwd`/../`uname -m`-linux-gnu \
	&& make \
	&& make install \
	&& cd ../..

RUN cd criu-deps \
	&& git clone https://github.com/protobuf-c/protobuf-c.git protobuf-c \
	&& cd protobuf-c \
	&& ./autogen.sh \
	&& mkdir ../pbc-`uname -m` \
	&& cd ../pbc-`uname -m` \
	&& ../protobuf-c/configure --prefix=`pwd`/../`uname -m`-linux-gnu PKG_CONFIG_PATH=`pwd`/../`uname -m`-linux-gnu/lib/pkgconfig \
	&& make \
	&& make install \
	&& cd ../..

# Install CRIU deps
RUN apk --no-cache add pkg-config iproute2 libcap-dev libnet1-dev asciidoc xmlto

# Install CRIU
RUN wget https://download.openvz.org/criu/criu-2.6.tar.bz2 \
	&& tar xvfj criu-2.6.tar.bz2 \
	&& cd criu-2.6 \
	&& make \
	&& make install \
	&& criu check --all \
	&& cd ..

RUN apk del git wget autoconf automake libtool curl make g++ unzip pkg-config

# Export some environment variables
ENV GRADLE_HOME=/opt/gradle-5.5.1/
ENV PATH=$PATH:$GRADLE_HOME/bin

RUN mkdir -p /home/app/libs

ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
WORKDIR /home/app

COPY . /home/app/

RUN gradle build

FROM openfaas/of-watchdog:0.7.2 as watchdog

FROM openjdk:8u212-jdk-alpine as ship

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

RUN addgroup -S app && adduser -S -g app app
WORKDIR /home/app
COPY --from=builder /home/app/entrypoint/build/distributions/entrypoint-1.0.zip ./entrypoint-1.0.zip
RUN unzip ./entrypoint-1.0.zip

RUN chown -R app /home/app
USER app

ENV upstream_url="http://127.0.0.1:8082"
ENV mode="http"
ENV CLASSPATH="/home/app/entrypoint-1.0/lib/*"

ENV fprocess="java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap com.openfaas.entrypoint.App"
EXPOSE 8080

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
