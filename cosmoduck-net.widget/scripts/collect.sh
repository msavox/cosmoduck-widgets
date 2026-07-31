#!/bin/bash
# Cosmoduck · rete — SSID + down/up.
# Velocità calcolata campionando netstat DUE volte nello stesso run (dt=0.7s):
# nessun file di stato condiviso → sicuro con più monitor (Übersicht esegue il
# widget su ogni schermo, e istanze concorrenti non si corrompono a vicenda).
export LC_ALL=C PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

IFACE=$(route get default 2>/dev/null | awk '/interface:/{print $2}'); [ -z "$IFACE" ] && IFACE="en0"

# --- SSID (macOS 14+: ipconfig getsummary; fallback etichetta porta) ---
ssid=$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F' : ' '/^[[:space:]]+SSID : /{print $2; exit}')
[ -z "$ssid" ] && ssid=$(networksetup -getairportnetwork "$IFACE" 2>/dev/null | awk -F': ' '/Current Wi-Fi Network/{print $2}')
case "$ssid" in ""|*"not associated"*|*"not currently"*|*"Error"*|"<redacted>")
  ssid=$(networksetup -listallhardwareports 2>/dev/null | awk -v i="$IFACE" '/Hardware Port:/{p=$0} $0 ~ "Device: "i" *$"{sub(/Hardware Port: /,"",p); print p; exit}')
  [ -z "$ssid" ] && ssid="$IFACE" ;;
esac
ssid=$(printf '%s' "$ssid" | tr -d '"\\')   # sanitizza per il JSON

# --- velocità: due letture a distanza dt ---
read -r ib1 ob1 < <(netstat -ibn -I "$IFACE" 2>/dev/null | awk 'NR==2{print $7" "$10}')
sleep 0.7
read -r ib2 ob2 < <(netstat -ibn -I "$IFACE" 2>/dev/null | awk 'NR==2{print $7" "$10}')
d=0; u=0
if [ -n "$ib1" ] && [ -n "$ib2" ]; then
  d=$(awk -v a="$ib1" -v b="$ib2" 'BEGIN{x=(b-a)/0.7; if(x<0||x>1e11)x=0; printf "%d", x}')
  u=$(awk -v a="$ob1" -v b="$ob2" 'BEGIN{x=(b-a)/0.7; if(x<0||x>1e11)x=0; printf "%d", x}')
fi
human(){ awk -v b="$1" 'BEGIN{split("B KiB MiB GiB TiB",U," ");i=1;while(b>=1024&&i<5){b/=1024;i++}printf "%.2f %s",b,U[i]}'; }

printf '{"ssid":"%s","down":"%s","up":"%s","dbytes":%d,"ubytes":%d}\n' \
  "$ssid" "$(human "$d")" "$(human "$u")" "$d" "$u"
