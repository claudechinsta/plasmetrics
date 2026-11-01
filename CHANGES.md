# Changes

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
