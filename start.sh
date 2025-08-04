#!/bin/bash

set -x

if [ -d "/vault/secrets" ]; then
  for secret in $(find /vault/secrets -type f | sort -n); do
    source $secret
  done
fi

cpuCount=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')

if [[ -z "${cpuCount}" ]]; then
  cpuCount=$(nproc --all)
fi

if [[ -z "${JAVA_CPU_AFFINITY_SKIP_FIRST}" ]]; then
  javaCpuCount=$cpuCount
  CMD="java"
else
  ((javaCpuCount=cpuCount-JAVA_CPU_AFFINITY_SKIP_FIRST))
  ((fromCpu=JAVA_CPU_AFFINITY_SKIP_FIRST))

  CMD="taskset --cpu-list ${fromCpu}-${cpuCount} java -XX:ActiveProcessorCount=${javaCpuCount}"

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
  --add-opens=java.base/jdk.internal.misc=ALL-UNNAMED \
  -cp $1/conf:lib/* \
  oap.application.Boot \
  --start \
  --config-directory=conf.d \
  --config=conf/application.conf
