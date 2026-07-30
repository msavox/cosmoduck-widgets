#!/bin/bash
# Cosmoduck · disco — dati per le 4 ring: CPU, RAM, disco /, disco Data.
export LC_ALL=C PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# uso disco (capacity %) — System = /, Home = volume dati utente
diskRoot=$(df -H / 2>/dev/null | awk 'NR==2{gsub("%","",$5);print $5}')
diskData=$(df -H /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5);print $5}')
[ -z "$diskData" ] && diskData="$diskRoot"

# CPU usata % = 100 - idle (da top)
cpu=$(top -l1 -n0 2>/dev/null | awk -F'[ %]+' '/CPU usage/{print int($3+$5+0.5)}')
[ -z "$cpu" ] && cpu=0

# RAM usata % = 100 - free (da memory_pressure)
free=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2);print $2}')
[ -z "$free" ] && free=0
mem=$(( 100 - free ))
[ "$mem" -lt 0 ] && mem=0

echo "{\"cpu\":${cpu:-0},\"mem\":${mem:-0},\"diskRoot\":${diskRoot:-0},\"diskData\":${diskData:-0}}"
