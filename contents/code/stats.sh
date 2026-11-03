#!/bin/sh
# One line per metric; parsed in main.qml
# printf %.0f, not %d / print: mawk (Debian, Ubuntu) caps those at 2^31, which jiffy and byte counters pass quickly
head -n1 /proc/stat | awk '{printf "cpu %.0f %.0f\n", $2+$3+$4+$5+$6+$7+$8, $5+$6}'
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
}END{printf "net %.0f %.0f %s\n", rx, tx, (i==""?"-":i)}' /proc/net/dev
echo "ip $(ip -4 -o addr show ${iface:+dev $iface} scope global 2>/dev/null | awk '{print $4; exit}' | cut -d/ -f1)"
# $5 = 1 looks up the public address (api.ipify.org), at most every 10 minutes, in the background
if [ "$5" = 1 ]; then
  c=${XDG_RUNTIME_DIR:-/tmp}/plasmetrics-extip
  [ -n "$(find "$c" -mmin -10 2>/dev/null)" ] || (curl -fsS -m 5 https://api.ipify.org >"$c.tmp" 2>/dev/null && mv "$c.tmp" "$c") >/dev/null 2>&1 &
  [ -r "$c" ] && echo "extip $(cat "$c")"
fi
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
  echo "batmodel $(cat $b/model_name 2>/dev/null)"
  # microvolts, microwatts (power_now, else current_now * voltage_now); -1 when the device doesn't report it
  # then seconds until empty (discharging) or full (charging), -1 when unknown
  awk -v c="$(cat $b/capacity)" -v en="$(cat $b/energy_now 2>/dev/null)" -v ef="$(cat $b/energy_full 2>/dev/null)" \
      -v cn="$(cat $b/charge_now 2>/dev/null)" -v cf="$(cat $b/charge_full 2>/dev/null)" -v v="$(cat $b/voltage_now 2>/dev/null)" -v p="$(cat $b/power_now 2>/dev/null)" \
      -v i="$(cat $b/current_now 2>/dev/null)" -v s="$(cat $b/status 2>/dev/null)" \
      'BEGIN{if (p=="" && v!="" && i!="") p=v*i/1e6
        if (en=="" && cn!="" && v!="") { en=cn*v/1e6; ef=cf*v/1e6 }
        t=-1; if (p+0>0 && en!="") { if (s=="Discharging") t=en/p*3600; else if (s=="Charging" && ef!="") t=(ef-en)/p*3600 }
        printf "bat %d %d %d %d %s\n", c, (v==""?-1:v), (p==""?-1:p), t, (s==""?"Unknown":s)}'
  break
