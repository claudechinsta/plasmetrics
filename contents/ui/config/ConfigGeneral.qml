import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_updateInterval: interval.value
    property alias cfg_barStyle: barStyle.currentIndex
    property alias cfg_showDisk: showDisk.checked
    property alias cfg_showUptime: showUptime.checked
    property alias cfg_tempFahrenheit: fahrenheit.checked
    property alias cfg_topProcesses: topProcs.value

    property int cfg_updateIntervalDefault
    property int cfg_barStyleDefault
    property bool cfg_showDiskDefault
    property bool cfg_showUptimeDefault
    property bool cfg_tempFahrenheitDefault
    property int cfg_topProcessesDefault

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

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Popup") }
        QQC2.CheckBox { id: showDisk; Kirigami.FormData.label: i18n("Show:"); text: i18n("Disk card") }
        QQC2.CheckBox { id: showUptime; text: i18n("Uptime") }
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
