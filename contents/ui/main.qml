import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "ClockZones.js" as Zones

PlasmoidItem {
    id: root

    readonly property int maxSamples: 60
    property real cpu: 0
    property real cpuFreq: -1 // GHz, -1 when unavailable
    property real memUsed: 0
    property real memTotal: 1
    property real swapUsed: 0
    property real swapTotal: 0
    property real rxRate: 0
    property real txRate: 0
    property real diskUsed: 0
    property real diskTotal: 1
    property real temp: -1
    property real batLevel: -1
    property real batVolts: 0
    property real batWatts: 0
    property real batSecs: -1
    property var sysInfo: []
    property string lanIp: ""
    property string wanIp: ""
    property string batModel: ""
    property var disks: []
    property string gpuName: ""
    property string gpuKind: ""
    property string gpuDrv: ""
    property string gpuState: ""
    property real gpuUtil: -1
    property real gpuVramUsed: -1
    property real gpuVramTotal: -1
    property real gpuTemp: -1
    property real gpuPower: -1
    property real gpuMhz: -1
    property string gpuTempSrc: ""
    property string batStatus: ""
    readonly property string batCharging: batStatus === "Charging" ? "⚡" : ""
    property double clockNow: Date.now()
    property var clockOffsets: ({})
    property real clockLocal: 0
    readonly property var clockZones: Zones.parse(cfg.clockZones)
    property string load: ""
    property int uptime: 0
    property var tops: []
    property var cpuHist: Array(60).fill(0)
    property var memHist: Array(60).fill(0)
    property var rxHist: Array(60).fill(0)
    property var txHist: Array(60).fill(0)
    property var tempHist: Array(60).fill(0)
    property var batHist: Array(60).fill(0)
    property var batWattHist: Array(60).fill(-1)
    property var batVoltHist: Array(60).fill(-1)
    property var diskHist: Array(60).fill(0)
    property var gpuHist: Array(60).fill(0)
    property real peakRate: 1024 * 100
    property var cores: []
    property var prevCores: null
    property var prevCpu: null
    property var prevNet: null
    property string netIface: ""
    property double prevNetT: 0

    readonly property var cfg: Plasmoid.configuration
    readonly property string fontFam: cfg.useCustomFont && cfg.fontFamily !== "" ? cfg.fontFamily : Kirigami.Theme.defaultFont.family
    readonly property int px: cfg.panelFontSize

    readonly property string clockScript: Qt.resolvedUrl("../code/clock.sh").toString().replace("file://", "")
    readonly property string script: Qt.resolvedUrl("../code/stats.sh").toString().replace("file://", "")

    readonly property var order: {
        var keys = ["cpu", "mem", "net", "temp", "gpu", "bat", "clock", "disk"], out = []
        cfg.metricOrder.split(",").forEach(function (k) { if (keys.indexOf(k) >= 0 && out.indexOf(k) < 0) out.push(k) })
        keys.forEach(function (k) { if (out.indexOf(k) < 0) out.push(k) })
        return out
    }

    // Everything the panel strip needs to draw one metric
    function metricData(key) {
        var pct = function (f) { return Math.round(f * 100) + "%" }
        switch (key) {
        case "cpu":
            return { on: cfg.showCpu, label: "CPU", showLabel: cfg.cpuLabel, display: cfg.cpuDisplay, text: cfg.cpuValue === 1 ? (cpuFreq >= 0 ? cpuFreq.toFixed(1) + " GHz" : "-") : cfg.cpuValue === 2 ? (temp >= 0 ? fmtTemp(temp) : "-") : pct(cpu), scale: 1,
                     frac: cpu, frac2: -1, chart: cfg.cpuChart, hist: cpuHist, hist2: null, col: root.tint(root.cfg.cpuColor), col2: "#000000" }
        case "mem":
            return { on: cfg.showMem, label: "MEM", showLabel: cfg.memLabel, display: cfg.memDisplay, text: memText(pct), scale: 1,
                     frac: memUsed / memTotal, frac2: -1, chart: cfg.barStyle, hist: memHist, hist2: null, col: root.tint(root.cfg.memColor), col2: "#000000" }
        case "gpu":
            return { on: cfg.showGpu && gpuUtil >= 0, label: "GPU", showLabel: cfg.gpuLabel, display: cfg.gpuDisplay,
                     text: cfg.gpuValue === 1 ? (gpuTemp >= 0 ? fmtTemp(gpuTemp / 1000) : "-") : cfg.gpuValue === 2 ? fmtMhz(gpuMhz) : Math.round(gpuUtil) + "%", scale: 1,
                     frac: Math.max(0, gpuUtil) / 100, frac2: -1, chart: cfg.barStyle, hist: gpuHist, hist2: null, col: root.tint(root.cfg.gpuColor), col2: "#000000" }
        case "net":
            return { on: cfg.showNet, label: "NET", showLabel: cfg.netLabel, display: cfg.netDisplay,
                     text: "↓ " + fmtRate(rxRate) + "\n↑ " + fmtRate(txRate), scale: 0.8,
                     frac: rxRate / peakRate, frac2: txRate / peakRate, chart: cfg.barStyle, hist: rxHist, hist2: txHist,
                     col: root.tint(root.cfg.downColor), col2: root.tint(root.cfg.upColor) }
        case "temp":
            return { on: cfg.showTemp && temp >= 0, label: "TEMP", showLabel: cfg.tempLabel, display: cfg.tempDisplay, text: fmtTemp(temp), scale: 1,
                     frac: temp / 100, frac2: -1, chart: cfg.barStyle, hist: tempHist, hist2: null, col: root.tint(root.cfg.tempColor), col2: "#000000" }
        case "clock":
            return { on: false, label: "", showLabel: false, display: 1, text: "", scale: 1,
                     frac: 0, frac2: -1, chart: 0, hist: null, hist2: null, col: "#000000", col2: "#000000" }
        case "bat":
            return { on: cfg.showBat && batLevel >= 0, label: "BAT", showLabel: cfg.batLabel, display: cfg.batDisplay,
                     text: (cfg.batValue === 1 ? fmtWatts(batWatts) : cfg.batValue === 2 ? fmtVolts(batVolts) : cfg.batValue === 3 ? fmtDuration(batSecs) : Math.round(batLevel) + "%") + batCharging, scale: 1,
                     frac: batLevel / 100, frac2: -1, chart: cfg.barStyle, hist: batHist, hist2: null, col: root.tint(root.cfg.batColor), col2: "#000000" }
        default:
            return { on: cfg.showDiskPanel, label: "DISK", showLabel: cfg.diskLabel, display: cfg.diskDisplay, text: pct(diskUsed / diskTotal), scale: 1,
                     frac: diskUsed / diskTotal, frac2: -1, chart: cfg.barStyle, hist: diskHist, hist2: null, col: root.tint(root.cfg.diskColor), col2: "#000000" }
        }
    }

    function memText(pct) {
        switch (cfg.memValue) {
        case 1: return fmtBytes(memUsed)
        case 2: return fmtBytes(memTotal - memUsed)
        case 3: return swapTotal > 0 ? fmtBytes(swapUsed) : "–"
        }
        return pct(memUsed / memTotal)
    }

    function fmtBytes(b) {
        var u = ["B", "KB", "MB", "GB", "TB"], i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return b.toFixed(i > 1 ? 1 : 0) + " " + u[i]
    }
    function fmtRate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        return Math.round(b / 1024) + " KB/s"
    }
    function fmtTemp(c) {
        return cfg.tempFahrenheit ? Math.round(c * 9 / 5 + 32) + "°F" : Math.round(c) + "°C"
    }
    function fmtDuration(s) {
        if (s < 0) return "–"
        var m = Math.round(s / 60)
        return Math.floor(m / 60) + ":" + ("0" + m % 60).slice(-2)
    }
    function gpuSubtitle() {
        switch (gpuState) {
        case "asleep": return "Discrete GPU is powered down"
        case "nodriver": return "No driver loaded"
        case "nostats":
            return gpuDrv === "nvidia" ? "Usage needs nvidia-smi (the nvidia-utils package)"
                 : gpuDrv === "nouveau" || gpuDrv === "radeon" ? "The " + gpuDrv + " driver does not report usage"
                 : "This driver does not report usage"
        }
        var parts = [gpuKind === "discrete" ? "Discrete" : "Integrated"]
        if (gpuVramTotal > 0) parts.push("VRAM  " + fmtBytes(gpuVramUsed) + " / " + fmtBytes(gpuVramTotal))
        if (gpuTemp >= 0) parts.push(fmtTemp(gpuTemp / 1000) + (gpuTempSrc === "package" ? " (CPU package)" : ""))
        if (gpuPower >= 0) parts.push(fmtWatts(gpuPower / 1e6))
        if (gpuMhz > 0) parts.push(fmtMhz(gpuMhz))
        if (gpuDrv === "i915" || gpuDrv === "xe") parts.push("usage estimated")
        return parts.join("      ")
    }
    function fmtMhz(m) { return m < 0 ? "-" : m >= 1000 ? (m / 1000).toFixed(2) + " GHz" : Math.round(m) + " MHz" }
    function fmtWatts(w) { return w < 0 ? "–" : w.toFixed(1) + " W" }
    function fmtVolts(v) { return v < 0 ? "–" : v.toFixed(2) + " V" }
    // The General setting, when picked, replaces every metric's own color
    function tint(c) { return cfg.colorOverride !== "" ? cfg.colorOverride : c }
    // Same thresholds as the panel core grid
    function usageColor(f) { return f < 0.2 ? "#30d158" : f < 0.7 ? "#ff9f0a" : "#ff453a" }
    // "09:41 (-5h)" for a zone, "–" until its offset is known
    function clockText(tz, withOffset) {
        var off = clockOffsets[tz]
        if (off === undefined || isNaN(clockLocal)) return "–"
        var t = Zones.clock(clockNow, off, cfg.clock24)
        return withOffset ? t + " (" + Zones.hours(off - clockLocal) + ")" : t
    }
    function clockOffsetText(tz) {
        var off = clockOffsets[tz]
        return off === undefined || isNaN(clockLocal) ? "" : "(" + Zones.hours(off - clockLocal) + ")"
    }
    function parseClock(out) {
        var offs = {}
        out.split("\n").forEach(function (line) {
            var p = line.trim().split(/\s+/)
            if (p.length !== 2) return
            if (p[0] === "local") clockLocal = Zones.offsetSeconds(p[1])
            else offs[p[0]] = Zones.offsetSeconds(p[1])
        })
        clockOffsets = offs
    }
    function fmtUp(s) {
        var d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + "d " : "") + h + "h " + m + "m"
    }
    function push(arr, v) {
        var a = arr.slice(-(maxSamples - 1)); a.push(v); return a
    }

    function parse(out) {
        var t = [], dl = []
        var now = Date.now()
        out.split("\n").forEach(function (line) {
            var p = line.trim().split(/\s+/)
            if (p[0].indexOf("disks|") === 0) { var dk = line.trim().split("|")
                var drv = dl.filter(function (d) { return d.id === dk[1] })[0]
                if (!drv) { drv = { id: dk[1], name: dk[2], bytes: +dk[3], parts: [] }; dl.push(drv) }
                drv.parts.push({ name: dk[4], used: +dk[5], total: +dk[6] })
                return }
            if (p[0].indexOf("gpu|") === 0) { var g = line.trim().split("|")
                gpuName = g[1]; gpuKind = g[2]; gpuDrv = g[3]; gpuUtil = +g[4]; gpuVramUsed = +g[5]; gpuVramTotal = +g[6]
                gpuTemp = +g[7]; gpuPower = +g[8]; gpuMhz = +g[9]; gpuState = g[10]; gpuTempSrc = g[11] || "gpu"
                return }
            if (p[0].indexOf("sys|") === 0) { sysInfo = line.trim().substring(4).split("|"); return }
            switch (p[0]) {
            case "cpu":
                var tot = +p[1], idle = +p[2]
                if (prevCpu && tot > prevCpu[0])
                    cpu = 1 - (idle - prevCpu[1]) / (tot - prevCpu[0])
                prevCpu = [tot, idle]
                break
            case "cores":
                var cur = []
                for (var k = 1; k + 2 < p.length; k += 3) cur.push([+p[k + 1], +p[k + 2]])
                if (prevCores && prevCores.length === cur.length)
                    cores = cur.map(function (c, i) {
                        var dt = c[0] - prevCores[i][0]
                        return dt > 0 ? 1 - (c[1] - prevCores[i][1]) / dt : 0
                    })
                prevCores = cur
                break
            case "mem":
                memTotal = p[1] * 1024; memUsed = (p[1] - p[2]) * 1024
                swapTotal = p[3] * 1024; swapUsed = (p[3] - p[4]) * 1024
                break
            case "net":
                var rx = +p[1], tx = +p[2]
                // The automatic choice follows the default route, so the counters can change under us
                if (p[3] !== netIface) { prevNet = null; netIface = p[3] }
                if (prevNet && now > prevNetT) {
                    var dt = (now - prevNetT) / 1000
                    rxRate = Math.max(0, (rx - prevNet[0]) / dt)
                    txRate = Math.max(0, (tx - prevNet[1]) / dt)
                }
                prevNet = [rx, tx]; prevNetT = now
                break
            case "ip": lanIp = p[1] || ""; break
            case "extip": wanIp = p[1] || ""; break
            case "batmodel": batModel = p.slice(1).join(" "); break
            case "disk": diskUsed = +p[1]; diskTotal = +p[2]; break
            case "load": load = p[1] + "  " + p[2] + "  " + p[3]; break
            case "up": uptime = +p[1]; break
            case "temp": temp = p[1] / 1000; break
            case "freq": cpuFreq = p[1] / 1e6; break
            case "bat":
                batLevel = +p[1]; batVolts = p[2] / 1e6; batWatts = p[3] / 1e6; batSecs = +p[4]; batStatus = p.slice(5).join(" ")
                break
            case "top": t.push({ cpu: p[1], name: p.slice(2).join(" ") }); break
            }
        })
        tops = t
        disks = dl
        peakRate = Math.max(1024 * 100, peakRate * 0.98, rxRate, txRate)
        cpuHist = push(cpuHist, cpu)
        memHist = push(memHist, memUsed / memTotal)
        rxHist = push(rxHist, rxRate / peakRate)
        txHist = push(txHist, txRate / peakRate)
        tempHist = push(tempHist, Math.max(0, temp) / 100)
        batHist = push(batHist, Math.max(0, batLevel) / 100)
        batWattHist = push(batWattHist, batLevel >= 0 ? batWatts : -1)
        batVoltHist = push(batVoltHist, batLevel >= 0 ? batVolts : -1)
        diskHist = push(diskHist, diskUsed / diskTotal)
        gpuHist = push(gpuHist, Math.max(0, gpuUtil) / 100)
    }

    Timer {
        interval: 5000
        running: root.cfg.showClock && root.clockZones.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.clockNow = Date.now()
    }

    // Offsets change only with daylight saving, so look them up rarely
    P5Support.DataSource {
        engine: "executable"
        connectedSources: root.cfg.showClock && root.clockZones.length > 0
            ? ["sh '" + root.clockScript + "' '" + root.clockZones.map(function (z) { return z.tz }).join(",") + "'"] : []
        interval: 300000
        onNewData: (source, data) => { if (data["stdout"]) root.parseClock(data["stdout"]) }
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: ["sh '" + root.script + "' '" + root.cfg.diskMount.replace(/'/g, "'\\''") + "' '" + root.cfg.tempSensor.replace(/'/g, "'\\''")
                          + "' '" + root.cfg.batDevice.replace(/'/g, "'\\''") + "' '" + root.cfg.netInterface.replace(/'/g, "'\\''") + "' " + (root.cfg.showExternalIp ? "1" : "0")]
        interval: root.cfg.updateInterval
        onNewData: (source, data) => { if (data["stdout"]) root.parse(data["stdout"]) }
    }

    // A different interface has different counters, so drop the previous sample
    Connections {
        target: root.cfg
        function onNetInterfaceChanged() { root.prevNet = null; root.rxRate = 0; root.txRate = 0 }
    }

    Plasmoid.icon: Qt.resolvedUrl("../icons/plasmetrics.png")
    toolTipMainText: "System"
    toolTipSubText: "CPU " + Math.round(cpu * 100) + "%  ·  RAM " + Math.round(memUsed / memTotal * 100) + "%"

    // ---- Panel strip: label [bar] value per metric ----
    compactRepresentation: MouseArea {
        id: compact
        onClicked: root.expanded = !root.expanded
        Layout.minimumWidth: strip.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitWidth: Layout.minimumWidth

        component Metric: RowLayout {
            property string label
            property string valueText
            property real frac: 0
            property real frac2: -1
            property var hist
            property int chart: 0
            property var cores: []
            property var hist2: null
            property color col: "#4da3ff"
            property color col2: "#ff453a"
            property real valueScale: 1
            property bool showLabel: true
            property int display: 2
            spacing: 4

            Item {
                visible: parent.showLabel
                implicitWidth: root.cfg.verticalLabels ? labelText.implicitHeight : labelText.implicitWidth
                implicitHeight: root.cfg.verticalLabels ? labelText.implicitWidth : labelText.implicitHeight
                Text {
                    id: labelText
                    anchors.centerIn: parent
                    rotation: root.cfg.verticalLabels ? -90 : 0
                    text: label
                    color: Kirigami.Theme.textColor
                    opacity: 0.65
                    font.family: root.fontFam
                    font.pixelSize: Math.max(6, root.px * 0.8)
                    font.bold: true
                }
            }
            VBar {
                visible: parent.display !== 1 && [0, 3, 4].indexOf(parent.chart) >= 0
                Layout.preferredHeight: Math.round(root.px * 1.8)
                frac: parent.frac; frac2: parent.frac2
                color: parent.col; color2: parent.col2
            }
            MiniChart {
                visible: parent.display !== 1 && [1, 4].indexOf(parent.chart) >= 0
                Layout.preferredWidth: 38
                Layout.preferredHeight: Math.round(root.px * 1.8)
                values: parent.hist; values2: parent.hist2
                color: parent.col; color2: parent.col2
            }
            CoreGrid {
                visible: parent.display !== 1 && [2, 3, 4].indexOf(parent.chart) >= 0
                Layout.preferredHeight: Math.round(root.px * 1.8)
                values: parent.cores
            }
            Text {
                visible: parent.display !== 0
                text: valueText
                color: Kirigami.Theme.textColor
                font.family: root.fontFam
                font.pixelSize: Math.max(6, root.px * valueScale)
                font.weight: root.cfg.fontBold ? Font.DemiBold : Font.Normal
                lineHeight: 0.85
            }
        }

        // World clock: each zone is a vertical code on the left, then "09:41 (-5h)" on one line
        component ClockRows: RowLayout {
            id: clockRows
            spacing: Kirigami.Units.largeSpacing
            Repeater {
                model: root.clockZones
                RowLayout {
                    spacing: 4
                    Item {
                        readonly property bool upright: Zones.hasEmoji(modelData.code)
                        implicitWidth: upright ? codeText.implicitWidth : codeText.implicitHeight
                        implicitHeight: upright ? codeText.implicitHeight : codeText.implicitWidth
                        Text {
                            id: codeText
                            anchors.centerIn: parent
                            rotation: parent.upright ? 0 : -90
                            text: modelData.code
                            color: Kirigami.Theme.textColor
                            opacity: parent.upright ? 1 : 0.65
                            font.family: root.fontFam
                            font.pixelSize: Math.max(6, root.px * (parent.upright ? 1.1 : 0.8))   // letters match the other labels
                            font.bold: !parent.upright
                        }
                    }
                    Text {
                        text: root.clockText(modelData.tz, false)
                        color: Kirigami.Theme.textColor
                        font.family: root.fontFam
                        font.pixelSize: root.px * 1.1
                        font.weight: root.cfg.fontBold ? Font.DemiBold : Font.Normal
                    }
                    Text {
                        text: root.clockOffsetText(modelData.tz)
                        Layout.alignment: Qt.AlignBaseline
                        color: Kirigami.Theme.textColor
                        opacity: 0.65
                        font.family: root.fontFam
                        font.pixelSize: Math.max(6, root.px * 0.7)
                    }
                }
            }
        }

        RowLayout {
            id: strip
            anchors.centerIn: parent
            spacing: root.cfg.itemGap
            Repeater {
                model: root.order
                RowLayout {
                    spacing: 0
                    visible: modelData === "clock" ? root.cfg.showClock && root.clockZones.length > 0 : d.on
                    readonly property var d: root.metricData(modelData)
                    Metric {
                        visible: modelData !== "clock"
                        showLabel: d.showLabel; display: d.display
                        label: d.label; valueText: d.text; valueScale: d.scale
                        chart: d.chart; cores: modelData === "cpu" ? root.cores : []
                        frac: d.frac; frac2: d.frac2; hist: d.hist; hist2: d.hist2
                        col: d.col; col2: d.col2
                    }
                    ClockRows { visible: modelData === "clock" }
                }
            }
        }
    }

    // ---- Popup: one card per metric ----
    fullRepresentation: PlasmaComponents.ScrollView {
        id: scroll
        // Fixed, not in grid units: those grow with the system font, which made the popup far wider on some machines
        Layout.preferredWidth: 324
        Layout.minimumWidth: 324
        Layout.maximumWidth: 324
        Layout.minimumHeight: stack.implicitHeight + Kirigami.Units.smallSpacing * 2 + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: stack.implicitHeight + Kirigami.Units.smallSpacing * 2 + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: stack
            width: scroll.availableWidth
            x: 0
            y: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Section {
                title: "CPU"
                accent: root.tint(root.cfg.cpuColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.cpu * 100) + "%"
                history: root.cpuHist
                subtitle: "Load  " + root.load + (root.cpuFreq >= 0 ? "      Freq  " + root.cpuFreq.toFixed(2) + " GHz" : "") + (root.temp >= 0 ? "      Temp  " + root.fmtTemp(root.temp) : "")
                // Per core / thread: 4 equal fixed-width cells per row, bar + percentage
                GridLayout {
                    id: coreGrid
                    visible: root.cores.length > 0
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: Kirigami.Units.smallSpacing * 2
                    rowSpacing: 3
                    // From the popup width (card margins removed), not this grid's own width, which depends on the cells
                    readonly property real cellW: Math.max(0, (stack.width - Kirigami.Units.smallSpacing * 3 - columnSpacing * (columns - 1)) / columns)
                    TextMetrics { id: pctWidth; text: "100%"; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.8 }
                    Repeater {
                        model: root.cores
                        RowLayout {
                            Layout.preferredWidth: coreGrid.cellW
                            Layout.minimumWidth: coreGrid.cellW
                            Layout.maximumWidth: coreGrid.cellW
                            spacing: 4
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                Rectangle {
                                    width: parent.width * Math.min(1, Math.max(0, modelData))
                                    height: parent.height
                                    radius: 3
                                    color: root.usageColor(modelData)
                                }
                            }
                            Text {
                                Layout.preferredWidth: pctWidth.width
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(modelData * 100) + "%"
                                color: Kirigami.Theme.textColor
                                font.family: root.fontFam
                                font.pointSize: root.cfg.popupFontSize * 0.8
                            }
                        }
                    }
                }
                Repeater {
                    model: root.tops.slice(0, root.cfg.topProcesses)
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: modelData.name; color: Kirigami.Theme.textColor; elide: Text.ElideRight; Layout.fillWidth: true; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.85 }
                        Text { text: modelData.cpu + "%"; color: Kirigami.Theme.textColor; opacity: 0.7; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.85 }
                    }
                }
            }
            Section {
                visible: root.gpuState !== ""
                title: "GPU  " + root.gpuName
                accent: root.tint(root.cfg.gpuColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: root.gpuUtil >= 0 ? Math.round(root.gpuUtil) + "%" : "–"
                history: root.gpuUtil >= 0 ? root.gpuHist : null
                subtitle: root.gpuSubtitle()
            }
            Section {
                title: "Memory"
                accent: root.tint(root.cfg.memColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.memUsed / root.memTotal * 100) + "%"
                history: root.memHist
                subtitle: root.fmtBytes(root.memUsed) + " of " + root.fmtBytes(root.memTotal)
                    + (root.swapTotal > 0 ? "      Swap  " + root.fmtBytes(root.swapUsed) : "")
            }
            Section {
                title: "Network"
                accent: root.tint(root.cfg.downColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: "↓ " + root.fmtRate(root.rxRate)
                subtitle: "↑ " + root.fmtRate(root.txRate)
                    + (root.lanIp !== "" ? "\nLocal  " + root.lanIp : "") + (root.wanIp !== "" ? (root.lanIp !== "" ? "      " : "\n") + "Public  " + root.wanIp : "")
                history: root.rxHist
                Spark {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    values: root.txHist
                    color: root.tint(root.cfg.upColor)
                }
            }
            Section {
                visible: root.batLevel >= 0
                title: "Battery" + (root.batModel !== "" ? "  " + root.batModel : "")
                accent: root.tint(root.cfg.batColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.batLevel) + "%" + root.batCharging
                subtitle: root.batStatus + (root.batSecs >= 0 ? "      " + root.fmtDuration(root.batSecs) + (root.batStatus === "Charging" ? " until full" : " remaining") : "")
                LineChart {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    values: root.batWattHist
                    values2: root.batVoltHist
                    color: "#ff9f0a"
                    color2: "#64d2ff"
                    min1: 5
                    min2: 1
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Repeater {
                        model: [
                            { name: "Wattage", value: root.fmtWatts(root.batWatts), col: "#ff9f0a" },
                            { name: "Voltage", value: root.fmtVolts(root.batVolts), col: "#64d2ff" }
                        ]
                        RowLayout {
                            spacing: 4
                            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 3; radius: 1.5; color: modelData.col }
                            Text {
                                text: modelData.name + "  " + modelData.value
                                color: Kirigami.Theme.textColor
                                font.family: root.fontFam
                                font.pointSize: root.cfg.popupFontSize * 0.85
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }
            Section {
                visible: root.cfg.showClock && root.clockZones.length > 0
                title: "World clock"
                accent: root.tint(root.cfg.clockColor)
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: ""
                Repeater {
                    model: root.clockZones
                    RowLayout {
                        Layout.fillWidth: true
                        readonly property real off: root.clockOffsets[modelData.tz] === undefined ? NaN : root.clockOffsets[modelData.tz]
                        readonly property int day: isNaN(off) ? 0 : Zones.dayShift(root.clockNow, off, root.clockLocal)
                        Text { text: modelData.code; Layout.preferredWidth: 34; font.bold: true; color: Kirigami.Theme.textColor; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.9 }
                        Text { text: Zones.city(modelData.tz); Layout.fillWidth: true; elide: Text.ElideRight; color: Kirigami.Theme.textColor; opacity: 0.7; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.85 }
                        Text { visible: parent.day !== 0; text: parent.day > 0 ? "+1 day" : "−1 day"; color: Kirigami.Theme.textColor; opacity: 0.5; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.75 }
                        Text { text: root.clockText(modelData.tz, false); color: Kirigami.Theme.textColor; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.95; font.weight: Font.DemiBold }
                        Text { text: isNaN(parent.off) ? "" : "(" + Zones.hours(parent.off - root.clockLocal) + ")"; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; color: Kirigami.Theme.textColor; opacity: 0.6; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.85 }
                    }
                }
            }
            Repeater {
                model: root.cfg.showDisk ? root.disks : []
                Section {
                    id: driveCard
                    required property var modelData
                    readonly property real used: modelData.parts.reduce(function (a, q) { return a + q.used }, 0)
                    readonly property real cap: Math.max(modelData.bytes, modelData.parts.reduce(function (a, q) { return a + q.total }, 0))
                    readonly property var colors: [root.tint(root.cfg.diskColor), "#ff9f0a", "#64d2ff", "#ff375f", "#ffd60a", "#5e5ce6"]
                    title: "Disk  " + modelData.name
                    accent: root.tint(root.cfg.diskColor)
                    fontFamily: root.fontFam
                    baseSize: root.cfg.popupFontSize
                    value: Math.round(used / cap * 100) + "%"
                    subtitle: root.fmtBytes(used) + " of " + root.fmtBytes(cap)
                    // One bar per physical drive, a coloured segment per partition
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6; radius: 3
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Row {
                            anchors.fill: parent
                            spacing: 2
                            Repeater {
                                model: driveCard.modelData.parts
                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: Math.max(2, (parent.width) * modelData.used / driveCard.cap)
                                    height: parent.height; radius: 3
                                    color: driveCard.colors[index % driveCard.colors.length]
                                }
                            }
                        }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: driveCard.modelData.parts
                            RowLayout {
                                required property var modelData
                                required property int index
                                spacing: 4
                                Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: driveCard.colors[index % driveCard.colors.length] }
                                Text {
                                    text: modelData.name + "  " + root.fmtBytes(modelData.used)
                                    color: Kirigami.Theme.textColor; opacity: 0.65
                                    font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.8
                                }
                            }
                        }
                    }
                }
            }
            Section {
                visible: root.cfg.showSysInfo && root.sysInfo.length >= 6
                title: "System"
                accent: Kirigami.Theme.textColor
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: ""
                // One titled row per fact
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: 2
                    TextMetrics { id: sysLabelW; text: "Hostname"; font.family: root.fontFam; font.pointSize: root.cfg.popupFontSize * 0.85 }
                    Repeater {
                        model: root.sysInfo.length < 6 ? [] : [
                            ["Model", root.sysInfo[0].trim()],
                            ["CPU", root.sysInfo[1] + " · " + root.sysInfo[2] + " threads"],
                            ["Memory", root.fmtBytes(root.memTotal)],
                            ["OS", root.sysInfo[3]],
                            ["Kernel", root.sysInfo[4]],
                            ["Hostname", root.sysInfo[5]]
                        ]
                        delegate: Item {
                            // Label and value share a row; Item keeps the two grid cells in step
                            required property var modelData
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            implicitHeight: valueText.implicitHeight
                            Text {
                                width: sysLabelW.width
                                text: modelData[0]
                                color: Kirigami.Theme.textColor
                                opacity: 0.55
                                font.family: root.fontFam
                                font.pointSize: root.cfg.popupFontSize * 0.85
                            }
                            Text {
                                id: valueText
                                x: sysLabelW.width + Kirigami.Units.largeSpacing
                                width: parent.width - x
                                text: modelData[1]
                                wrapMode: Text.WordWrap
                                color: Kirigami.Theme.textColor
                                font.family: root.fontFam
                                font.pointSize: root.cfg.popupFontSize * 0.85
                            }
                        }
                    }
                }
            }
            Text {
                visible: root.cfg.showUptime
                text: "Uptime  " + root.fmtUp(root.uptime)
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.8)
                font.family: root.fontFam
                font.pointSize: root.cfg.popupFontSize * 0.85
                Layout.alignment: Qt.AlignHCenter
            }
            ColumnLayout {
                readonly property var meta: Plasmoid.metaData
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing
                Text {
                    text: parent.meta.name + " " + parent.meta.version + "  ·  " + parent.meta.license
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.8)
                    font.family: root.fontFam
                    font.pointSize: root.cfg.popupFontSize * 0.85
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing
                    Repeater {
                        model: [
                            { icon: "internet-services", text: "GitHub", url: Plasmoid.metaData.website },
                            { icon: "tools-report-bug", text: "Report a bug", url: Plasmoid.metaData.bugReportUrl },
                            { icon: "help-donate", text: "Buy me a coffee", url: "https://buymeacoffee.com/chinsta" }
                        ]
                        RowLayout {
                            required property var modelData
                            spacing: 4
                            opacity: link.hovered ? 1 : 0.85
                            Kirigami.Icon { source: modelData.icon; implicitWidth: 14; implicitHeight: 14; color: Kirigami.Theme.textColor }
                            Text {
                                text: modelData.text
                                color: Kirigami.Theme.textColor
                                font.family: root.fontFam
                                font.pointSize: root.cfg.popupFontSize * 0.85
                                font.underline: link.hovered
                            }
                            HoverHandler { id: link; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Qt.openUrlExternally(modelData.url) }
                        }
                    }
                }
            }
        }
    }
}
