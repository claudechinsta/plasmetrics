import QtQuick

// Filled sparkline; `values` is an array of 0..1 numbers
Canvas {
    id: root
    property var values: []
    property color color: "#4da3ff"
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var n = values.length
        if (n < 2) return
        var step = width / (root.maxSamples - 1)
        var x0 = width - (n - 1) * step
        ctx.beginPath()
        ctx.moveTo(x0, height)
        for (var i = 0; i < n; i++)
            ctx.lineTo(x0 + i * step, height - Math.min(1, values[i]) * (height - 2))
        ctx.lineTo(width, height)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.28)
        ctx.fill()
        ctx.beginPath()
        for (var j = 0; j < n; j++) {
            var y = height - Math.min(1, values[j]) * (height - 2)
            if (j === 0) ctx.moveTo(x0, y); else ctx.lineTo(x0 + j * step, y)
        }
        ctx.strokeStyle = color
        ctx.lineWidth = 1.5
        ctx.stroke()
    }
    property int maxSamples: 60
}
