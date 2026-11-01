#!/bin/sh
# One line per metric; parsed in main.qml
head -n1 /proc/stat | awk '{print "cpu", $2+$3+$4+$5+$6+$7+$8, $5+$6}'
awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}/SwapTotal/{st=$2}/SwapFree/{sf=$2}END{print "mem", t, a, st, sf}' /proc/meminfo
# $4 = interface name; empty means the one carrying the default route (lowest metric),
# or every interface except lo when there is no default route
iface=$4
[ -z "$iface" ] && iface=$(awk 'NR>1 && $2=="00000000" && (m=="" || $7+0<m){m=$7+0; n=$1}END{print n}' /proc/net/route)
# Names up to 6 chars are space padded, longer ones (wlp2s0, enp5s0) are not, so split on the colon
awk -v i="$iface" 'NR>2 {
  c = index($0, ":"); name = substr($0, 1, c - 1); gsub(/ /, "", name)
  split(substr($0, c + 1), f, " ")
  if (i == "" ? name != "lo" : name == i) { rx += f[1]; tx += f[9] }
}END{print "net", rx+0, tx+0, (i==""?"-":i)}' /proc/net/dev
df -B1 --output=used,size "${1:-/}" 2>/dev/null | awk 'NR==2{print "disk", $1, $2}'
awk '{print "load", $1, $2, $3}' /proc/loadavg
awk '{print "up", int($1)}' /proc/uptime
# $2 = "<hwmon name>/<tempN>[@<device>]" picks a sensor; empty means the CPU sensor
want=${2%%@*}; dev=; case $2 in *@*) dev=${2#*@};; esac
for h in /sys/class/hwmon/hwmon*; do
  n=$(cat $h/name 2>/dev/null)
  if [ -n "$2" ]; then
    d=$(basename "$(readlink -f $h/device 2>/dev/null)")
    [ "$n" = "${want%%/*}" ] && { [ -z "$dev" ] || [ "$d" = "$dev" ]; } && [ -r "$h/${want#*/}_input" ] \
      && echo "temp $(cat $h/${want#*/}_input)" && break
    continue
  fi
  case $n in k10temp|coretemp|zenpower|cpu_thermal)
    for f in $h/temp*_input; do [ -r "$f" ] && echo "temp $(cat $f)" && break 2; done;;
  esac
done
ps -eo comm,pcpu --sort=-pcpu --no-headers | head -n5 | awk '{print "top", $2, $1}'
# $3 = power_supply name; empty means the first system battery (peripherals are skipped)
for b in /sys/class/power_supply/${3:-*}; do
  [ "$(cat $b/type 2>/dev/null)" = Battery ] || continue
  [ -r "$b/capacity" ] || continue
  [ -z "$3" ] && [ "$(cat $b/scope 2>/dev/null)" = Device ] && continue
  # microvolts, microwatts (power_now, else current_now * voltage_now); -1 when the device doesn't report it
  awk -v c="$(cat $b/capacity)" -v v="$(cat $b/voltage_now 2>/dev/null)" -v p="$(cat $b/power_now 2>/dev/null)" \
      -v i="$(cat $b/current_now 2>/dev/null)" -v s="$(cat $b/status 2>/dev/null)" \
      'BEGIN{if (p=="" && v!="" && i!="") p=v*i/1e6; printf "bat %d %d %d %s\n", c, (v==""?-1:v), (p==""?-1:p), (s==""?"Unknown":s)}'
  break
done
awk '/^cpu[0-9]/{printf "%s %d %d ", $1, $2+$3+$4+$5+$6+$7+$8, $5+$6; n++}END{if(n) print ""}' /proc/stat | sed 's/^/cores /'
