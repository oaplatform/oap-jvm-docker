#!/bin/bash

set -x

if [[ $(uname -a) == *"aarch64"* ]]; then
  cpuCount=$(nproc)
else
  cpuCount=$(($(nproc) / 2))
fi

if [[ -z "${JAVA_CPU_AFFINITY_SKIP_FIRST}" ]]; then
  javaCpuCount=$cpuCount
  CMD="java"
else
  ((javaCpuCount=cpuCount-JAVA_CPU_AFFINITY_SKIP_FIRST))
  ((fromCpu=JAVA_CPU_AFFINITY_SKIP_FIRST-1))

  CMD="taskset --cpu-list ${fromCpu}-${cpuCount} java"

  echo "JAVA_CPU_AFFINITY_SKIP_FIRST = ${JAVA_CPU_AFFINITY_SKIP_FIRST}"
fi

cd $1 || exit 2;

echo "cpuCount ${cpuCount} javaCpuCount ${javaCpuCount} exec ${CMD}"

exec ${CMD} \
  @conf/vm.options \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.math=ALL-UNNAMED \
  --add-opens=java.base/java.util=ALL-UNNAMED \
  --add-opens=java.base/java.util.stream=ALL-UNNAMED \
  --add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
  --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
  --add-opens=java.base/java.net=ALL-UNNAMED \
  --add-opens=java.base/java.text=ALL-UNNAMED \
  --add-opens=java.sql/java.sql=ALL-UNNAMED \
  -XX:ActiveProcessorCount=${javaCpuCount} \
  -cp $1/conf:lib/* \
  oap.application.Boot \
  --start \
  --config-directory=conf.d \
  --config=conf/application.conf
