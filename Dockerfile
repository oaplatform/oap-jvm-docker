FROM debian:bullseye-slim

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    tzdata curl ca-certificates fontconfig locales jq bc \
    procps \
    sysstat \
    ncat \
    net-tools \
    libjna-java \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-18.0.2.1+1

RUN set -eux; \
    JAVA_VERSION_URLENCODE="$(printf ${JAVA_VERSION} | jq -sRr '@uri')"; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         BINARY_URL="https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1%2B1/OpenJDK18U-jdk_aarch64_linux_hotspot_18.0.2.1_1.tar.gz"; \
         ;; \
       amd64|x86_64) \
         BINARY_URL="https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1%2B1/OpenJDK18U-jdk_x64_linux_hotspot_18.0.2.1_1.tar.gz"; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"

ARG mongo

MAINTAINER igor.petrenko <igor.petrenko@xenoss.io>

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    gnupg2 libgomp1 less nano htop mc \
    procps

COPY start.sh /opt/xenoss/
RUN chmod +x /opt/xenoss/start.sh

RUN if [ "$mongo" = "true" ] ;  then \
    apt-get install -y gnupg2 && \
    curl -Ls https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add - && \
    echo "deb hhttp://repo.mongodb.org/apt/debian bullseye/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list && \
    apt-get update && \
    apt-get install -y mongodb-org-shell \
    ; fi

RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
