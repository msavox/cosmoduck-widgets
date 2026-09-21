#!/bin/bash
# Cosmoduck · hardware — sensori reali via macmon (sudoless, Apple Silicon).
# macmon legge CPU/GPU die temp + power senza sudo. Installa: brew install macmon
export LC_ALL=C PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# La batteria non passa da macmon: pmset c'e' su ogni Mac e non vuole permessi.
# La riga utile e' la seconda:
#   -InternalBattery-0 (id=...)  33%; charging; 3:14 remaining present: true
# dove lo stato e' charging / discharging / charged / AC attached, e la stima
# manca del tutto ("(no estimate)") nei minuti dopo che attacchi la spina.
# pmset scrive "(no estimate)" nei minuti dopo che attacchi o stacchi la spina,
# e ogni tanto anche a regime: e' il momento in cui la stima serve di piu' e non
# c'e'. Il dato pero' vive nel registro IO, in tre campi diversi, e vanno letti
# tutti e tre perche' a turno valgono 65535, che e' il sentinella dello
# sconosciuto. Una sola chiamata a ioreg, e solo quando pmset ha rinunciato.
registry_mins() {
  local state=$1 reg tr tte ttf
  reg=$(ioreg -rn AppleSmartBattery 2>/dev/null) || { echo null; return; }
  pick() { printf '%s\n' "$reg" | grep -oE "\"$1\" = [0-9]+" | head -1 | grep -oE '[0-9]+$'; }
  valid() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -ge 1 ] && [ "$1" -le 1440 ]; }
  tr=$(pick TimeRemaining); tte=$(pick AvgTimeToEmpty); ttf=$(pick AvgTimeToFull)
  if   valid "$tr";                                then echo "$tr"; return
  elif [ "$state" = discharging ] && valid "$tte"; then echo "$tte"; return
  elif [ "$state" = charging ]    && valid "$ttf"; then echo "$ttf"; return
  fi
  # Anche i tre campi vanno e vengono: passano a 65535 per qualche giro e poi
  # tornano, e la stima a schermo lampeggiava di conseguenza. Ma i mAh che
  # restano e la corrente che scorre ci sono sempre, e la divisione la sappiamo
  # fare: sotto i 200 mA pero' non si sta ne' caricando ne' scaricando davvero
  # -- e' la carica in pausa -- e un rapporto del genere darebbe giorni.
  local rem full amp
  rem=$(printf '%s\n' "$reg"  | grep -o '"RemainingCapacity"=[0-9]*'   | head -1 | grep -oE '[0-9]+$')
  full=$(printf '%s\n' "$reg" | grep -o '"FullChargeCapacity"=[0-9]*'  | head -1 | grep -oE '[0-9]+$')
  amp=$(printf '%s\n' "$reg"  | grep -oE '"Amperage" = -?[0-9]+'       | head -1 | grep -oE '\-?[0-9]+$')
  case "$rem$full$amp" in ''|*[!0-9-]*) echo null; return ;; esac
  [ "$amp" -lt 0 ] && amp=$(( -amp ))
  [ "$amp" -lt 200 ] && { echo null; return; }
  if [ "$state" = charging ] && [ "$full" -gt "$rem" ]; then
    mins=$(( (full - rem) * 60 / amp ))
  elif [ "$state" = discharging ]; then
    mins=$(( rem * 60 / amp ))
  else
    echo null; return
  fi
  valid "$mins" && echo "$mins" || echo null
}

battery_json() {
  local line pct state hhmm mins ac
  line=$(pmset -g batt 2>/dev/null)
  [ -z "$line" ] && { echo null; return; }
  case "$line" in *"'AC Power'"*) ac=true ;; *) ac=false ;; esac
  line=$(printf '%s\n' "$line" | sed -n '2p')
  pct=$(printf '%s\n' "$line" | grep -o '[0-9]\{1,3\}%' | head -1 | tr -d '%')
  [ -z "$pct" ] && { echo null; return; }
  state=$(printf '%s\n' "$line" | awk -F';' 'NF>1 { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }')
  hhmm=$(printf '%s\n' "$line" | grep -o '[0-9]\{1,2\}:[0-9][0-9]' | head -1)
  if [ -n "$hhmm" ]; then
    mins=$(( ${hhmm%%:*} * 60 + 10#${hhmm##*:} ))
  else
    mins=$(registry_mins "$state")
  fi
  printf '{"pct":%s,"state":"%s","mins":%s,"ac":%s}' "$pct" "${state:-unknown}" "$mins" "$ac"
}
BATT=$(battery_json)

if command -v macmon >/dev/null 2>&1; then
  out=$(macmon pipe -s 1 -i 400 2>/dev/null | tail -1)
  if [ -n "$out" ]; then
    echo "$out" | /usr/bin/jq -c --argjson batt "$BATT" '{
      cputemp: .temp.cpu_temp_avg,
      gputemp: .temp.gpu_temp_avg,
      cpupwr:  .cpu_power,
      gpupwr:  .gpu_power,
      syspwr:  .sys_power,
      batt:    $batt
    }'
    exit 0
  fi
fi
# macmon assente o nessun output: la batteria pero' si legge lo stesso.
printf '{"cputemp":null,"gputemp":null,"cpupwr":null,"gpupwr":null,"syspwr":null,"nomacmon":true,"batt":%s}\n' "$BATT"
