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
    property alias cfg_cpuColor: cpuColorBox.colorString
    property bool cfg_showMem
    property alias cfg_memLabel: memLabel.checked
    property alias cfg_memDisplay: memDisplay.currentIndex
    property alias cfg_memColor: memColorBox.colorString
    property bool cfg_showNet
    property alias cfg_netLabel: netLabel.checked
    property alias cfg_netDisplay: netDisplay.currentIndex
    property alias cfg_downColor: downColorBox.colorString
    property alias cfg_upColor: upColorBox.colorString
    property bool cfg_showTemp
    property alias cfg_tempLabel: tempLabel.checked
    property alias cfg_tempDisplay: tempDisplay.currentIndex
    property alias cfg_tempColor: tempColorBox.colorString
    property bool cfg_showDiskPanel
    property alias cfg_diskLabel: diskLabel.checked
    property alias cfg_diskDisplay: diskDisplay.currentIndex
    property alias cfg_diskColor: diskColorBox.colorString

    property bool cfg_showCpuDefault
    property bool cfg_cpuLabelDefault
    property int cfg_cpuDisplayDefault
    property string cfg_cpuColorDefault
    property bool cfg_showMemDefault
    property bool cfg_memLabelDefault
    property int cfg_memDisplayDefault
    property string cfg_memColorDefault
    property bool cfg_showNetDefault
    property bool cfg_netLabelDefault
    property int cfg_netDisplayDefault
    property string cfg_downColorDefault
    property string cfg_upColorDefault
    property bool cfg_showTempDefault
    property bool cfg_tempLabelDefault
    property int cfg_tempDisplayDefault
    property string cfg_tempColorDefault
    property bool cfg_showDiskPanelDefault
    property bool cfg_diskLabelDefault
    property int cfg_diskDisplayDefault
    property string cfg_diskColorDefault

    readonly property var keys: ["cpu", "mem", "net", "temp", "disk"]
    readonly property var titles: ({ cpu: i18n("CPU"), mem: i18n("Memory"), net: i18n("Network"), temp: i18n("Temperature"), disk: i18n("Disk") })
    property string selected: "cpu"
    property var mounts: []

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
        default: return cfg_showDiskPanel
        }
    }
    function setOn(k, v) {
        switch (k) {
        case "cpu": cfg_showCpu = v; break
        case "mem": cfg_showMem = v; break
        case "net": cfg_showNet = v; break
        case "temp": cfg_showTemp = v; break
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
                PaletteBox { id: tempColorBox; Kirigami.FormData.label: i18n("Color:") }
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
