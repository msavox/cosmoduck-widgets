#!/bin/bash
# Cosmoduck · tema — trova il wallpaper in uso e ne deriva la palette.
# Emette su stdout il JSON di palette.jxa (o niente, se qualcosa non torna: il
# widget tiene allora l'ultima palette buona, e sotto c'e' comunque il colore
# originale come fallback CSS).
export LC_ALL=C PATH="/usr/bin:/bin:$PATH"

# ─── configurazione ────────────────────────────────────────────────────────────
# BLEND     quanto il wallpaper detta il colore: 1 = tinta adottata in pieno,
#           0.3 = il blu Cosmoduck spostato di poco, 0 = tema originale intatto.
# SAT_FLOOR pavimento della saturazione, in frazione di quella originale. Senza,
#           un wallpaper slavato produce widget grigiastri e illeggibili.
# VIVIDNESS come si sceglie fra le tinte presenti: 0 = vince quella piu' estesa,
#           1.5 = il colore carico batte il fondo smorto anche se piccolo,
#           3 = basta una macchia accesa per dettare il tema.
# TWO_TONE  wallpaper piatto con dentro qualche macchia accesa (un logo, una
#           lampada): 1 = i pannelli prendono la tinta del fondo e l'accento la
#           macchia, com'e' composto il wallpaper stesso; 0 = una tinta sola.
BLEND=${COSMODUCK_THEME_BLEND:-1.0}
SAT_FLOOR=${COSMODUCK_THEME_SAT_FLOOR:-0.75}
VIVIDNESS=${COSMODUCK_THEME_VIVIDNESS:-1.5}
TWO_TONE=${COSMODUCK_THEME_TWO_TONE:-1}
# ───────────────────────────────────────────────────────────────────────────────

# NB: lo script JXA si chiama .jxa, non .js, e non e' un vezzo. Ubersicht
# carica come widget ogni .js/.jsx/.coffee che trovi sotto la sua cartella
# (server.js: /\.coffee$|\.js$|\.jsx$/), quindi un palette.js finirebbe nel
# parser dei widget e comparirebbe a schermo come errore di sintassi.
DIR=$(cd "$(dirname "$0")" && pwd)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cosmoduck"
CACHE="$CACHE_DIR/theme.json"
CACHE_KEY="$CACHE_DIR/theme.key"
LOG="$CACHE_DIR/theme.log"
mkdir -p "$CACHE_DIR" 2>/dev/null

# Ubersicht considera in errore un widget il cui comando scriva un solo byte su
# stderr. Qui stderr deve restare vuoto in ogni caso, quindi i guai si
# raccontano nel log e si esce comunque con 0.
note() { printf '%s  %s\n' "$(date '+%F %T')" "$*" >> "$LOG" 2>/dev/null; }
give_up() { note "$*"; exit 0; }

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
    | tr -cs '[:print:]' '\n' | grep -o 'file:///[^"]*' | head -1
}

# Ripiego: chiede al Finder. Esatto, ma la prima volta fa comparire il prompt
# "Ubersicht vuole controllare System Events".
wallpaper_from_applescript() {
  osascript -e 'tell application "System Events" to tell current desktop to get picture as text' 2>/dev/null
}

urldecode() { local s="${1//+/ }"; printf '%b' "${s//%/\\x}"; }

SRC=$(wallpaper_from_store 2>>"$LOG")
[ -z "$SRC" ] && SRC=$(wallpaper_from_applescript)
[ -z "$SRC" ] && give_up "wallpaper non trovato: ne' nel registro di macOS ne' via System Events"

case "$SRC" in
  file://*) FILE=$(urldecode "${SRC#file://}") ;;
  *)        FILE=$SRC ;;
esac
# Due guai diversi che si somigliano. Il file puo' non esserci piu': il registro
# di macOS conserva il percorso di quando l'hai impostato, e se poi lo sposti o
# lo cancelli resta li' a puntare al vuoto. Oppure c'e' ma non si legge, ed e'
# il caso dei permessi mancanti su quella cartella. Distinguerli serve, perche'
# la cura e' diversa: reimpostare lo sfondo nel primo caso, dare il permesso a
# Ubersicht nel secondo.
if [ ! -e "$FILE" ]; then
  give_up "wallpaper sparito dal disco: $FILE (spostato o cancellato dopo essere stato impostato; reimposta lo sfondo)"
elif [ ! -r "$FILE" ]; then
  give_up "wallpaper non leggibile: $FILE (permessi di Ubersicht su quella cartella?)"
fi

# Decodificare il wallpaper costa un paio di decimi e non cambia finche' non
# cambia lui: si ricalcola solo quando path, mtime o taratura si muovono.
# Nella chiave c'e' anche l'mtime dell'estrattore: se non ci fosse, aggiornare
# il widget lascerebbe a schermo la palette calcolata dalla versione precedente
# finche' non cambia il wallpaper.
KEY="$FILE|$(stat -f %m "$FILE" 2>/dev/null)|$(stat -f %m "$DIR/palette.jxa" 2>/dev/null)|$BLEND|$SAT_FLOOR|$VIVIDNESS|$TWO_TONE"
if [ -r "$CACHE" ] && [ -r "$CACHE_KEY" ] && [ "$(cat "$CACHE_KEY")" = "$KEY" ]; then
  cat "$CACHE"
  exit 0
fi

JSON=$(osascript -l JavaScript "$DIR/palette.jxa" "$SRC" "$BLEND" "$SAT_FLOOR" "$VIVIDNESS" "$TWO_TONE" 2>>"$LOG")
case "$JSON" in
  \{*\}) ;;
  *) give_up "palette.jxa non ha prodotto JSON (vedi le righe qui sopra)" ;;
esac
# Temp file per processo: Ubersicht gira il widget su ogni schermo, e due
# istanze non devono sovrascriversi la cache a meta' scrittura.
TMP="$CACHE.$$"
printf '%s\n' "$JSON" > "$TMP" && mv -f "$TMP" "$CACHE"
printf '%s' "$KEY" > "$CACHE_KEY.$$" && mv -f "$CACHE_KEY.$$" "$CACHE_KEY"
printf '%s\n' "$JSON"
