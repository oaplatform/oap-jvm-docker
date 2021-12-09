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

ENV JAVA_VERSION jdk-17.0.1+12

RUN set -eux; \
    JAVA_VERSION_URLENCODE="$(printf ${JAVA_VERSION} | jq -sRr '@uri')"; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='f23d482b2b4ada08166201d1a0e299e3e371fdca5cd7288dcbd81ae82f3a75e3'; \
         BINARY_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.1%2B12/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.1_12.tar.gz"; \
         ;; \
       amd64|x86_64) \
         ESUM='6ea18c276dcbb8522feeebcfc3a4b5cb7c7e7368ba8590d3326c6c3efc5448b6'; \
         BINARY_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.1%2B12/OpenJDK17U-jdk_x64_linux_hotspot_17.0.1_12.tar.gz"; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
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
    curl -Ls https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
    echo "deb https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
    apt-get update && \
    apt-get install -y mongodb-org-shell \
    ; fi

RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
