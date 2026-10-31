#!/bin/sh
# One line per metric; parsed in main.qml
head -n1 /proc/stat | awk '{print "cpu", $2+$3+$4+$5+$6+$7+$8, $5+$6}'
awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}/SwapTotal/{st=$2}/SwapFree/{sf=$2}END{print "mem", t, a, st, sf}' /proc/meminfo
awk -F'[: ]+' 'NR>2 && $2!="lo"{rx+=$3; tx+=$11}END{print "net", rx, tx}' /proc/net/dev
df -B1 --output=used,size "${1:-/}" 2>/dev/null | awk 'NR==2{print "disk", $1, $2}'
awk '{print "load", $1, $2, $3}' /proc/loadavg
awk '{print "up", int($1)}' /proc/uptime
for h in /sys/class/hwmon/hwmon*; do
  n=$(cat $h/name 2>/dev/null)
  case $n in k10temp|coretemp|zenpower|cpu_thermal)
    for f in $h/temp*_input; do [ -r "$f" ] && echo "temp $(cat $f)" && break 2; done;;
  esac
done
ps -eo comm,pcpu --sort=-pcpu --no-headers | head -n5 | awk '{print "top", $2, $1}'
