# Cosmoduck Widgets for Übersicht

A blue, monospaced-glass widget set for macOS — a faithful port of the **Regulus Dark / Cosmoduck** Conky theme (Linux) to [Übersicht](https://tracesof.net/uebersicht/). Big two‑layer clock, calendar, ring gauges, weather, network, processes and **real Apple‑Silicon sensors**, all on a subtle frosted‑glass panel.

Made for a MacBook Air M‑series, tuned on a notch display.

## Preview
![Preview](preview.png?v=2)

## Features
- **Frosted glass** — translucent tinted panels with `backdrop-filter` blur, thin blue border and inner highlight. The blur picks up your wallpaper.
- **Accent from the wallpaper** — an invisible theme widget reads the wallpaper in use, picks the colour your eye picks — the vivid one, not merely the widest — and recolours the whole set to match. Remove the widget and everything falls back to the original blue.
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
5. **For the Hardware Monitor's sensors** (CPU/GPU temp & power — the battery half needs nothing), install macmon:
   ```bash
   brew install macmon
   ```
6. Übersicht loads the widgets automatically (menu → *Refresh All* if needed).

## Included widgets
| Widget | Shows |
|---|---|
| **Clock** | `HH` over `MM` (two‑layer, colour‑inverted) + seconds |
| **Calendar** | Month grid with today highlighted and an ISO week-number (`CW`) column; `‹ ›` to browse months, double-click a day to open it in Calendar.app |
| **Disk / System** | Ring gauges for CPU, RAM, disk + legend with CPU %, free RAM and free disk |
| **Weather** | OpenWeatherMap: current conditions, wind and humidity as glyphs, and the next five days |
| **Network** | Wi‑Fi name + down/up speed with bar sparklines |
| **Processes** | Top 3 by CPU and top 3 by memory, each row carrying its own bar |
| **Hardware Monitor** | CPU/GPU die temperature as gauges (via macmon), battery charge with time to empty or to full, CPU/GPU/System power in watts over the last two minutes' trace |
| **Claude Code** | Model + reasoning effort in use, real session (5h) and weekly rate-limit usage with % fill bars and next reset time |
| **Theme** | Nothing — invisible. Derives the accent palette from the wallpaper and publishes it to all the others |
| **All in one** | Every card above except the clock, calendar included, in a single 216×738 panel |

## All in one

`cosmoduck-all.widget` puts weather, system rings, sensors and battery, network, processes,
Claude usage and the month grid into one panel 216 points wide, for anyone who would rather have a
block than a column. Only the clock stays out: it is meant to be read across the room, and it
gains nothing from being folded into a dashboard.

It does not duplicate any collector — it calls the ones belonging to the individual widgets, in
parallel, so a fix made there applies here too. The calendar is the one exception: it has no
script to call, being drawn entirely in the browser, so that code is carried in both places and a
change to the grid has to be made twice. That also means it needs those widget folders to
be present, even if you drag the individual cards off-screen or keep them hidden; a folder that is
missing simply leaves its section blank. One pass costs about a second of wall time, nearly all of
it the network collector, which has to watch the counters for a second to know the rate.

## Configuration
- **Accent from the wallpaper** — `cosmoduck-theme.widget` draws nothing. Every 5 s it finds the
  wallpaper in use, samples it, and publishes a palette as CSS variables (`--cd-accent`,
  `--cd-bright`, `--cd-mid`, `--cd-deep`, `--cd-shadow`, `--cd-text`, `--cd-ink`, `--cd-glass` and
  the translucent `--cd-border` / `--cd-fill` / `--cd-rule` / `--cd-track`). Übersicht puts every
  widget in one document per screen, so the variables reach all of them at once.

  Every colour in the other widgets is written `var(--cd-x, <original colour>)`. **Delete the
  theme widget and the set goes back to the Cosmoduck blue** — nothing else has to change.

  Only the *hue* comes from the wallpaper. Lightness stays where it was, because that is what
  decides whether text reads on the dark glass, and a photo does not get a vote on it. Saturation
  scales with the wallpaper's own, between a floor and a ceiling: a washed-out picture gives a
  quieter theme, a vivid one a livelier theme, neither an illegible one.

  How the colour is found: the picture is redrawn into a small bitmap, so every pixel of it is the
  average of the area it stands for and nothing falls between two samples. Each pixel is read in
  **Oklab** rather than HSL — HSL's degrees are not perceptually even and its *S* does not say how
  charged a colour is. Hues go into a 72-bin histogram, each pixel spread across the two bins it
  straddles so a colour sitting on a boundary is not split in half. Then every peak of that
  histogram is a candidate, and the winner is the one whose *extent weighted by charge* is
  highest: a small vivid flower beats a large washed-out sky, which is how a person would read the
  picture.

  If nothing in the picture is colourful enough to qualify, it gets looked at a second time, with
  faint tints allowed, and asked a different question: does the *whole* picture agree on one hue?
  A desaturated photograph or a Nord-palette wallpaper answers yes — every pixel points the same
  way — and gets that hue, quietly, at the saturation floor. A true black-and-white picture
  answers no: what little chroma it has is compression noise pointing everywhere at once. Those
  get a **greyscale theme**, because inventing a hue for them would be worse.

  A flat wallpaper with a few bright specks in it — a lamp, a neon sign — gets read in **two
  tones**, because that is how the picture itself is put together: a calm field with coloured
  punctuation. The panels (glass, ink, shadows) take the field's tint; the marks on top of them
  (numbers, icons, arcs, borders) take the speck. Specks are hunted at four times the resolution
  of the main pass and only among genuinely charged pixels: at 96×96 the four dots of a logo are
  five pixels in total, and five pixels should not repaint a desktop.

  When the flat wallpaper's subject has no colour at all — white lettering, a light logo — it is
  still the thing your eye lands on, and a histogram of hues cannot see it, because white has no
  hue. It is found by lightness instead: few pixels, neutral, far brighter than the rest. Then the
  palette is read in three parts, the way the poster is: labels and secondary marks go
  near-neutral like the lettering, panels keep the field's tint, and the accent alone goes to a
  speck. One hue is passed over there — a red or magenta speck reads as an alarm on a dark
  dashboard, so among thirty pixels' worth of candidates it loses to any other colour, though it
  still wins if it is the only colour present. A red that *fills* the picture — a car, a sunset —
  is unaffected: there, red is the picture.

  | The wallpaper | What the widgets do |
  |---|---|
  | has a colour | take it, saturation scaled by how charged it is |
  | is flat but tinted (Nord, a desaturated photo) | take the tint, at the saturation floor |
  | is flat with bright specks in it | panels from the field, accent from the brightest speck |
  | is flat with a light subject (lettering, a logo) | labels near-neutral like the lettering, panels from the field, accent from a speck |
  | is black and white | go greyscale |
  | cannot be read (dynamic wallpaper, no permission) | keep the last good palette |

  Tune it at the top of `cosmoduck-theme.widget/scripts/collect.sh`:

  | Variable | Default | Meaning |
  |---|---|---|
  | `BLEND` | `1.0` | how much the wallpaper decides. `1` adopts its hue outright, `0.3` nudges the Cosmoduck blue a few dozen degrees, `0` leaves the original theme untouched |
  | `SAT_FLOOR` | `0.75` | saturation floor, as a fraction of the original. Without it a grey wallpaper produces grey widgets |
  | `VIVIDNESS` | `1.5` | how the winner is chosen among the hues present. `0` gives it to the widest one, `1.5` lets a charged colour outweigh a dull backdrop, `3` lets one bright patch set the theme |
  | `TWO_TONE` | `1` | on a flat wallpaper with bright specks, let the panels keep the field's tint and give the accent to a speck. `0` keeps one hue for everything |

  All four also read from the environment, as `COSMODUCK_THEME_BLEND`, `COSMODUCK_THEME_SAT_FLOOR`,
  `COSMODUCK_THEME_VIVIDNESS` and `COSMODUCK_THEME_TWO_TONE`.

  The wallpaper is read from macOS's own registry
  (`~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`), which needs **no
  permission**. Only if that fails does it ask System Events, and *that* raises the usual
  *"Übersicht wants to control System Events"* prompt. Decoding the picture costs a couple of
  tenths of a second, so the result is cached in `~/.cache/cosmoduck/` and recomputed only when
  the wallpaper, its mtime or the tuning changes.

  Two known limits: the wallpaper can differ per display and per Space, while the palette is one
  per screen — the most recently set wallpaper wins; and a *dynamic* wallpaper (the `hello …` ones, `.madesktop`)
  is not an image file, so it cannot be read — the last good palette stays, and
  `~/.cache/cosmoduck/theme.log` says so.
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

  Two calls, cached apart: current conditions age out after 10 minutes, the five-day forecast
  after an hour — it moves far more slowly and is not worth a call every time. The forecast comes
  in three-hour steps, which the script groups into local days, keeping each day's low, high and
  the icon from the middle of the day.
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
  widget marks it. Next to `LAST HOUR`:

  | Marker | Meaning |
  |---|---|
  | *(nothing)* | real quota, and still exact |
  | `~3h` | real quota, but that stale — the percentages also carry a `~` |
  | `~stima` | no usable cache; percentages are estimated from the transcripts |

  Age alone does not make a reading stale: a cached figure can only have been overtaken by tokens
  you actually spent. If no counted session has consumed anything since the capture, the number is
  still exact no matter how old it is, and it is left unmarked — which is the normal state when
  you simply stop using Claude Code. `LIVE_TTL` is the fallback for the window the transcripts
  cannot vouch for (a capture older than the scan, another entrypoint on the same account).

  **When a window expires.** A closed window does not decay into a guess: the next one starts at
  zero, so if nothing was consumed after the reset the widget shows a real `0%` and rolls the
  weekly reset forward by seven days. It zeroes itself at the scheduled time with Claude Code shut,
  without waiting for a session to refresh the cache. The 5h window has no fixed grid — it opens on
  the first message — so an expired one with no usage since simply reads `idle`.

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

  **Estimated fallback.** Without that cache — or when a window expired *and* was used again
  before any status line could report the new figure — the widget estimates from the transcripts
  and prefixes the percentage with `~`. The same `ENTRYPOINTS` filter applies, so the estimate
  covers the same sessions as the live figures. When the real weekly boundary is known from the
  cache it also anchors the estimate, so a fallback right after a reset starts from zero instead
  of dragging in the previous week's tokens. `WEEK_ANCHOR_*` only applies when it is not.
  Tune the estimate at the top of `cosmoduck-cc.widget/scripts/collect.sh`:

  | Variable | Default | Meaning |
  |---|---|---|
  | `SESSION_BUDGET` | `1000000` | tokens per 5h session window |
  | `WEEK_BUDGET` | `10000000` | tokens per weekly window |
  | `SESSION_HOURS` | `5` | length of the session window |
  | `WEEK_ANCHOR_DOW` | `0` | weekly reset day (0=Mon … 6=Sun), when the real one is unknown |
  | `WEEK_ANCHOR_HOUR` | `0` | weekly reset hour, local time, when the real one is unknown |
  | `METRIC` | `bill` | `bill` = fresh input + cache creation + output; `tot` also adds cache reads |
  | `LIVE_TTL` | `900` | seconds a cached quota stays fresh when idleness cannot be verified |
  | `ENTRYPOINTS` | `cli` | which sessions to count; empty disables the filter |
  | `ACCOUNT_LABEL` | *(empty)* | optional reminder of which login you are on; empty hides it |

  `CACHE_ENTRYPOINTS` (default `cli`) is the matching knob in `statusline.sh`, deciding which
  sessions may write the cache. Keep the two in agreement.
- **Calendar** — sits under the clock, aligned to its column. The week starts on Monday; set
  `WEEK_START = 0` in `afterRender:` (`cosmoduck-cal.widget/index.coffee`) for a Sunday-first
  grid. The month always draws six rows, so the card never changes height.

  The `CW` column carries **ISO 8601** week numbers. Each row is numbered after its own Thursday,
  which is what fixes an ISO week's number and year — so the count stays right across a year
  boundary, and under `WEEK_START = 0`, where a row opens on a Sunday that still belongs to the
  week before.

  `‹` and `›` browse months (the grid keeps whatever month you left it on — the minute refresh
  does not snap it back); while you are away from the current month the date on the right turns
  into a **TODAY** button that brings you home. **Double-clicking** a day opens **Calendar.app** on
  that date, greyed-out days from the neighbouring months included — it takes two clicks because
  raising an app to the front is too easy to trigger by accident on a single one.

  Opening Calendar goes through `osascript`, so the first time raises the macOS prompt *"Übersicht
  wants to control Calendar"* — allow it, or the double-click silently does nothing. You can revisit the
  choice in *System Settings → Privacy & Security → Automation*. Both this and the drag need
  **Enable Interaction** on in Übersicht's menu.
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
