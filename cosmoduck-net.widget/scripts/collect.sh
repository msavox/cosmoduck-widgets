#!/bin/bash
# Cosmoduck · rete — SSID + down/up (delta netstat) + storico per sparkline.
export LC_ALL=C PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
IFACE=$(route get default 2>/dev/null | awk '/interface:/{print $2}'); [ -z "$IFACE" ] && IFACE="en0"
CACHE="$HOME/.cache"; mkdir -p "$CACHE"
state="$CACHE/cosmoduck-net.state"
histD="$CACHE/cosmoduck-net.dhist"
histU="$CACHE/cosmoduck-net.uhist"

# SSID — su macOS 14+ networksetup viene oscurato: prima ipconfig getsummary
# (funziona anche su Sequoia), poi networksetup. macOS restituisce il letterale
# "<redacted>" se manca il permesso Localizzazione all'app chiamante (Übersicht):
# in quel caso si ripiega sull'etichetta della porta hardware (es. "Wi-Fi").
ssid=$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F' : ' '/^[[:space:]]+SSID : /{print $2; exit}')
[ -z "$ssid" ] && ssid=$(networksetup -getairportnetwork "$IFACE" 2>/dev/null | awk -F': ' '/Current Wi-Fi Network/{print $2}')
case "$ssid" in ""|*"not associated"*|*"not currently"*|*"Error"*|"<redacted>")
  ssid=$(networksetup -listallhardwareports 2>/dev/null | awk -v i="$IFACE" '/Hardware Port:/{p=$0} $0 ~ "Device: "i" *$"{sub(/Hardware Port: /,"",p); print p; exit}')
  [ -z "$ssid" ] && ssid="$IFACE"
esac

read -r ib ob < <(netstat -ibn -I "$IFACE" 2>/dev/null | awk 'NR==2{print $7" "$10}')
now=$(date +%s)
dspeed=0; uspeed=0
if [ -f "$state" ] && [ -n "$ib" ]; then
  read -r pib pob pt < "$state"
  dt=$(( now - pt )); [ "$dt" -le 0 ] && dt=1
  dspeed=$(( (ib - pib) / dt )); [ "$dspeed" -lt 0 ] && dspeed=0
  uspeed=$(( (ob - pob) / dt )); [ "$uspeed" -lt 0 ] && uspeed=0
fi
[ -n "$ib" ] && echo "$ib $ob $now" > "$state"

human() { awk -v b="$1" 'BEGIN{split("B KiB MiB GiB",u," ");i=1;while(b>=1024&&i<4){b/=1024;i++}printf "%.2f %s",b,u[i]}'; }
downH=$(human "$dspeed"); upH=$(human "$uspeed")

# storico (ultimi 40 campioni) per sparkline
push() { echo "$2" >> "$1"; tail -n 40 "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }
push "$histD" "$dspeed"; push "$histU" "$uspeed"
arrD=$(paste -sd, "$histD" 2>/dev/null); arrU=$(paste -sd, "$histU" 2>/dev/null)

echo "{\"ssid\":\"${ssid}\",\"down\":\"${downH}\",\"up\":\"${upH}\",\"dhist\":[${arrD:-0}],\"uhist\":[${arrU:-0}]}"
