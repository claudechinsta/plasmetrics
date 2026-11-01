# Plasmetrics

A compact system monitor widget for the KDE Plasma 6 panel, inspired by iStat Menus.

Shows CPU, memory, network, temperature, battery and disk usage in the panel as label, bar and value, with a detailed popup (history graphs, load, top processes, uptime) when clicked.

## Features

- Per-metric options: enable, label, chart / percentage / both, and a fixed palette of colors
- Reorder metrics in the panel
- Choose which disk to monitor (defaults to `/`)
- Vertical bar or history chart style
- Custom font (with search), font sizes, Celsius or Fahrenheit, update interval

## Install

Requires Plasma 6. Download `plasmetrics-*.plasmoid` from the [Releases](https://github.com/claudechinsta/plasmetrics/releases) page and install it with:

```bash
kpackagetool6 -t Plasma/Applet --install plasmetrics-*.plasmoid
```

Or from source:

```bash
git clone git@github.com:claudechinsta/plasmetrics.git
cd plasmetrics
kpackagetool6 -t Plasma/Applet --install .
```

Then right-click the panel, choose Add Widgets, and search for "Plasmetrics". Update later with `--upgrade` instead of `--install`.

Temperature needs a `k10temp`, `coretemp`, `zenpower` or `cpu_thermal` sensor (`lm_sensors`).
Battery needs a `Battery` entry in `/sys/class/power_supply` (hidden otherwise). Wattage uses `power_now`, or current × voltage when that is missing.

## Layout

- `contents/ui/` widget QML, `contents/ui/config/` settings pages
- `contents/config/` settings schema and page list
- `contents/code/stats.sh` reads `/proc`, `/sys/class/hwmon`, `df` and `ps`

## Support

If you find it useful, you can [buy me a coffee](https://buymeacoffee.com/chinsta).

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).
