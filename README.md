# Cosmoduck Widgets for Übersicht

A blue, monospaced-glass widget set for macOS — a faithful port of the **Regulus Dark / Cosmoduck** Conky theme (Linux) to [Übersicht](https://tracesof.net/uebersicht/). Big two‑layer clock, ring gauges, weather, network, processes and **real Apple‑Silicon sensors**, all on a subtle frosted‑glass panel.

Made for a MacBook Air M‑series, tuned on a notch display.

## Preview
![Preview](preview.png?v=2)

## Features
- **Frosted glass** — translucent tinted panels with `backdrop-filter` blur, thin blue border and inner highlight. The blur picks up your wallpaper.
- **Draggable & lockable** — click‑drag any widget to reposition; each has a small monochrome lock icon (shown on hover) to freeze it. Positions and lock state persist across reboots and refreshes (via `localStorage`).
- **Real sensors on Apple Silicon** — CPU/GPU die temperature and power draw via [`macmon`](https://github.com/vladkens/macmon) (no `sudo`).
- **Two‑layer clock** — large Bebas Neue digits with the original Cosmoduck colour‑inversion between hours and minutes.
- **Ring gauges** — CPU, RAM and disk usage as arcs around chip/CPU glyphs, with a legend showing CPU load plus free RAM and free disk space.

## Installation
1. **[Download `cosmoduck-widgets.zip`](https://github.com/msavox/cosmoduck-widgets/raw/main/cosmoduck-widgets.zip)**
2. Unzip it into your Übersicht widgets folder:
   `~/Library/Application Support/Übersicht/widgets/`
3. Make the scripts executable (once):
   ```bash
   chmod +x ~/Library/Application\ Support/Übersicht/widgets/cosmoduck-*.widget/scripts/*.sh
   ```
4. **Enable Interaction** in Übersicht's menu so dragging and the lock buttons work.
5. **For the Hardware Monitor** (CPU/GPU temp & power), install macmon:
   ```bash
   brew install macmon
   ```
6. Übersicht loads the widgets automatically (menu → *Refresh All* if needed).

## Included widgets
| Widget | Shows |
|---|---|
| **Clock** | `HH` over `MM` (two‑layer, colour‑inverted) + seconds |
| **Disk / System** | Ring gauges for CPU, RAM, disk + legend with CPU %, free RAM and free disk |
| **Weather** | OpenWeatherMap current conditions with a Feather glyph icon |
| **Network** | Wi‑Fi name + down/up speed with bar sparklines |
| **Processes** | Top 3 CPU and top 3 RAM processes |
| **Hardware Monitor** | CPU/GPU temperature + CPU/GPU/System power (via macmon) |
| **Claude Code** | Model + reasoning effort in use, real session (5h) and weekly rate-limit usage with % fill bars and next reset time |

## Configuration
- **Weather** — edit `cosmoduck-weather.widget/scripts/weather.sh` and set your own `city_id`
  (find it on [openweathermap.org](https://openweathermap.org/find)) and `api_key`.
  It ships with a demo key and city (Como, IT) and `lang=en`.
- **Wi‑Fi name** — macOS 14+ hides the SSID (`<redacted>`) unless the app has **Location**
  permission. Grant Location to Übersicht to show the real network name; otherwise the widget
  falls back to the interface label (e.g. "Wi‑Fi").
- **Claude Code** — token counts come from the local CLI transcripts in
  `~/.claude/projects/**/*.jsonl` (the Claude Code CLI only — the Claude desktop app stores its
  data elsewhere and is never counted). Bars turn amber past 80% and red past 92%.

  **Real percentages (recommended).** Claude Code hands its status line the actual
  `rate_limits` for the 5-hour and 7-day windows. Wire that up once and the widget shows real
  percentages and real reset times, with nothing to calibrate:

  ```bash
  cp cosmoduck-cc.widget/scripts/statusline.sh ~/.claude/cosmoduck-statusline.sh
  chmod +x ~/.claude/cosmoduck-statusline.sh
  ```

  then add to `~/.claude/settings.json`:

  ```json
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/cosmoduck-statusline.sh",
    "refreshInterval": 30
  }
  ```

  The script caches the limits to `~/.claude/cosmoduck-ratelimits.json` and also prints a status
  line with model, 5h/7d usage, context and cost. Two caveats: `rate_limits` is only sent to
  Claude.ai Pro/Max subscribers after the first API response of a session, and the values only
  refresh while a Claude Code session is open. Configuring any status line also removes most
  footer keyboard hints.

  With live limits the percentage comes from Anthropic while the token figure is still counted
  locally from the transcripts, so the two are not the same measurement — the token figure is
  labelled `local` to keep them from being read as a fraction of one another.

  **Estimated fallback.** Without that cache — or once a cached window is past its reset — the
  widget estimates from the transcripts and prefixes the percentage with `~`. Tune the estimate
  at the top of `cosmoduck-cc.widget/scripts/collect.sh`:

  | Variable | Default | Meaning |
  |---|---|---|
  | `SESSION_BUDGET` | `1000000` | tokens per 5h session window |
  | `WEEK_BUDGET` | `10000000` | tokens per weekly window |
  | `SESSION_HOURS` | `5` | length of the session window |
  | `WEEK_ANCHOR_DOW` | `0` | weekly reset day (0=Mon … 6=Sun) |
  | `WEEK_ANCHOR_HOUR` | `0` | weekly reset hour, local time |
  | `METRIC` | `bill` | `bill` = fresh input + cache creation + output; `tot` also adds cache reads |
- **Layout** — each widget's `top` / `left` are at the top of its `index.coffee`. You can also
  just drag them; positions are remembered.

## Credits
- Original theme: **Regulus Dark** (Leonis Conky pack) by **Closebox73**, recoloured with the
  Cosmoduck palette — GPLv3.
- Lock/drag/persistence technique adapted from [msavox/Glass‑Widgets‑Uebersicht](https://github.com/msavox/Glass-Widgets-Uebersicht).
- Sensors: [macmon](https://github.com/vladkens/macmon) by vladkens.
- Fonts: **Bebas Neue** & **Abel** (SIL OFL), **Feather** icon font (MIT). See `THIRD_PARTY.md`.
- Tested on: MacBook Air (Apple Silicon, M‑series).

## License
GPLv3 — see `LICENSE`. This is a derivative of the GPLv3 Regulus Conky theme.
