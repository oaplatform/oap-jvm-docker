#!/usr/bin/env bash

cd $1

exec java \
  @conf/vm.options \
  -XX:ActiveProcessorCount=$(($(nproc) / 2)) \
  -cp $1/conf:lib/* \
  oap.application.Boot \
  --start \
  --config-directory=/etc/xenoss/conf.d \
  --config=conf/application.conf