done
awk '/^cpu[0-9]/{printf "%s %.0f %.0f ", $1, $2+$3+$4+$5+$6+$7+$8, $5+$6; n++}END{if(n) print ""}' /proc/stat | sed 's/^/cores /'
# Average current CPU clock in kHz; absent when cpufreq isn't exposed
cat /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{s+=$1;n++}END{if(n) printf "freq %d\n", s/n}'
# One line for the GPU in use: "gpu|name|kind|driver|util %|vram used|vram total|temp mC|power uW|MHz|state"
# Walks PCI display devices (not /sys/class/drm), so a card with no driver still shows up. Unknown numbers are -1.
# state: ok, asleep (powered-down discrete GPU, left alone so it isn't woken), nodriver, nostats (driver exposes no usage)
# A GPU that is awake and discrete wins, then the integrated / boot GPU, then a sleeping discrete one.
now=$(awk '{printf "%d", $1 * 1000}' /proc/uptime)
smi=
for p in /sys/bus/pci/devices/*; do
  case $(cat $p/class 2>/dev/null) in 0x03*) ;; *) continue;; esac
  slot=$(basename $p); drv=; [ -e $p/driver ] && drv=$(basename "$(readlink -f $p/driver)")
  vendor=$(cat $p/vendor 2>/dev/null); rs=$(cat $p/power/runtime_status 2>/dev/null)
  util=-1 vu=-1 vt=-1 temp=-1 pw=-1 mhz=-1 state=ok kind=integrated
  name=$(lspci -s "${slot#0000:}" -mm 2>/dev/null | awk -F'"' '{v=$4; n=$6
    if (v ~ /Advanced Micro/) v="AMD"; else if (v ~ /NVIDIA/) v="NVIDIA"; else sub(/ (Corporation|Corp|Inc).*|, Inc.*/, "", v)
    if (match(n, /\[.*\]/)) n=substr(n, RSTART + 1, RLENGTH - 2)
    print (index(n, v) == 1 ? "" : v " ") n}')
  if [ -z "$name" ]; then
    case $vendor in 0x8086) name=Intel;; 0x10de) name=NVIDIA;; 0x1002) name=AMD;; *) name=GPU;; esac
    name="$name $(cat $p/device 2>/dev/null)"
  fi
  for h in $p/hwmon/hwmon*; do
    [ -r $h/temp1_input ] && temp=$(cat $h/temp1_input)
    [ -r $h/power1_average ] && pw=$(cat $h/power1_average)
    [ -r $h/power1_input ] && pw=$(cat $h/power1_input)
    [ -r $h/freq1_input ] && mhz=$(( $(cat $h/freq1_input) / 1000000 ))
    break
  done
  case $drv in
    amdgpu|radeon)
      [ -r $p/gpu_busy_percent ] && util=$(cat $p/gpu_busy_percent)
      [ -r $p/mem_info_vram_total ] && vt=$(cat $p/mem_info_vram_total) vu=$(cat $p/mem_info_vram_used)
      # APUs only carve a slice of system RAM out as "VRAM"
      [ "$vt" -ge 3221225472 ] && kind=discrete
      [ "$drv" = radeon ] && state=nostats;;
    i915|xe)
      # No usage counter without root: use the share of time the GPU is not in its RC6 power-saving state
      n=0 rc6=0
      for f in $p/drm/card*/gt/gt*/rc6_residency_ms $p/tile*/gt*/gtidle/idle_residency_ms; do
        [ -r $f ] && rc6=$((rc6 + $(cat $f))) n=$((n + 1))
      done
      if [ $n -gt 0 ]; then
        c=${XDG_RUNTIME_DIR:-/tmp}/plasmetrics-gpu-$slot
        if [ -r $c ] && read -r t0 r0 <$c && [ "$now" -gt "$t0" ]; then
          util=$(awk -v t=$((now - t0)) -v r=$((rc6 - r0)) -v n=$n 'BEGIN{u=100*(1-r/(t*n)); print (u<0?0:u>100?100:int(u+.5))}')
        fi
        echo "$now $rc6" >$c
      else state=nostats; fi
      for f in $p/drm/card*/gt/gt0/rps_act_freq_mhz $p/drm/card*/gt_act_freq_mhz $p/tile0/gt0/freq0/act_freq; do
        [ -r $f ] && mhz=$(cat $f) && break
      done
      [ -e $p/tile0/vram0 ] || [ -e $p/lmem_total_bytes ] && kind=discrete;;
    nvidia)
      kind=discrete
      if [ "$rs" != suspended ] && command -v nvidia-smi >/dev/null 2>&1; then
        [ -z "$smi" ] && smi=$(timeout 2 nvidia-smi --query-gpu=pci.bus_id,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.gr --format=csv,noheader,nounits 2>/dev/null)
        v=$(echo "$smi" | awk -F', *' -v s="${slot#0000:}" 'index($1, s) {
          for (i = 2; i <= 7; i++) if ($i !~ /^[0-9.]+$/) $i = -1
          printf "%d %.0f %.0f %.0f %.0f %d", $2, ($3 < 0 ? -1 : $3 * 1048576), ($4 < 0 ? -1 : $4 * 1048576), ($5 < 0 ? -1 : $5 * 1000), ($6 < 0 ? -1 : $6 * 1000000), $7 }')
        [ -n "$v" ] && read -r util vu vt temp pw mhz <<EOF
$v
EOF
      else state=nostats; fi;;
    "") state=nodriver;;
    *) state=nostats;;
  esac
  rank=1
  if [ $kind = discrete ]; then
    rank=0; [ "$rs" = suspended ] && rank=2 state=asleep
  fi
  echo "$rank|gpu|$name|$kind|$drv|$util|$vu|$vt|$temp|$pw|$mhz|$state"
done | sort -t'|' -k1,1n | head -n1 | cut -d'|' -f2-
# Static machine info, "|" separated: model, CPU, OS, kernel, hostname
d=/sys/class/dmi/id
echo "sys|$(cat $d/sys_vendor 2>/dev/null) $(cat $d/product_name 2>/dev/null)|$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo | sed 's/([RTM]*)//g; s/ CPU//; s/  */ /g')|$(nproc)|$(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME")|$(uname -sr)|$(uname -n)"
# One line per mounted partition: parent drive, drive model, drive bytes, partition name (label else device), used, size
df -B1 --output=source,used,size 2>/dev/null | awk 'NR>1 && $1 ~ "^/dev/" && !seen[$1]++' | while read -r src used size; do
  dev=$(basename "$(readlink -f "$src")"); parent=$dev
  [ -e /sys/class/block/$dev/partition ] && parent=$(basename "$(dirname "$(readlink -f /sys/class/block/$dev)")")
  model=$(sed 's/  */ /g; s/ $//' /sys/block/$parent/device/model 2>/dev/null)
  bytes=$(( $(cat /sys/block/$parent/size 2>/dev/null || echo 0) * 512 ))
  name=$(basename "$src")
  for l in /dev/disk/by-label/*; do
    [ -e "$l" ] && [ "$(readlink -f "$l")" = "$(readlink -f "$src")" ] && name=$(basename "$l" | sed 's/\\x20/ /g') && break
  done
  echo "disks|$parent|${model:-$parent}|$bytes|$name|$used|$size"
done
