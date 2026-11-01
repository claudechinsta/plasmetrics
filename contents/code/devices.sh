#!/bin/sh
# One line per device: "bat|name|model|capacity" and "net|name|state"
for b in /sys/class/power_supply/*; do
  [ "$(cat $b/type 2>/dev/null)" = Battery ] || continue
  echo "bat|$(basename $b)|$(cat $b/model_name 2>/dev/null)|$(cat $b/capacity 2>/dev/null)"
done
for n in /sys/class/net/*; do
  [ "$(basename $n)" = lo ] && continue
  echo "net|$(basename $n)|$(cat $n/operstate 2>/dev/null)"
done
