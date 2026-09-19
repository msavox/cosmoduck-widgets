#!/bin/bash
# Cosmoduck · tema — trova il wallpaper in uso e ne deriva la palette.
# Emette su stdout il JSON di palette.js (o niente, se qualcosa non torna: il
# widget tiene allora l'ultima palette buona, e sotto c'e' comunque il colore
# originale come fallback CSS).
export LC_ALL=C PATH="/usr/bin:/bin:$PATH"

# ─── configurazione ────────────────────────────────────────────────────────────
# BLEND     quanto il wallpaper detta il colore: 1 = tinta adottata in pieno,
#           0.3 = il blu Cosmoduck spostato di poco, 0 = tema originale intatto.
# SAT_FLOOR pavimento della saturazione, in frazione di quella originale. Senza,
#           un wallpaper slavato produce widget grigiastri e illeggibili.
BLEND=${COSMODUCK_THEME_BLEND:-1.0}
SAT_FLOOR=${COSMODUCK_THEME_SAT_FLOOR:-0.75}
# ───────────────────────────────────────────────────────────────────────────────

DIR=$(cd "$(dirname "$0")" && pwd)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cosmoduck"
CACHE="$CACHE_DIR/theme.json"
CACHE_KEY="$CACHE_DIR/theme.key"

# Il wallpaper dal registro di macOS: nessun permesso da concedere, a differenza
# di System Events. Le voci sono una per display e per spazio, molte storiche,
# quindi si prende quella usata piu' di recente. Il path sta dentro un plist
# binario annidato in un <data>, percent-encoded.
wallpaper_from_store() {
  local idx="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
  [ -r "$idx" ] || return 1
  plutil -convert xml1 -o - "$idx" 2>/dev/null | awk '
    /<key>Desktop<\/key>/       { sec=1; b=""; d=""; conf=0; next }
    /<key>Idle<\/key>/          { if (sec && b != "" && d != "") print d "\t" b; sec=0; next }
    !sec                        { next }
    /<key>Configuration<\/key>/ { conf=1; next }
    /<key>LastUse<\/key>/       { want=1; next }
    want && /<date>/            { gsub(/.*<date>|<\/date>.*/,""); d=$0; want=0; next }
    conf && /<\/data>/          { conf=0; next }
    conf                        { gsub(/[ \t<>]/,""); if ($0 != "data") b = b $0 }
  ' | sort -r | head -1 | cut -f2 | base64 -d 2>/dev/null \
    | strings -n 8 | grep -o 'file:///[^"]*' | head -1
}

# Ripiego: chiede al Finder. Esatto, ma la prima volta fa comparire il prompt
# "Ubersicht vuole controllare System Events".
wallpaper_from_applescript() {
  osascript -e 'tell application "System Events" to tell current desktop to get picture as text' 2>/dev/null
}

urldecode() { local s="${1//+/ }"; printf '%b' "${s//%/\\x}"; }

SRC=$(wallpaper_from_store)
[ -z "$SRC" ] && SRC=$(wallpaper_from_applescript)
[ -z "$SRC" ] && exit 0

case "$SRC" in
  file://*) FILE=$(urldecode "${SRC#file://}") ;;
  *)        FILE=$SRC ;;
esac
[ -r "$FILE" ] || exit 0

# Decodificare il wallpaper costa mezzo secondo e non cambia finche' non cambia
# lui: si ricalcola solo quando path, mtime o taratura si muovono.
KEY="$FILE|$(stat -f %m "$FILE" 2>/dev/null)|$BLEND|$SAT_FLOOR"
if [ -r "$CACHE" ] && [ -r "$CACHE_KEY" ] && [ "$(cat "$CACHE_KEY")" = "$KEY" ]; then
  cat "$CACHE"
  exit 0
fi

JSON=$(osascript -l JavaScript "$DIR/palette.js" "$SRC" "$BLEND" "$SAT_FLOOR" 2>/dev/null)
case "$JSON" in
  \{*\}) ;;
  *) exit 0 ;;
esac

mkdir -p "$CACHE_DIR"
# Temp file per processo: Ubersicht gira il widget su ogni schermo, e due
# istanze non devono sovrascriversi la cache a meta' scrittura.
TMP="$CACHE.$$"
printf '%s\n' "$JSON" > "$TMP" && mv -f "$TMP" "$CACHE"
printf '%s' "$KEY" > "$CACHE_KEY.$$" && mv -f "$CACHE_KEY.$$" "$CACHE_KEY"
printf '%s\n' "$JSON"
