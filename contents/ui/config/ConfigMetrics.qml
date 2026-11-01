import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: page

    property string cfg_diskMount
    property string cfg_diskMountDefault
    property string cfg_metricOrder
    property string cfg_metricOrderDefault
    property bool cfg_showCpu
    property alias cfg_cpuLabel: cpuLabel.checked
    property alias cfg_cpuDisplay: cpuDisplay.currentIndex
    property alias cfg_cpuChart: cpuChart.currentIndex
    property alias cfg_cpuColor: cpuColorBox.colorString
    property bool cfg_showMem
    property alias cfg_memLabel: memLabel.checked
    property alias cfg_memDisplay: memDisplay.currentIndex
    property alias cfg_memColor: memColorBox.colorString
    property bool cfg_showNet
    property alias cfg_netLabel: netLabel.checked
    property alias cfg_netDisplay: netDisplay.currentIndex
    property string cfg_netInterface
    property alias cfg_downColor: downColorBox.colorString
    property alias cfg_upColor: upColorBox.colorString
    property bool cfg_showTemp
    property alias cfg_tempLabel: tempLabel.checked
    property alias cfg_tempDisplay: tempDisplay.currentIndex
    property string cfg_tempSensor
    property alias cfg_tempColor: tempColorBox.colorString
    property bool cfg_showBat
    property alias cfg_batLabel: batLabel.checked
    property alias cfg_batDisplay: batDisplay.currentIndex
    property alias cfg_batValue: batValue.currentIndex
    property string cfg_batDevice
    property alias cfg_batColor: batColorBox.colorString
    property bool cfg_showDiskPanel
    property alias cfg_diskLabel: diskLabel.checked
    property alias cfg_diskDisplay: diskDisplay.currentIndex
    property alias cfg_diskColor: diskColorBox.colorString

    property bool cfg_showCpuDefault
    property bool cfg_cpuLabelDefault
    property int cfg_cpuDisplayDefault
    property int cfg_cpuChartDefault
    property string cfg_cpuColorDefault
    property bool cfg_showMemDefault
    property bool cfg_memLabelDefault
    property int cfg_memDisplayDefault
    property string cfg_memColorDefault
    property bool cfg_showNetDefault
    property bool cfg_netLabelDefault
    property int cfg_netDisplayDefault
    property string cfg_netInterfaceDefault
    property string cfg_downColorDefault
    property string cfg_upColorDefault
    property bool cfg_showTempDefault
    property bool cfg_tempLabelDefault
    property int cfg_tempDisplayDefault
    property string cfg_tempSensorDefault
    property string cfg_tempColorDefault
    property bool cfg_showBatDefault
    property bool cfg_batLabelDefault
    property int cfg_batDisplayDefault
    property int cfg_batValueDefault
    property string cfg_batDeviceDefault
    property string cfg_batColorDefault
    property bool cfg_showDiskPanelDefault
    property bool cfg_diskLabelDefault
    property int cfg_diskDisplayDefault
    property string cfg_diskColorDefault

    readonly property var keys: ["cpu", "mem", "net", "temp", "bat", "disk"]
    readonly property var titles: ({ cpu: i18n("CPU"), mem: i18n("Memory"), net: i18n("Network"), temp: i18n("Temperature"), bat: i18n("Battery"), disk: i18n("Disk") })
    property string selected: "cpu"
    property var mounts: []
    property var batteries: [{ key: "", text: i18n("System battery (automatic)") }]
    property var interfaces: [{ key: "", text: i18n("Default route (automatic)") }]
    property var sensors: [{ key: "", text: i18n("CPU (automatic)") }]

    // Saved order, with any missing or unknown keys repaired
    readonly property var order: {
        var out = []
        cfg_metricOrder.split(",").forEach(function (k) { if (keys.indexOf(k) >= 0 && out.indexOf(k) < 0) out.push(k) })
        keys.forEach(function (k) { if (out.indexOf(k) < 0) out.push(k) })
        return out
    }

    function isOn(k) {
        switch (k) {
        case "cpu": return cfg_showCpu
        case "mem": return cfg_showMem
        case "net": return cfg_showNet
        case "temp": return cfg_showTemp
        case "bat": return cfg_showBat
        default: return cfg_showDiskPanel
        }
    }
    function setOn(k, v) {
        switch (k) {
        case "cpu": cfg_showCpu = v; break
        case "mem": cfg_showMem = v; break
        case "net": cfg_showNet = v; break
        case "temp": cfg_showTemp = v; break
        case "bat": cfg_showBat = v; break
        default: cfg_showDiskPanel = v
        }
    }
    function move(delta) {
        var arr = order.slice()
        var i = arr.indexOf(selected), j = i + delta
        if (j < 0 || j >= arr.length) return
        arr[i] = arr[j]; arr[j] = selected
        cfg_metricOrder = arr.join(",")
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["df -B1 --output=target,size -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay | tail -n +2"]
        onNewData: (source, data) => {
            var list = []
            ;(data["stdout"] || "").split("\n").forEach(function (l) {
                var m = l.trim().match(/^(.*\S)\s+(\d+)$/)
                if (m) list.push({ path: m[1], text: m[1] + "  (" + (m[2] / 1e9).toFixed(0) + " GB)" })
            })
            mounts = list
            disconnectSource(source)
        }
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["sh '" + Qt.resolvedUrl("../../code/devices.sh").toString().replace("file://", "") + "'"]
        onNewData: (source, data) => {
            var bats = [{ key: "", text: i18n("System battery (automatic)") }]
            var nets = [{ key: "", text: i18n("Default route (automatic)") }]
            ;(data["stdout"] || "").split("\n").forEach(function (l) {
                var p = l.split("|")
                if (p[0] === "bat" && p.length >= 4)
                    bats.push({ key: p[1], text: p[1] + (p[2] ? " – " + p[2] : "") + (p[3] ? "  (" + p[3] + "%)" : "") })
                else if (p[0] === "net" && p.length >= 3)
                    nets.push({ key: p[1], text: p[1] + (p[2] ? "  (" + p[2] + ")" : "") })
            })
            batteries = bats
            interfaces = nets
            disconnectSource(source)
        }
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["sh '" + Qt.resolvedUrl("../../code/sensors.sh").toString().replace("file://", "") + "'"]
        onNewData: (source, data) => {
            var list = [{ key: "", text: i18n("CPU (automatic)") }]
            ;(data["stdout"] || "").split("\n").forEach(function (l) {
                var p = l.split("|")
                if (p.length < 3 || p[0].indexOf("/") < 0) return
                var name = p[0].split("/")[0] + (p[1] ? " – " + p[1] : " – " + p[0].split("/")[1])
                list.push({ key: p[0], text: name + "  (" + (p[2] / 1000).toFixed(0) + " °C)" })
            })
            sensors = list
            disconnectSource(source)
        }
    }

    RowLayout {
        spacing: Kirigami.Units.largeSpacing

        // Metric list: checkbox = shown in panel, order = panel order
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            spacing: 0

            Repeater {
                model: page.order
                QQC2.ItemDelegate {
                    Layout.fillWidth: true
                    highlighted: page.selected === modelData
                    onClicked: page.selected = modelData
                    contentItem: RowLayout {
                        QQC2.CheckBox {
                            checked: page.isOn(modelData)
                            onToggled: page.setOn(modelData, checked)
                        }
                        QQC2.Label {
                            text: page.titles[modelData]
                            opacity: page.isOn(modelData) ? 1 : 0.55
                            Layout.fillWidth: true
                        }
                    }
                }
            }
            RowLayout {
                Layout.topMargin: Kirigami.Units.smallSpacing
                QQC2.Button {
                    icon.name: "go-up"
                    text: i18n("Move up")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: page.order.indexOf(page.selected) > 0
                    onClicked: page.move(-1)
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                }
                QQC2.Button {
                    icon.name: "go-down"
                    text: i18n("Move down")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: page.order.indexOf(page.selected) < page.order.length - 1
                    onClicked: page.move(1)
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                }
            }
        }

        Kirigami.Separator { Layout.fillHeight: true }

        // Options for the selected metric only
        StackLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            currentIndex: page.keys.indexOf(page.selected)

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("CPU") }
                QQC2.CheckBox { id: cpuLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: cpuDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Percentage"), i18n("Chart + percentage")]
                }
                QQC2.ComboBox {
                    id: cpuChart
                    Kirigami.FormData.label: i18n("Chart:")
                    model: [i18n("Vertical bar"), i18n("History"), i18n("Cores"), i18n("Vertical bar & cores"), i18n("All")]
                }
                PaletteBox { id: cpuColorBox; Kirigami.FormData.label: i18n("Color:") }
            }

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Memory") }
                QQC2.CheckBox { id: memLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: memDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Percentage"), i18n("Chart + percentage")]
                }
                PaletteBox { id: memColorBox; Kirigami.FormData.label: i18n("Color:") }
            }

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Network") }
                QQC2.CheckBox { id: netLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: netDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Speed"), i18n("Chart + speed")]
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: i18n("Interface:")
                    model: page.interfaces
                    textRole: "text"
                    implicitContentWidthPolicy: QQC2.ComboBox.ContentItemImplicitWidth
                    currentIndex: {
                        for (var i = 0; i < page.interfaces.length; i++)
                            if (page.interfaces[i].key === page.cfg_netInterface) return i
                        return 0
                    }
                    onActivated: (i) => page.cfg_netInterface = page.interfaces[i].key
                }
                PaletteBox { id: downColorBox; Kirigami.FormData.label: i18n("Download color:") }
                PaletteBox { id: upColorBox; Kirigami.FormData.label: i18n("Upload color:") }
            }

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Temperature") }
                QQC2.CheckBox { id: tempLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: tempDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Value"), i18n("Chart + value")]
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: i18n("Sensor:")
                    model: page.sensors
                    textRole: "text"
                    implicitContentWidthPolicy: QQC2.ComboBox.ContentItemImplicitWidth
                    currentIndex: {
                        for (var i = 0; i < page.sensors.length; i++)
                            if (page.sensors[i].key === page.cfg_tempSensor || page.sensors[i].key.split("@")[0] === page.cfg_tempSensor) return i
                        return 0
                    }
                    onActivated: (i) => page.cfg_tempSensor = page.sensors[i].key
                }
                PaletteBox { id: tempColorBox; Kirigami.FormData.label: i18n("Color:") }
            }

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Battery") }
                QQC2.CheckBox { id: batLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: batDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Value"), i18n("Chart + value")]
                }
                QQC2.ComboBox {
                    id: batValue
                    Kirigami.FormData.label: i18n("Value:")
                    model: [i18n("Level"), i18n("Wattage"), i18n("Voltage")]
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: i18n("Device:")
                    model: page.batteries
                    textRole: "text"
                    implicitContentWidthPolicy: QQC2.ComboBox.ContentItemImplicitWidth
                    currentIndex: {
                        for (var i = 0; i < page.batteries.length; i++)
                            if (page.batteries[i].key === page.cfg_batDevice) return i
                        return 0
                    }
                    onActivated: (i) => page.cfg_batDevice = page.batteries[i].key
                }
                PaletteBox { id: batColorBox; Kirigami.FormData.label: i18n("Color:") }
            }

            Kirigami.FormLayout {
                Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Disk") }
                QQC2.CheckBox { id: diskLabel; Kirigami.FormData.label: i18n("Label:"); text: i18n("Show label") }
                QQC2.ComboBox {
                    id: diskDisplay
                    Kirigami.FormData.label: i18n("Display:")
                    model: [i18n("Chart"), i18n("Percentage"), i18n("Chart + percentage")]
                }
                PaletteBox { id: diskColorBox; Kirigami.FormData.label: i18n("Color:") }
                QQC2.ComboBox {
                    Kirigami.FormData.label: i18n("Disk:")
                    model: page.mounts
                    textRole: "text"
                    implicitContentWidthPolicy: QQC2.ComboBox.ContentItemImplicitWidth
                    currentIndex: {
                        for (var i = 0; i < page.mounts.length; i++)
                            if (page.mounts[i].path === page.cfg_diskMount) return i
                        return -1
                    }
                    onActivated: (i) => page.cfg_diskMount = page.mounts[i].path
                }
            }
        }
    }
}
