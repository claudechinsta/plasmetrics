# Changes

## 1.4.0

- New Claude usage and Codex usage metrics (beta, both off by default, turn them on under Metrics): your plan's 5-hour session and weekly usage as two bars with their own percentages in the panel (CLD and CDX), and a popup card per plan with reset countdowns. They read the login Claude Code keeps in `~/.claude/.credentials.json` and the one the Codex CLI keeps in `~/.codex/auth.json`, so there is nothing to set up beyond having signed in to the tool once. A login is only sent to its own service (api.anthropic.com, chatgpt.com), at most once per refresh interval, and is never stored or changed. Each metric stays hidden when you are not signed in, and shows the last reading while the tool's login is out of date
- Claude and Codex usage get an "Official" color (Claude orange, Codex periwinkle), their default, in the color list. The panel label (CLD, CDX) uses the chosen color
- New "Refresh every" setting in General for Claude and Codex usage: 1 (default), 3, 5 or 10 minutes. After a "too many requests" answer from a service, it is left alone for 5 minutes
- After updating, restart the Plasma shell or log out and in so the new version loads

## 1.3.0

- New GPU metric: usage, temperature or clock speed in the panel, plus a popup card. Works with Intel, AMD and NVIDIA (NVIDIA needs `nvidia-smi`), shows the GPU name when a driver reports nothing, and leaves a sleeping discrete GPU alone so it is not woken up. Intel usage is an estimate
- CPU value can now show temperature, and GPU value can show temperature or clock speed. When a reading is not available the panel shows `-`
- New "Color for all charts" setting in General to override every metric color
- Popup: the System card is now a titled list (Model, CPU, Memory, OS, Kernel, Hostname)
- Popup: fixed width, no longer grows with the system font size
- Changed: new installs start with the order network, CPU, GPU, memory, temp, disk, battery, world clock, and the network panel item shows its value without a chart. Existing settings are kept
- Changed: CPU clock speed shows `-` when unavailable instead of the percentage
- Fixed: CPU and network readings on systems whose awk is mawk (Debian, Ubuntu)
- After updating, restart the Plasma shell or log out and in so the new version loads

## 1.2.1

- CPU: new clock speed readout. The popup shows the average frequency, and the panel can show it instead of the percentage
- Memory and battery get a "Value shows" choice for the panel: memory can show percentage, used, available or swap; battery adds time remaining (also shown in the popup)
- Popup: new System card (model, CPU, threads, RAM, OS, kernel, hostname)
- Popup: disks are grouped by physical drive, named by model, with one colored bar segment per partition
- Popup: battery card shows the battery model; network card shows your local and public IP. The public IP is looked up on api.ipify.org at most every 10 minutes and can be turned off in General
- Popup: opens at full height without scrolling, square cards with more breathing room, and a footer with version and links
- Display options now read Chart, Value, Chart + value
- New Item gap setting in Appearance
- World clock: search time zones by country as well as city

## 1.2.0

- New world clock metric: add as many time zones as you like. Each shows a vertical code (up to 3 characters, emoji allowed, editable), the local time and the hour difference to you, for example `09:41 (-5h)`. 12 or 24-hour time. Also a card in the popup with the city, time and "+1 day" markers
- CPU card in the popup shows usage for every core and thread: 4 equal columns, a bar and a percentage each, colored green, orange or red by load
- Battery card in the popup draws wattage and voltage as two lines with a colored legend
- A ⚡ follows the battery value while charging

## 1.1.1

- Fixed the network metric stuck at 0 KB/s on systems whose interface is named like `wlp2s0` or `enp5s0`

## 1.1.0

- New battery metric: level, wattage and voltage. The panel shows one of them (your choice), the popup card shows all three plus charge status. Hidden on machines without a battery
- CPU can show one square per core in a 4-row grid (green below 20%, orange up to 70%, red above). Chart options: bar, history, cores, bar & cores, all
- Pick the battery, network interface and temperature sensor from a list. Automatic by default: the system battery, the interface with the default route, the CPU sensor. Peripheral batteries such as a wireless mouse work; missing wattage or voltage shows as –
- Panel labels are vertical by default (turn off in Appearance)
- About page links to Buy Me a Coffee

## 1.0.1

- Widget ID is now `io.github.claudechinsta.plasmetrics`. Remove the 1.0.0 widget from your panel and add this one
- The icon is bundled in the package, so it shows for everyone
- About page now lists the author, repository and bug tracker

## 1.0.0

First release.

- Panel strip with CPU, memory, network, temperature and disk, each as label, bar and value
- Click-to-open popup with history graphs, load average, top processes and uptime
- Per-metric settings: enable, label, chart / percentage / both, and a fixed color palette
- Reorderable metrics, selectable disk (defaults to `/`)
- Vertical bar or history chart style
- Custom font with search, font sizes, Celsius or Fahrenheit, update interval
