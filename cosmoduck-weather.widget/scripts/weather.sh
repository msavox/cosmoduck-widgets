#!/bin/bash
# Cosmoduck · meteo — OpenWeatherMap (Como, id 3178229).
# Emette su stdout { current: <meteo ora>, forecast: [5 giorni] }.
# Le due chiamate hanno cache separate: il meteo corrente invecchia in 10
# minuti, le previsioni in un'ora — cambiano molto piu' lentamente e non vale
# la pena spendere una chiamata ogni volta.
# Multi-monitor safe: temp file UNICO per processo + validazione JSON prima di
# sostituire la cache (Übersicht esegue il widget su ogni schermo → istanze
# concorrenti non devono corrompersi la cache a vicenda).
export LC_ALL=C PATH="/usr/bin:/bin:$PATH"

# ─── configurazione ────────────────────────────────────────────────────────────
# La chiave NON sta nel repo: questi widget si distribuiscono pubblicamente, e una
# chiave committata resta nella history anche dopo averla tolta. Mettila in
# ~/.config/cosmoduck/weather.env (chmod 600):
#     OWM_API_KEY=la-tua-chiave
# oppure esportala nell'ambiente. Chiave gratuita: https://openweathermap.org/api
# CITY_ID: cerca la tua citta' su openweathermap.org, l'id e' nell'URL.
CITY_ID=${CITY_ID:-3178229}
CONF="${COSMODUCK_WEATHER_CONF:-$HOME/.config/cosmoduck/weather.env}"
[ -z "$OWM_API_KEY" ] && [ -r "$CONF" ] && . "$CONF"
API_KEY=$OWM_API_KEY
# ───────────────────────────────────────────────────────────────────────────────

CACHE_NOW="$HOME/.cache/cosmoduck-weather.json"
CACHE_FC="$HOME/.cache/cosmoduck-forecast.json"
mkdir -p "$HOME/.cache"

# Le voci delle previsioni sono ogni 3 ore in UTC: si raggruppano per data
# LOCALE (dt + offset della citta'), e di ogni giorno restano minima, massima e
# l'icona di meta' giornata, che e' quella che lo descrive a colpo d'occhio.
# L'aggregazione si fa qui e non nella cache, cosi' il confine fra i giorni
# resta giusto anche se la cache e' di un'ora fa.
AGG='
(.city.timezone // 0) as $tz
| ((now + $tz) | gmtime | strftime("%Y-%m-%d")) as $today
| [ .list[] | {
      d:    ((.dt + $tz) | gmtime | strftime("%Y-%m-%d")),
      dow:  ((.dt + $tz) | gmtime | strftime("%a")),
      h:    (((.dt + $tz) | gmtime | strftime("%H")) | tonumber),
      tmin: .main.temp_min, tmax: .main.temp_max,
      icon: .weather[0].icon
    } ]
| group_by(.d)
| def day: {
      dow:  .[0].dow,
      min:  (map(.tmin) | min | round),
      max:  (map(.tmax) | max | round),
      icon: ( (map(select(.h >= 11 and .h <= 14)) | .[0]) // (. | sort_by(.h) | .[(length/2) | floor]) ).icon
    };
  { today: ( map(select(.[0].d == $today)) | if length > 0 then (.[0] | day) else null end ),
    days:  ( map(select(.[0].d > $today)) | map(day) | .[0:5] ) }'

# scarica in cache se manca o e' vecchia:  fetch <url> <cache> <eta-max> <test-jq>
fetch() {
  local url=$1 cache=$2 maxage=$3 test=$4
  local now mtime tmp
  now=$(date +%s)
  mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  [ -s "$cache" ] && [ $(( now - mtime )) -le "$maxage" ] && return 0
  tmp="$cache.$$.tmp"       # unico per processo → niente collisioni fra istanze
  if curl -sf --max-time 8 "$url" -o "$tmp"; then
    # sostituisci la cache solo se il download e' JSON valido e completo
    if /usr/bin/jq -e "$test" "$tmp" >/dev/null 2>&1; then
      mv -f "$tmp" "$cache"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

if [ -n "$API_KEY" ]; then
  BASE="https://api.openweathermap.org/data/2.5"
  Q="id=${CITY_ID}&appid=${API_KEY}&units=metric&lang=en"
  fetch "$BASE/weather?$Q"  "$CACHE_NOW" 600  '.main.temp'
  fetch "$BASE/forecast?$Q" "$CACHE_FC"  3600 '.list|length > 0'
fi

# Senza chiave, o con la rete giu', si serve quello che c'e' in cache; se non
# c'e' niente, "null", che il widget gia' gestisce lasciando i segnaposto.
if ! /usr/bin/jq -e '.main.temp' "$CACHE_NOW" >/dev/null 2>&1; then
  echo "null"
  exit 0
fi
if /usr/bin/jq -e '.list|length > 0' "$CACHE_FC" >/dev/null 2>&1; then
  # today: le previsioni coprono solo le ore che restano, quindi la minima del
  # giorno ci si mette dentro solo se deve ancora arrivare. Per non mentire, si
  # tiene anche la temperatura di adesso fra i candidati: cosi' "min" e' la piu'
  # bassa fra quella attuale e quelle previste fino a mezzanotte.
  /usr/bin/jq -n --slurpfile cur "$CACHE_NOW" --slurpfile fc "$CACHE_FC" \
    "(\$fc[0] | $AGG) as \$f
     | (\$cur[0].main.temp | round) as \$now
     | { current:  \$cur[0],
         today:    (if \$f.today
                    then { min: ([\$f.today.min, \$now] | min), max: ([\$f.today.max, \$now] | max) }
                    else { min: \$now, max: \$now } end),
         forecast: \$f.days }"
else
  # Senza previsioni in cache si emette solo il meteo corrente: "oggi" diventa
  # la temperatura di adesso, e il widget resta senza striscia.
  /usr/bin/jq -n --slurpfile cur "$CACHE_NOW" \
    '($cur[0].main.temp | round) as $now
     | { current: $cur[0], today: { min: $now, max: $now }, forecast: [] }'
fi
