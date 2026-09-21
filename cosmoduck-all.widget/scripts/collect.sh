#!/bin/bash
# Cosmoduck · tutto in uno — raccoglie l'uscita dei singoli widget e la fonde.
#
# I collector restano quelli dei widget separati: sono la sola copia del codice,
# e le correzioni fatte li' valgono anche qui. Girano in parallelo perche' in
# fila costerebbero due secondi e mezzo a giro -- da solo quello della rete ne
# vuole uno, che gli serve per misurare il traffico fra due letture.
# Se una cartella non c'e' la sua sezione diventa null, e il widget la salta.
export LC_ALL=C PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/cosmoduck-all.XXXXXX") || { echo '{}'; exit 0; }
trap 'rm -rf "$TMP"' EXIT

run() {
  local name=$1 script=$2
  [ -r "$script" ] || return 0
  ( bash "$script" > "$TMP/$name" 2>/dev/null ) &
}

run sys  "$ROOT/cosmoduck-disk.widget/scripts/collect.sh"
run net  "$ROOT/cosmoduck-net.widget/scripts/collect.sh"
run proc "$ROOT/cosmoduck-proc.widget/scripts/collect.sh"
run hw   "$ROOT/cosmoduck-hw.widget/scripts/collect.sh"
run wx   "$ROOT/cosmoduck-weather.widget/scripts/weather.sh"
run cc   "$ROOT/cosmoduck-cc.widget/scripts/collect.sh"
wait

# Solo JSON valido: un collector interrotto a meta' non deve far saltare tutto.
part() { [ -s "$TMP/$1" ] && /usr/bin/jq -e . "$TMP/$1" >/dev/null 2>&1 && cat "$TMP/$1" || echo null; }

/usr/bin/jq -n \
  --argjson sys  "$(part sys)"  --argjson net  "$(part net)" \
  --argjson proc "$(part proc)" --argjson hw   "$(part hw)"  \
  --argjson wx   "$(part wx)"   --argjson cc   "$(part cc)"  \
  '{sys: $sys, net: $net, proc: $proc, hw: $hw, wx: $wx, cc: $cc}'
