#!/bin/sh
# $1 = comma separated time zone names. Prints "local +HHMM", then "<zone> +HHMM" per zone
echo "local $(date +%z)"
IFS=,
for z in $1; do
  case $z in ""|*[!A-Za-z0-9_+/-]*) continue;; esac
  echo "$z $(TZ=$z date +%z)"
done
