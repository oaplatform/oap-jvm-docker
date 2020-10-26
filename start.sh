#!/bin/bash

cd $1

if [[ $(uname -a) == *"aarch64"* ]]; then
  cpuCount=$(nproc)
else
  cpuCount=$(($(nproc) / 2))
fi

echo "exec java \
  @conf/vm.options \
  -XX:ActiveProcessorCount=${cpuCount} \
  -cp $1/conf:lib/* \
  oap.application.Boot \
  --start \
  --config-directory=/etc/xenoss/conf.d \
  --config=conf/application.conf"
