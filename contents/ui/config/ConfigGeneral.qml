import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_updateInterval: interval.value
    property alias cfg_barStyle: barStyle.currentIndex
    property alias cfg_colorOverride: colorOverride.colorString
    property alias cfg_showDisk: showDisk.checked
    property alias cfg_showUptime: showUptime.checked
    property alias cfg_showExternalIp: showExternalIp.checked
    property alias cfg_showSysInfo: showSysInfo.checked
    property alias cfg_tempFahrenheit: fahrenheit.checked
    property alias cfg_topProcesses: topProcs.value
    property int cfg_usageIntervalMinutes

    property int cfg_updateIntervalDefault
    property int cfg_barStyleDefault
    property string cfg_colorOverrideDefault
    property bool cfg_showDiskDefault
    property bool cfg_showUptimeDefault
    property bool cfg_showExternalIpDefault
    property bool cfg_showSysInfoDefault
    property bool cfg_tempFahrenheitDefault
    property int cfg_topProcessesDefault
    property int cfg_usageIntervalMinutesDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: interval
            Kirigami.FormData.label: i18n("Update every:")
            from: 500
            to: 10000
            stepSize: 500
            textFromValue: (v) => (v / 1000).toFixed(1) + " s"
            valueFromText: (t) => Math.round(parseFloat(t) * 1000)
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Panel") }
        QQC2.ComboBox {
            id: barStyle
            Kirigami.FormData.label: i18n("Chart style:")
            model: [i18n("Vertical bar"), i18n("History chart")]
        }
        PaletteBox {
            id: colorOverride
            allowNone: true
            colorString: ""
            Kirigami.FormData.label: i18n("Color for all charts:")
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Claude and Codex usage") }
        QQC2.ComboBox {
            readonly property var minutes: [1, 3, 5, 10]
            Kirigami.FormData.label: i18n("Refresh every:")
            model: minutes.map(function (m) { return i18n("%1 min", m) })
            currentIndex: Math.max(0, minutes.indexOf(cfg_usageIntervalMinutes))
            onActivated: (i) => cfg_usageIntervalMinutes = minutes[i]
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Popup") }
        QQC2.CheckBox { id: showDisk; Kirigami.FormData.label: i18n("Show:"); text: i18n("Disk card") }
        QQC2.CheckBox { id: showUptime; text: i18n("Uptime") }
        QQC2.CheckBox { id: showExternalIp; text: i18n("Public IP (looks it up on api.ipify.org)") }
        QQC2.CheckBox { id: showSysInfo; text: i18n("System info") }
        QQC2.SpinBox {
            id: topProcs
            Kirigami.FormData.label: i18n("Top processes:")
            from: 0
            to: 5
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Units") }
        QQC2.CheckBox { id: fahrenheit; Kirigami.FormData.label: i18n("Temperature:"); text: i18n("Use Fahrenheit") }
    }
}
