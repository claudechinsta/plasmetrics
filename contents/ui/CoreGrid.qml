import QtQuick
import org.kde.kirigami as Kirigami

// One small square per CPU core, filled column by column (`rows` per column).
// green < 20%, orange < 70%, red above
Item {
    id: root
    property var values: []
    property int rows: 4
    readonly property int gap: 1
    readonly property int cell: Math.max(2, Math.floor((height - gap * (rows - 1)) / rows))
    readonly property int cols: Math.max(1, Math.ceil(values.length / rows))

    readonly property int gridH: rows * cell + (rows - 1) * gap

    implicitWidth: cols * cell + (cols - 1) * gap
    implicitHeight: 20

    function shade(f) {
        return f < 0.2 ? "#30d158" : f < 0.7 ? "#ff9f0a" : "#ff453a"
    }

    Repeater {
        model: root.values.length
        Rectangle {
            x: Math.floor(index / root.rows) * (root.cell + root.gap)
            y: Math.round((root.height - root.gridH) / 2) + (index % root.rows) * (root.cell + root.gap)
            width: root.cell
            height: root.cell
            radius: 1
            color: root.shade(root.values[index])
        }
    }
}
