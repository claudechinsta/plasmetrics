import QtQuick
import org.kde.kirigami as Kirigami

// Two line series with their own scales (e.g. watts and volts); values below 0 mean "no data"
Canvas {
    id: root
    property var values: []
    property var values2: []
    property color color: "#ff9f0a"
    property color color2: "#64d2ff"
    property real min1: 0        // smallest span each series is allowed to zoom into
    property real min2: 1
    property int maxSamples: 60
    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function line(ctx, vals, col, span, fromZero) {
        var good = vals.filter(function (v) { return v >= 0 })
        if (good.length < 2) return
        var lo = fromZero ? 0 : Math.min.apply(null, good), hi = Math.max.apply(null, good)
        if (hi - lo < span) {
            var c = (hi + lo) / 2
            lo = fromZero ? 0 : c - span / 2
            hi = fromZero ? span : c + span / 2
        }
        var n = vals.length, step = width / (maxSamples - 1), x0 = width - (n - 1) * step
        ctx.beginPath()
        var started = false
        for (var i = 0; i < n; i++) {
            if (vals[i] < 0) { started = false; continue }
            var y = height - 2 - (vals[i] - lo) / (hi - lo) * (height - 4)
            if (!started) { ctx.moveTo(x0 + i * step, y); started = true } else ctx.lineTo(x0 + i * step, y)
        }
        ctx.strokeStyle = col
        ctx.lineWidth = 1.5
        ctx.stroke()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var t = Kirigami.Theme.textColor
        ctx.strokeStyle = Qt.rgba(t.r, t.g, t.b, 0.15)
        ctx.lineWidth = 1
        ctx.beginPath(); ctx.moveTo(0, height - 0.5); ctx.lineTo(width, height - 0.5); ctx.stroke()
        line(ctx, values, color, min1, true)
        line(ctx, values2, color2, min2, false)
    }
}
