# Cosmoduck Widgets for Übersicht

A blue, monospaced-glass widget set for macOS — a faithful port of the **Regulus Dark / Cosmoduck** Conky theme (Linux) to [Übersicht](https://tracesof.net/uebersicht/). Big two‑layer clock, ring gauges, weather, network, processes and **real Apple‑Silicon sensors**, all on a subtle frosted‑glass panel.

Made for a MacBook Air M‑series, tuned on a notch display.

## Preview
![Preview](preview.png?v=1)

## Features
- **Frosted glass** — translucent tinted panels with `backdrop-filter` blur, thin blue border and inner highlight. The blur picks up your wallpaper.
- **Draggable & lockable** — click‑drag any widget to reposition; each has a small monochrome lock icon (shown on hover) to freeze it. Positions and lock state persist across reboots and refreshes (via `localStorage`).
- **Real sensors on Apple Silicon** — CPU/GPU die temperature and power draw via [`macmon`](https://github.com/vladkens/macmon) (no `sudo`).
- **Two‑layer clock** — large Bebas Neue digits with the original Cosmoduck colour‑inversion between hours and minutes.
- **Ring gauges** — CPU, RAM and disk usage as arcs around chip/CPU glyphs, with a CPU/RAM/Disk legend.

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
| **Disk / System** | Ring gauges for CPU, RAM, disk + CPU/RAM/Disk % legend |
| **Weather** | OpenWeatherMap current conditions with a Feather glyph icon |
| **Network** | Wi‑Fi name + down/up speed with bar sparklines |
| **Processes** | Top 3 CPU and top 3 RAM processes |
| **Hardware Monitor** | CPU/GPU temperature + CPU/GPU/System power (via macmon) |

## Configuration
- **Weather** — edit `cosmoduck-weather.widget/scripts/weather.sh` and set your own `city_id`
  (find it on [openweathermap.org](https://openweathermap.org/find)) and `api_key`.
  It ships with a demo key and city (Como, IT) and `lang=en`.
- **Wi‑Fi name** — macOS 14+ hides the SSID (`<redacted>`) unless the app has **Location**
  permission. Grant Location to Übersicht to show the real network name; otherwise the widget
  falls back to the interface label (e.g. "Wi‑Fi").
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
