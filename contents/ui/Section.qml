import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Card with a title, big value, subtitle and optional sparkline
Rectangle {
    id: card
    property string title
    property string value
    property string subtitle
    property color accent: "#4da3ff"
    property var history: null
    property real fraction: -1
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property real baseSize: 10
    default property alias extra: extraCol.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Kirigami.Units.smallSpacing * 3
    radius: Kirigami.Units.cornerRadius
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Kirigami.Units.smallSpacing * 1.5 }
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: card.accent }
            Text {
                text: card.title
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.family: card.fontFamily
                font.pointSize: card.baseSize
                Layout.fillWidth: true
            }
            Text {
                text: card.value
                color: Kirigami.Theme.textColor
                font.family: card.fontFamily
                font.pointSize: card.baseSize * 1.5
                font.weight: Font.DemiBold
            }
        }
        Spark {
            visible: card.history !== null
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 26 : 0
            values: card.history ? card.history : []
            color: card.accent
        }
        Rectangle {
            visible: card.fraction >= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 6; radius: 3
            color: Qt.rgba(1, 1, 1, 0.1)
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, card.fraction))
                height: parent.height; radius: 3; color: card.accent
            }
        }
        Text {
            text: card.subtitle
            visible: text !== ""
            color: Kirigami.Theme.textColor
            opacity: 0.65
            elide: Text.ElideRight
            font.family: card.fontFamily
            font.pointSize: card.baseSize * 0.85
            Layout.fillWidth: true
        }
        ColumnLayout { id: extraCol; Layout.fillWidth: true; spacing: 2 }
    }
}
