#!/bin/bash
# Cosmoduck · meteo — OpenWeatherMap (Como, id 3178229, IT). Cache 10 min.
# Emette il JSON grezzo di OWM su stdout (parsato in JS).
export LC_ALL=C PATH="/usr/bin:/bin:$PATH"
CITY_ID=3178229
API_KEY=OWM_API_KEY_REMOVED
cache="$HOME/.cache/cosmoduck-weather.json"
mkdir -p "$HOME/.cache"
now=$(date +%s)
mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
if [ ! -s "$cache" ] || [ $(( now - mtime )) -gt 600 ]; then
  curl -sf --max-time 8 \
    "https://api.openweathermap.org/data/2.5/weather?id=${CITY_ID}&appid=${API_KEY}&units=metric&lang=en" \
    -o "$cache.tmp" && mv "$cache.tmp" "$cache"
fi
[ -s "$cache" ] && cat "$cache" || echo "null"
