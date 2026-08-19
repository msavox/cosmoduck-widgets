#!/bin/bash
# Cosmoduck · meteo — OpenWeatherMap (Como, id 3178229). Cache 10 min.
# Emette il JSON grezzo di OWM su stdout (parsato in JS).
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

# Senza chiave non si chiama l'API: si serve la cache se c'e' ancora, altrimenti
# "null", che il widget gia' gestisce lasciando i segnaposto.
if [ -z "$API_KEY" ]; then
  if /usr/bin/jq -e '.main.temp' "$HOME/.cache/cosmoduck-weather.json" >/dev/null 2>&1; then
    cat "$HOME/.cache/cosmoduck-weather.json"
  else
    echo "null"
  fi
  exit 0
fi

cache="$HOME/.cache/cosmoduck-weather.json"
mkdir -p "$HOME/.cache"
now=$(date +%s)
mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)

if [ ! -s "$cache" ] || [ $(( now - mtime )) -gt 600 ]; then
  tmp="$cache.$$.tmp"   # unico per processo → niente collisioni fra istanze
  if curl -sf --max-time 8 \
      "https://api.openweathermap.org/data/2.5/weather?id=${CITY_ID}&appid=${API_KEY}&units=metric&lang=en" \
      -o "$tmp"; then
    # sostituisci la cache solo se il download è JSON valido con la temperatura
    if /usr/bin/jq -e '.main.temp' "$tmp" >/dev/null 2>&1; then
      mv -f "$tmp" "$cache"
    else
      rm -f "$tmp"
    fi
  else
    rm -f "$tmp"
  fi
fi

# Emetti solo JSON valido (mai una cache mezza scritta)
if /usr/bin/jq -e '.main.temp' "$cache" >/dev/null 2>&1; then
  cat "$cache"
else
  echo "null"
fi
