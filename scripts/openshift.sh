#!/bin/bash
# This script collects simplifed cpu and disk metrics


HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

while sleep "$INTERVAL"; do

  USED=$(oo-cgroup-read memory.usage_in_bytes)
  MAX_USED=$(oo-cgroup-read memory.max_usage_in_bytes)
  LIMIT=$(oo-cgroup-read memory.limit_in_bytes)
  FREE=$(($LIMIT-$USED))

  echo "PUTVAL $HOSTNAME/gear_memory/used_memory interval=$INTERVAL N:$USED"
  echo "PUTVAL $HOSTNAME/gear_memory/max_memory interval=$INTERVAL N:$MAX_USED"
  echo "PUTVAL $HOSTNAME/gear_memory/limit_memory interval=$INTERVAL N:$LIMIT"
  echo "PUTVAL $HOSTNAME/gear_memory/free_memory interval=$INTERVAL N:$FREE"

  VALUE=$(oo-cgroup-read cpuacct.stat)
  SYS=`echo $VALUE | cut -f 4 -d " "`
  USER=`echo $VALUE |cut -f 2 -d " "`

  echo "PUTVAL $HOSTNAME/cpu_util/gear_cpu_user interval=$INTERVAL N:$USER"
  echo "PUTVAL $HOSTNAME/cpu_util/gear_cpu_system interval=$INTERVAL N:$SYS"

  USED_DISK_SPACE=$(quota -v 2>/dev/null | awk 'FNR == 3 {print $2}')
  LIMIT_DISK_SPACE=$(quota -v 2>/dev/null | awk 'FNR == 3 {print $4}')
  NUMBER_OF_FILES=$(quota -v 2>/dev/null | awk 'FNR == 3 {print $5}')
  LIMIT_NUMBEROF_FILES=$(quota -v 2>/dev/null | awk 'FNR == 3 {print $7}')

  echo "PUTVAL $HOSTNAME/disk_iops/used_disk_space interval=$INTERVAL N:$USED_DISK_SPACE"
  echo "PUTVAL $HOSTNAME/disk_iops/limit_disk_space interval=$INTERVAL N:$LIMIT_DISK_SPACE"
  echo "PUTVAL $HOSTNAME/disk_iops/number_of_files interval=$INTERVAL N:$NUMBER_OF_FILES"
  echo "PUTVAL $HOSTNAME/disk_iops/limit_numberof_files interval=$INTERVAL N:$LIMIT_NUMBEROF_FILES"

  y=7
  flag="true"

  while $flag;  do

        diskName_cmd="iostat -x | awk 'FNR == "$y" {print $""1}'"
        cpu_util_cmd="iostat -x | awk 'FNR == "$y" {print $""12}'"
        io_kb_read_cmd="iostat -k | awk 'FNR == "$y" {print $""5}'"
        io_kb_written_cmd="iostat -k | awk 'FNR == "$y" {print $""6}'"

        diskName=$(eval $diskName_cmd)
          if [ -z $diskName ];  then
                flag="false"
          else
                cpu_util=$(eval $cpu_util_cmd)
                echo "PUTVAL $HOSTNAME/disk_iops-$diskName/cpu_util_percent interval=$INTERVAL N:$cpu_util"
                io_kb_read=$(eval $io_kb_read_cmd)
                echo "PUTVAL $HOSTNAME/disk_iops-$diskName/io_kb_read interval=$INTERVAL N:$io_kb_read"
                io_kb_written=$(eval $io_kb_written_cmd)
                echo "PUTVAL $HOSTNAME/disk_iops-$diskName/io_kb_written interval=$INTERVAL N:$io_kb_written"
          fi
          y=$(( $y + 1 ))
  done
done
