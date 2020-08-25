FROM adoptopenjdk/openjdk13:latest

MAINTAINER igor.petrenko <igor.petrenko@xenoss.io>

RUN apt-get update && apt-get install -y gnupg2 libgomp1 less

COPY start.sh /opt/xenoss/
RUN chmod +x /opt/xenoss/start.sh
