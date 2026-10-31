import QtQuick
import org.kde.kirigami as Kirigami

// Menu-bar style bar chart. `values` (0..1) draws upward from the bottom;
// with `values2` set, values grow up from the midline and values2 down from it.
Canvas {
    id: root
    property var values: []
    property var values2: null
    property color color: "#4da3ff"
    property color color2: "#ff453a"
    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var t = Kirigami.Theme.textColor
        ctx.strokeStyle = Qt.rgba(t.r, t.g, t.b, 0.45)
        ctx.lineWidth = 1
        ctx.strokeRect(0.5, 0.5, width - 1, height - 1)

        var barW = 2, gap = 1
        var n = Math.floor((width - 2) / (barW + gap))
        var split = values2 !== null
        var mid = split ? height / 2 : height - 1
        var span = split ? height / 2 - 2 : height - 3
        var off = Math.max(0, values.length - n)
        for (var i = 0; i < n && i + off < values.length; i++) {
            var x = width - 1 - (n - i) * (barW + gap) + gap
            var h = Math.max(0, Math.min(1, values[i + off])) * span
            ctx.fillStyle = color
            ctx.fillRect(x, mid - h, barW, h)
            if (split && values2.length > i + off) {
                var h2 = Math.max(0, Math.min(1, values2[i + off])) * span
                ctx.fillStyle = color2
                ctx.fillRect(x, mid, barW, h2)
            }
        }
    }
}
