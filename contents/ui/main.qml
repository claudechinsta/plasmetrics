import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property int maxSamples: 60
    property real cpu: 0
    property real memUsed: 0
    property real memTotal: 1
    property real swapUsed: 0
    property real swapTotal: 0
    property real rxRate: 0
    property real txRate: 0
    property real diskUsed: 0
    property real diskTotal: 1
    property real temp: -1
    property string load: ""
    property int uptime: 0
    property var tops: []
    property var cpuHist: Array(60).fill(0)
    property var memHist: Array(60).fill(0)
    property var rxHist: Array(60).fill(0)
    property var txHist: Array(60).fill(0)
    property var tempHist: Array(60).fill(0)
    property var diskHist: Array(60).fill(0)
    property real peakRate: 1024 * 100
    property var prevCpu: null
    property var prevNet: null
    property double prevNetT: 0

    readonly property var cfg: Plasmoid.configuration
    readonly property string fontFam: cfg.useCustomFont && cfg.fontFamily !== "" ? cfg.fontFamily : Kirigami.Theme.defaultFont.family
    readonly property int px: cfg.panelFontSize

    readonly property string script: Qt.resolvedUrl("../code/stats.sh").toString().replace("file://", "")

    readonly property var order: {
        var keys = ["cpu", "mem", "net", "temp", "disk"], out = []
        cfg.metricOrder.split(",").forEach(function (k) { if (keys.indexOf(k) >= 0 && out.indexOf(k) < 0) out.push(k) })
        keys.forEach(function (k) { if (out.indexOf(k) < 0) out.push(k) })
        return out
    }

    // Everything the panel strip needs to draw one metric
    function metricData(key) {
        var pct = function (f) { return Math.round(f * 100) + "%" }
        switch (key) {
        case "cpu":
            return { on: cfg.showCpu, label: "CPU", showLabel: cfg.cpuLabel, display: cfg.cpuDisplay, text: pct(cpu), scale: 1,
                     frac: cpu, frac2: -1, hist: cpuHist, hist2: null, col: cfg.cpuColor, col2: "#000000" }
        case "mem":
            return { on: cfg.showMem, label: "MEM", showLabel: cfg.memLabel, display: cfg.memDisplay, text: pct(memUsed / memTotal), scale: 1,
                     frac: memUsed / memTotal, frac2: -1, hist: memHist, hist2: null, col: cfg.memColor, col2: "#000000" }
        case "net":
            return { on: cfg.showNet, label: "NET", showLabel: cfg.netLabel, display: cfg.netDisplay,
                     text: "↓ " + fmtRate(rxRate) + "\n↑ " + fmtRate(txRate), scale: 0.8,
                     frac: rxRate / peakRate, frac2: txRate / peakRate, hist: rxHist, hist2: txHist,
                     col: cfg.downColor, col2: cfg.upColor }
        case "temp":
            return { on: cfg.showTemp && temp >= 0, label: "TEMP", showLabel: cfg.tempLabel, display: cfg.tempDisplay, text: fmtTemp(temp), scale: 1,
                     frac: temp / 100, frac2: -1, hist: tempHist, hist2: null, col: cfg.tempColor, col2: "#000000" }
        default:
            return { on: cfg.showDiskPanel, label: "DISK", showLabel: cfg.diskLabel, display: cfg.diskDisplay, text: pct(diskUsed / diskTotal), scale: 1,
                     frac: diskUsed / diskTotal, frac2: -1, hist: diskHist, hist2: null, col: cfg.diskColor, col2: "#000000" }
        }
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
    function fmtUp(s) {
        var d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + "d " : "") + h + "h " + m + "m"
    }
    function push(arr, v) {
        var a = arr.slice(-(maxSamples - 1)); a.push(v); return a
    }

    function parse(out) {
        var t = []
        var now = Date.now()
        out.split("\n").forEach(function (line) {
            var p = line.trim().split(/\s+/)
            switch (p[0]) {
            case "cpu":
                var tot = +p[1], idle = +p[2]
                if (prevCpu && tot > prevCpu[0])
                    cpu = 1 - (idle - prevCpu[1]) / (tot - prevCpu[0])
                prevCpu = [tot, idle]
                break
            case "mem":
                memTotal = p[1] * 1024; memUsed = (p[1] - p[2]) * 1024
                swapTotal = p[3] * 1024; swapUsed = (p[3] - p[4]) * 1024
                break
            case "net":
                var rx = +p[1], tx = +p[2]
                if (prevNet && now > prevNetT) {
                    var dt = (now - prevNetT) / 1000
                    rxRate = Math.max(0, (rx - prevNet[0]) / dt)
                    txRate = Math.max(0, (tx - prevNet[1]) / dt)
                }
                prevNet = [rx, tx]; prevNetT = now
                break
            case "disk": diskUsed = +p[1]; diskTotal = +p[2]; break
            case "load": load = p[1] + "  " + p[2] + "  " + p[3]; break
            case "up": uptime = +p[1]; break
            case "temp": temp = p[1] / 1000; break
            case "top": t.push({ cpu: p[1], name: p.slice(2).join(" ") }); break
            }
        })
        tops = t
        peakRate = Math.max(1024 * 100, peakRate * 0.98, rxRate, txRate)
        cpuHist = push(cpuHist, cpu)
        memHist = push(memHist, memUsed / memTotal)
        rxHist = push(rxHist, rxRate / peakRate)
        txHist = push(txHist, txRate / peakRate)
        tempHist = push(tempHist, Math.max(0, temp) / 100)
        diskHist = push(diskHist, diskUsed / diskTotal)
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: ["sh '" + root.script + "' '" + root.cfg.diskMount.replace(/'/g, "'\\''") + "'"]
        interval: root.cfg.updateInterval
        onNewData: (source, data) => { if (data["stdout"]) root.parse(data["stdout"]) }
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
            property var hist2: null
            property color col: "#4da3ff"
            property color col2: "#ff453a"
            property real valueScale: 1
            property bool showLabel: true
            property int display: 2
            spacing: 4

            Text {
                visible: parent.showLabel
                text: label
                color: Kirigami.Theme.textColor
                opacity: 0.65
                font.family: root.fontFam
                font.pixelSize: Math.max(6, root.px * 0.8)
                font.bold: true
            }
            VBar {
                visible: parent.display !== 1 && root.cfg.barStyle === 0
                Layout.preferredHeight: Math.round(root.px * 1.8)
                frac: parent.frac; frac2: parent.frac2
                color: parent.col; color2: parent.col2
            }
            MiniChart {
                visible: parent.display !== 1 && root.cfg.barStyle === 1
                Layout.preferredWidth: 38
                Layout.preferredHeight: Math.round(root.px * 1.8)
                values: parent.hist; values2: parent.hist2
                color: parent.col; color2: parent.col2
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

        RowLayout {
            id: strip
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing
            Repeater {
                model: root.order
                Metric {
                    readonly property var d: root.metricData(modelData)
                    visible: d.on
                    showLabel: d.showLabel; display: d.display
                    label: d.label; valueText: d.text; valueScale: d.scale
                    frac: d.frac; frac2: d.frac2; hist: d.hist; hist2: d.hist2
                    col: d.col; col2: d.col2
                }
            }
        }
    }

    // ---- Popup: one card per metric ----
    fullRepresentation: PlasmaComponents.ScrollView {
        id: scroll
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Math.min(stack.implicitHeight + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 20)
        Layout.preferredHeight: stack.implicitHeight + Kirigami.Units.smallSpacing * 2

        ColumnLayout {
            id: stack
            width: scroll.availableWidth - Kirigami.Units.smallSpacing * 2
            x: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Section {
                title: "CPU"
                accent: root.cfg.cpuColor
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.cpu * 100) + "%"
                history: root.cpuHist
                subtitle: "Load  " + root.load + (root.temp >= 0 ? "      Temp  " + root.fmtTemp(root.temp) : "")
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
                title: "Memory"
                accent: root.cfg.memColor
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.memUsed / root.memTotal * 100) + "%"
                history: root.memHist
                subtitle: root.fmtBytes(root.memUsed) + " of " + root.fmtBytes(root.memTotal)
                    + (root.swapTotal > 0 ? "      Swap  " + root.fmtBytes(root.swapUsed) : "")
            }
            Section {
                title: "Network"
                accent: root.cfg.downColor
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: "↓ " + root.fmtRate(root.rxRate)
                subtitle: "↑ " + root.fmtRate(root.txRate)
                history: root.rxHist
                Spark {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    values: root.txHist
                    color: root.cfg.upColor
                }
            }
            Section {
                visible: root.cfg.showDisk
                title: "Disk  " + root.cfg.diskMount
                accent: root.cfg.diskColor
                fontFamily: root.fontFam
                baseSize: root.cfg.popupFontSize
                value: Math.round(root.diskUsed / root.diskTotal * 100) + "%"
                fraction: root.diskUsed / root.diskTotal
                subtitle: root.fmtBytes(root.diskUsed) + " of " + root.fmtBytes(root.diskTotal)
            }
            Text {
                visible: root.cfg.showUptime
                text: "Uptime  " + root.fmtUp(root.uptime)
                color: Kirigami.Theme.textColor; opacity: 0.55
                font.family: root.fontFam
                font.pointSize: root.cfg.popupFontSize * 0.85
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
