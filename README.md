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
- **Weather** — needs a free [OpenWeatherMap](https://openweathermap.org/api) key. Keep it out of
  the repo, in `~/.config/cosmoduck/weather.env`:

  ```bash
  mkdir -p ~/.config/cosmoduck
  echo 'OWM_API_KEY=your-key-here' > ~/.config/cosmoduck/weather.env
  chmod 600 ~/.config/cosmoduck/weather.env
  ```

  `OWM_API_KEY` in the environment works too. Set `CITY_ID` at the top of
  `cosmoduck-weather.widget/scripts/weather.sh` (find yours on
  [openweathermap.org](https://openweathermap.org/find)). Without a key the widget keeps showing
  the last cached reading, then falls back to placeholders.
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

  **How fresh the reading is.** Limits only refresh while a CLI session is rendering its status
  line, so a cached figure can be hours old while still looking authoritative. It stays useful —
  within a window the quota can only go up, so an old reading is a valid lower bound — but the
  widget now marks it. Next to `LAST HOUR`:

  | Marker | Meaning |
  |---|---|
  | *(nothing)* | real quota, refreshed within `LIVE_TTL` |
  | `~3h` | real quota, but that stale — the percentages also carry a `~` |
  | `~stima` | no usable cache; percentages are estimated from the transcripts |

  **Terminal only, by default.** Claude Code launched from the Claude desktop app uses the same
  `~/.claude`, so it runs this same status line and writes the same cache — and if it is signed
  in as a different account, its quota has nothing to do with the one you are watching. Since the
  cache is a single file, the last session to render used to win, which made the widget flip
  between two accounts' numbers.

  Rate limits carry no account id (Claude Code passes `model`, `workspace`, `cost`,
  `rate_limits`, … to the status line and no identity, and `~/.claude.json` is shared by both), so
  the widget keys off `entrypoint` instead, which transcripts do record: `cli` for the terminal,
  `claude-desktop` for the app. Only sessions in `ENTRYPOINTS` are counted, and only those in
  `CACHE_ENTRYPOINTS` may write the cache — both default to `cli`. This tracks the terminal, not
  an account: it is the right split only if each surface stays on its own login.

  | Want | Set |
  |---|---|
  | terminal only *(default)* | `ENTRYPOINTS=cli` |
  | both, combined | `ENTRYPOINTS="cli claude-desktop"` (and the same for `CACHE_ENTRYPOINTS`) |
  | everything, no filter | `ENTRYPOINTS=""` |

  `ACCOUNT_LABEL` (e.g. `perso`, `lavoro`) adds a reminder next to the model name. It is a note to
  yourself, not something the widget verifies.

  **Estimated fallback.** Without that cache — or once a cached window is past its reset — the
  widget estimates from the transcripts and prefixes the percentage with `~`. The same
  `ENTRYPOINTS` filter applies, so the estimate covers the same sessions as the live figures.
  Tune the estimate at the top of `cosmoduck-cc.widget/scripts/collect.sh`:

  | Variable | Default | Meaning |
  |---|---|---|
  | `SESSION_BUDGET` | `1000000` | tokens per 5h session window |
  | `WEEK_BUDGET` | `10000000` | tokens per weekly window |
  | `SESSION_HOURS` | `5` | length of the session window |
  | `WEEK_ANCHOR_DOW` | `0` | weekly reset day (0=Mon … 6=Sun) |
  | `WEEK_ANCHOR_HOUR` | `0` | weekly reset hour, local time |
  | `METRIC` | `bill` | `bill` = fresh input + cache creation + output; `tot` also adds cache reads |
  | `LIVE_TTL` | `900` | seconds a cached real quota stays fresh before being marked stale |
  | `ENTRYPOINTS` | `cli` | which sessions to count; empty disables the filter |
  | `ACCOUNT_LABEL` | *(empty)* | optional reminder of which login you are on; empty hides it |

  `CACHE_ENTRYPOINTS` (default `cli`) is the matching knob in `statusline.sh`, deciding which
  sessions may write the cache. Keep the two in agreement.
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
