FROM adoptopenjdk/openjdk15:jdk-15.0.1_9-ubuntu

ARG mongo

MAINTAINER igor.petrenko <igor.petrenko@xenoss.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg2 libgomp1 less nano htop mc

COPY start.sh /opt/xenoss/
RUN chmod +x /opt/xenoss/start.sh

RUN if [ "$mongo" = "true" ] ;  then \
    apt-get install -y gnupg2 && \
    curl -Ls https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
    echo "deb https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
    apt-get update && \
    apt-get install -y mongodb-org-shell \
    ; fi
