# https://github.com/AdoptOpenJDK/openjdk-docker/blob/master/15/jdk/debianslim/Dockerfile.hotspot.releases.full
FROM debian:buster-slim

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata curl ca-certificates fontconfig locales jq \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-15.0.2+7

RUN set -eux; \
    JAVA_VERSION_URLENCODE="$(printf ${JAVA_VERSION} | jq -sRr '@uri')"; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='6e8b6b037148cf20a284b5b257ec7bfdf9cc31ccc87778d0dfd95a2fddf228d4'; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/${JAVA_VERSION_URLENCODE}/OpenJDK15U-jdk_aarch64_linux_hotspot_15.0.2_7.tar.gz"; \
         ;; \
       armhf|armv7l) \
         ESUM='ff39c0380224e419d940382c4d651cb1e6297a794854e0cc459c1fd4973b3368'; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/${JAVA_VERSION_URLENCODE}/OpenJDK15U-jdk_arm_linux_hotspot_15.0.2_7.tar.gz"; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='486f2aad94c5580c0b27c9007beebadfccd4677c0bd9565a77ca5c34af5319f9'; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/${JAVA_VERSION_URLENCODE}/OpenJDK15U-jdk_ppc64le_linux_hotspot_15.0.2_7.tar.gz"; \
         ;; \
       s390x) \
         ESUM='7dc35a8a4ba1ccf6cfe96fcf26e09ed936f1802ca668ca6bf708e2392c35ab6a'; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/${JAVA_VERSION_URLENCODE}/OpenJDK15U-jdk_s390x_linux_hotspot_15.0.2_7.tar.gz"; \
         ;; \
       amd64|x86_64) \
         ESUM='94f20ca8ea97773571492e622563883b8869438a015d02df6028180dd9acc24d'; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/${JAVA_VERSION_URLENCODE}/OpenJDK15U-jdk_x64_linux_hotspot_15.0.2_7.tar.gz"; \
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
