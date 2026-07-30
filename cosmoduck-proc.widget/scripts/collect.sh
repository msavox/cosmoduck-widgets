#!/bin/bash
# Cosmoduck · processi — top 3 CPU e top 3 RAM (ps BSD).
export LC_ALL=C PATH="/usr/bin:/bin:$PATH"
topcpu=$(ps -Aceo pcpu,comm -r 2>/dev/null | awk 'NR>=2 && NR<=4 {name=$2; for(i=3;i<=NF;i++) name=name" "$i; printf "%s{\"n\":\"%s\",\"p\":\"%.1f\"}", (NR>2?",":""), substr(name,1,10), $1}')
topram=$(ps -Aceo pmem,comm -m 2>/dev/null | awk 'NR>=2 && NR<=4 {name=$2; for(i=3;i<=NF;i++) name=name" "$i; printf "%s{\"n\":\"%s\",\"p\":\"%.1f\"}", (NR>2?",":""), substr(name,1,10), $1}')
echo "{\"topcpu\":[${topcpu}],\"topram\":[${topram}]}"
