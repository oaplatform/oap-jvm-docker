#!/bin/bash

paddy() {
    how_many_bits=$1
    read number
    zeros=$(( $how_many_bits - ${#number} ))
    for ((i=0;i<$zeros;i++)); do
    echo -en 0
    done && echo $number
}

if [[ $(uname -a) == *"aarch64"* ]]; then
  cpuCount=$(nproc)
else
  cpuCount=$(($(nproc) / 2))
fi

if [[ -z "${ENS5_CPUS}" ]]; then
  ENS5_CPUS=0
  javaCpuCount=$cpuCount
  CMD="java"
else
  interrupts=$(cat /proc/interrupts | grep ens5-Tx-Rx | awk '{print $1}')
  interruptCount=$(echo "$interrupts" | wc -l)

  ((javaCpuCount=cpuCount-(interruptCount/ENS5_CPUS)))

  CMD="taskset --cpu-list 0-$((javaCpuCount-1)) java"

  echo "ENS5_CPUS = ${ENS5_CPUS} interruptCount ${interruptCount}"

  ((lastCpu=cpuCount-1))
  i=0;
  while IFS= read -r interruptLine; do
    interrupt=${interruptLine::-1}
    
    smp_affinity_hex=$(cat /proc/irq/${interrupt}/smp_affinity)
    
    echo "OLD interrupt ${interrupt} smp_affinity ${smp_affinity_hex}"

    ((i=i+1))    
    if((i > ENS5_CPUS)); then
        ((lastCpu=lastCpu-1))
        i=1;
    fi
    smp_affinity_hex=$(echo "obase=16; ibase=10; $lastCpu" | bc | paddy 4)
    
    echo "NEW interrupt ${interrupt} smp_affinity ${smp_affinity_hex}"
    
    echo "${smp_affinity_hex}" >> /proc/irq/${interrupt}/smp_affinity

  done <<< "$interrupts"
fi

cd $1 || exit 2;

echo "cpuCount ${cpuCount} javaCpuCount ${javaCpuCount} exec ${CMD}"

#exec ${CMD} \
#  @conf/vm.options \
#  -XX:ActiveProcessorCount=${cpuCount} \
#  -cp $1/conf:lib/* \
#  oap.application.Boot \
#  --start \
#  --config-directory=conf.d \
#  --config=conf/application.conf
