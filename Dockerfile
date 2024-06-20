FROM debian:bookworm-slim

ARG JVM_VERSION

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

MAINTAINER igor.petrenko <igor.petrenko@xenoss.io>

COPY start.sh /opt/xenoss/

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tzdata curl ca-certificates fontconfig locales jq bc \
      procps  sysstat ncat net-tools libjna-java \
      gnupg2 libgomp1 less nano htop mc procps \
      gpg ca-certificates curl wget gnupg
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
RUN wget -O - https://apt.corretto.aws/corretto.key | \gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list
RUN apt-get update
RUN apt-get install -y java-${JVM_VERSION}-amazon-corretto-jdk
RUN chmod +x /opt/xenoss/start.sh
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/
