#!/bin/sh
# One line per temperature sensor: key|label|millidegrees (key is "<hwmon name>/<tempN>@<device>")
for h in /sys/class/hwmon/hwmon*; do
  n=$(cat "$h/name" 2>/dev/null)
  for f in "$h"/temp*_input; do
    [ -r "$f" ] || continue
    b=${f%_input}
    echo "$n/$(basename "$b")@$(basename "$(readlink -f "$h/device" 2>/dev/null)")|$(cat "${b}_label" 2>/dev/null)|$(cat "$f" 2>/dev/null)"
  done
done
