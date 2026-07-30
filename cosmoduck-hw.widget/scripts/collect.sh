#!/bin/bash
# Cosmoduck · hardware — sensori reali via macmon (sudoless, Apple Silicon).
# macmon legge CPU/GPU die temp + power senza sudo. Installa: brew install macmon
export LC_ALL=C PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if command -v macmon >/dev/null 2>&1; then
  out=$(macmon pipe -s 1 -i 400 2>/dev/null | tail -1)
  if [ -n "$out" ]; then
    echo "$out" | /usr/bin/jq -c '{
      cputemp: .temp.cpu_temp_avg,
      gputemp: .temp.gpu_temp_avg,
      cpupwr:  .cpu_power,
      gpupwr:  .gpu_power,
      syspwr:  .sys_power
    }'
    exit 0
  fi
fi
# macmon assente o nessun output
echo '{"cputemp":null,"gputemp":null,"cpupwr":null,"gpupwr":null,"syspwr":null,"nomacmon":true}'
