#!/bin/bash
# Cosmoduck · statusline per Claude Code.
# Doppio scopo:
#  1) stampa una riga di stato (modello, cartella, branch, limiti, contesto, costo);
#  2) mette in cache il blocco rate_limits, cosi' il widget cosmoduck-cc puo' mostrare
#     percentuali e orari di reset VERI invece di stimarli su budget manuali.
#
# rate_limits e' presente solo per gli abbonati Claude.ai (Pro/Max) e solo dopo la
# prima risposta API della sessione: fuori da quei casi la cache non viene toccata e
# il widget ricade sulla stima locale.
#
# Configurato in ~/.claude/settings.json come "statusLine".
export LC_ALL=C PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Quali sessioni possono scrivere la cache dei limiti. Anche Claude Code lanciato
# dall'app desktop usa ~/.claude, quindi esegue QUESTA statusline: se lo si lascia
# fare, la sua quota finisce nel widget al posto di quella del terminale (e con un
# account diverso, se i due login non coincidono). I limiti sono per-account, la
# cache e' un file solo: senza filtro vince l'ultima sessione che renderizza.
CACHE_ENTRYPOINTS=${CACHE_ENTRYPOINTS-cli}

CACHE="$HOME/.claude/cosmoduck-ratelimits.json"
input=$(cat)

# ── 1. cache dei limiti reali ─────────────────────────────────────────────────
# L'entrypoint non e' nell'input della statusline, ma e' su quasi ogni record del
# transcript (dalla terza riga in poi), e il transcript ce lo dice l'input.
ENTRY=""
TRANSCRIPT=$(printf '%s' "$input" | /usr/bin/jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  ENTRY=$(head -n 40 "$TRANSCRIPT" 2>/dev/null |
    /usr/bin/jq -r 'select(type == "object" and .entrypoint != null) | .entrypoint' 2>/dev/null |
    head -n 1)
fi

# Entrypoint sconosciuto (sessione appena nata, formato cambiato) = non si scrive:
# meglio un dato vecchio, che il widget marca, che uno dell'account sbagliato.
case " $CACHE_ENTRYPOINTS " in
  *" $ENTRY "*) MAY_CACHE=1 ;;
  *)            MAY_CACHE=0 ;;
esac

# Scrittura atomica (tmp + mv): il widget legge ogni 60s e non deve mai vedere
# un file troncato a meta'.
if [ "$MAY_CACHE" = 1 ]; then
printf '%s' "$input" | /usr/bin/jq -c --argjson now "$(date +%s)" --arg entry "$ENTRY" '
  if (.rate_limits // empty) then
    {captured_at: $now, entrypoint: $entry, rate_limits: .rate_limits}
  else empty end
' > "$CACHE.tmp" 2>/dev/null
fi

if [ -s "$CACHE.tmp" ]; then
  mv -f "$CACHE.tmp" "$CACHE"
else
  rm -f "$CACHE.tmp"
fi

# ── 2. riga di stato ──────────────────────────────────────────────────────────
DIM='\033[2m'; CYAN='\033[36m'; BLUE='\033[34m'; GREEN='\033[32m'
YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

vars=$(printf '%s' "$input" | /usr/bin/jq -r '
  def q: @sh;
  "MODEL=" + ((.model.display_name // "Claude") | q),
  "DIR="   + ((.workspace.current_dir // .cwd // "") | q),
  "EFFORT=" + ((.effort.level // "") | q),
  "CTX="   + ((.context_window.used_percentage // empty | round | tostring) // "" | q),
  "COST="  + ((.cost.total_cost_usd // empty | tostring) // "" | q),
  "H5="    + ((.rate_limits.five_hour.used_percentage // empty | round | tostring) // "" | q),
  "D7="    + ((.rate_limits.seven_day.used_percentage // empty | round | tostring) // "" | q)
' 2>/dev/null) || exit 0
[ -n "$vars" ] || exit 0
eval "$vars"

BRANCH=""
if [ -n "$DIR" ] && [ -d "$DIR" ]; then
  b=$(cd "$DIR" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$b" ] && [ "$b" != "HEAD" ] && BRANCH="  ${b}"
fi

# colore per percentuale: verde < 80, giallo < 92, rosso oltre
tone() {
  [ -z "$1" ] && return
  if   [ "$1" -ge 92 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 80 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

EFF=""
[ -n "$EFFORT" ] && EFF=" ${EFFORT}"

printf "%b[%s%b%s%b]%b %b%s%b%b%s%b\n" \
  "$CYAN" "$MODEL" "$DIM" "$EFF" "$CYAN" "$RESET" \
  "$BLUE" "${DIR/#$HOME/~}" "$RESET" "$DIM" "$BRANCH" "$RESET"

line=""
[ -n "$H5"  ] && line="$line$(tone "$H5")5h ${H5}%${RESET}"
[ -n "$D7"  ] && { [ -n "$line" ] && line="$line${DIM} · ${RESET}"; line="$line$(tone "$D7")7d ${D7}%${RESET}"; }
[ -n "$CTX" ] && { [ -n "$line" ] && line="$line${DIM} · ${RESET}"; line="$line${DIM}ctx ${CTX}%${RESET}"; }
[ -n "$COST" ] && { [ -n "$line" ] && line="$line${DIM} · ${RESET}"; line="$line${DIM}$(printf '$%.2f' "$COST")${RESET}"; }
[ -n "$line" ] && printf "%b\n" "$line"
