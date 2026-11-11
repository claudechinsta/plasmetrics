import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Picks one color from a fixed palette; with allowNone, "Not set" (empty string) comes first.
// With officialColor set, "Official" (stored as "official") comes first and shows that color
RowLayout {
    id: root
    property string colorString: "#4da3ff"
    property bool allowNone: false
    property string officialColor: ""
    // What a stored value looks like on screen
    function shown(v) { return v === "official" ? officialColor : v }
    readonly property var palette: (allowNone ? [{ name: i18n("Not set"), value: "" }] : (officialColor !== "" ? [{ name: i18n("Official"), value: "official" }] : [])).concat([
        { name: i18n("Blue"), value: "#4da3ff" },
        { name: i18n("Green"), value: "#4cd964" },
        { name: i18n("Orange"), value: "#ff9f0a" },
        { name: i18n("Red"), value: "#ff453a" },
        { name: i18n("Pink"), value: "#ff6482" },
        { name: i18n("Purple"), value: "#bf5af2" },
        { name: i18n("Teal"), value: "#40c8e0" },
        { name: i18n("Yellow"), value: "#ffd60a" },
        { name: i18n("Gray"), value: "#98989d" }
    ])
    spacing: Kirigami.Units.smallSpacing

    Rectangle {
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
        radius: 3
        color: root.colorString === "" ? "transparent" : root.shown(root.colorString)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
    }
    QQC2.ComboBox {
        model: root.palette
        textRole: "name"
        currentIndex: {
            for (var i = 0; i < root.palette.length; i++)
                if (root.palette[i].value === root.colorString.toLowerCase()) return i
            return -1
        }
        onActivated: (i) => root.colorString = root.palette[i].value
        delegate: QQC2.ItemDelegate {
            width: parent ? parent.width : implicitWidth
            text: modelData.name
            icon.name: ""
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { Layout.preferredWidth: 14; Layout.preferredHeight: 14; radius: 3; color: modelData.value === "" ? "transparent" : root.shown(modelData.value); border.width: modelData.value === "" ? 1 : 0; border.color: Kirigami.Theme.disabledTextColor }
                QQC2.Label { text: modelData.name; Layout.fillWidth: true }
            }
        }
    }
}
