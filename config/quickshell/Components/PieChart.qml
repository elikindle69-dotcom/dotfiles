import QtQuick

Item {
    property real value: 0
    property int chart_size: 100
    property color color
    property color background

    width: chart_size
    height: chart_size

    Behavior on value {
        NumberAnimation { duration: token_motion_duration_short; easing.type: Easing.Bezier; easing.bezierCurve: token_motion_curve_subtle }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")

            ctx.reset()

            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2

            // background
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fillStyle = background
            ctx.fill()

            // progress
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.arc(
                cx,
                cy,
                r,
                -Math.PI / 2,
                -Math.PI / 2 + Math.PI * 2 * value
            )
            ctx.closePath()
            ctx.fillStyle = color
            ctx.fill()
        }
    }

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onBackgroundChanged: canvas.requestPaint()

    function repaint() {
        canvas.requestPaint()
    }
}
