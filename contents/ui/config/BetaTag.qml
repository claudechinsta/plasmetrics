import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Small outlined "BETA" badge
Rectangle {
    implicitWidth: tag.implicitWidth + Kirigami.Units.smallSpacing * 2
    implicitHeight: tag.implicitHeight + 2
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Kirigami.Theme.highlightColor
    QQC2.Label {
        id: tag
        anchors.centerIn: parent
        text: i18n("BETA")
        color: Kirigami.Theme.highlightColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
        font.bold: true
        font.letterSpacing: 0.6
    }
}
