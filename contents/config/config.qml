import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Metrics")
        icon: "utilities-system-monitor"
        source: "config/ConfigMetrics.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-font"
        source: "config/ConfigAppearance.qml"
    }
}
