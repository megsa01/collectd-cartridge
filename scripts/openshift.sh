#!/bin/bash
# This script collects simplifed cpu and disk metrics


HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="${COLLECTD_INTERVAL:-30}"

prev_total=0
prev_idle=0
while sleep "$INTERVAL"; do
  cpu=`cat /proc/stat | head -n1 | sed 's/cpu //'`
  user=`echo $cpu | awk '{print $1}'`
  system=`echo $cpu | awk '{print $2}'`
  nice=`echo $cpu | awk '{print $3}'`
  idle=`echo $cpu | awk '{print $4}'`
  wait=`echo $cpu | awk '{print $5}'`
  irq=`echo $cpu | awk '{print $6}'`
  srq=`echo $cpu | awk '{print $7}'`
  zero=`echo $cpu | awk '{print $8}'`
  total=$(($user+$system+$nice+$idle+$wait+$irq+$srq+$zero))
  diff_idle=$(($idle-$prev_idle))
  diff_total=$(($total-$prev_total))
  usage=$(($((1000*$(($diff_total-$diff_idle))/$diff_total+5))/10))
  echo "PUTVAL $HOSTNAME/cpu_util/cpu_util interval=$INTERVAL N:$usage"
  prev_total=$total
  prev_idle=$idle

  iops=`iostat -d 1 2 | awk 'NR <= 7 {next};{SUM += $2} END {print SUM}'`
  echo "PUTVAL $HOSTNAME/disk_iops/disk_iops interval=$INTERVAL N:$iops"
done
