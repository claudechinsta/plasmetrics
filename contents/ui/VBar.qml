import QtQuick
import org.kde.kirigami as Kirigami

// Vertical progress bar; `frac2` >= 0 adds a second bar beside the first
Item {
    id: root
    property real frac: 0
    property real frac2: -1
    property color color: "#4da3ff"
    property color color2: "#ff453a"
    readonly property int barW: 7

    implicitWidth: frac2 >= 0 ? barW * 2 + 3 : barW
    implicitHeight: 20

    component Bar: Rectangle {
        property real f
        property color c
        width: root.barW
        height: root.height
        radius: 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
            height: Math.max(0, Math.min(1, parent.f)) * (parent.height - 2)
            radius: 1
            color: parent.c
        }
    }
    Bar { f: root.frac; c: root.color }
    Bar { x: root.barW + 3; visible: root.frac2 >= 0; f: Math.max(0, root.frac2); c: root.color2 }
}
