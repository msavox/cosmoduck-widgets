#!/bin/bash
# Cosmoduck · tema — ridistribuisce il tema a tutti i widget del set.
#
# Ogni widget si porta dietro la sua copia del tema, perche' si installano uno
# per uno e nessuno puo' contare sulla cartella di un altro. Le copie sono tre:
#   scripts/theme.sh      trova il wallpaper e tiene la cache
#   scripts/palette.jxa   lo analizza
#   il blocco fra "# ▼ cosmoduck-theme" e "# ▲ cosmoduck-theme" in index.coffee:
#                         compone i colori e disegna il retro
# Quelle buone stanno qui, in theme/. Si modificano qui e poi si lancia questo
# script, che le ricopia in ogni cartella *.widget che ha i due marcatori.
#
#   theme/sync.sh           ricopia
#   theme/sync.sh --check   non tocca niente, e dice (exit 1) chi e' rimasto indietro
export LC_ALL=C
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/theme"
BLOCK="$SRC/widget-block.coffee.in"
CHECK=0
[ "$1" = "--check" ] && CHECK=1

# Il blocco del widget sostituito con quello buono, su stdout.
splice() {
  awk -v blk="$BLOCK" '
    /^# ▼ cosmoduck-theme/ { while ((getline l < blk) > 0) print l; close(blk); skip = 1; next }
    /^# ▲ cosmoduck-theme/ { skip = 0; next }
    !skip
  ' "$1"
}

stale=0
for w in "$ROOT"/*.widget; do
  f="$w/index.coffee"
  name=$(basename "$w")
  if ! grep -q '^# ▼ cosmoduck-theme' "$f" 2>/dev/null; then
    echo "  --  $name (senza marcatori, saltato)"
    continue
  fi
  if [ $CHECK = 1 ]; then
    same=1
    splice "$f" | cmp -s - "$f" || same=0
    cmp -s "$SRC/theme.sh" "$w/scripts/theme.sh" || same=0
    cmp -s "$SRC/palette.jxa" "$w/scripts/palette.jxa" || same=0
    if [ $same = 1 ]; then echo "  ok  $name"; else echo "  !!  $name"; stale=1; fi
    continue
  fi
  mkdir -p "$w/scripts"
  cp "$SRC/theme.sh" "$SRC/palette.jxa" "$w/scripts/"
  splice "$f" > "$f.sync" && mv "$f.sync" "$f"
  echo "  ok  $name"
done
exit $stale
