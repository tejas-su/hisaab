package com.widgetsandco.hisaab.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path

/**
 * The days rail as a bitmap (BR-6): one dot per day left, today's first and bigger, in its state's
 * shape. A port of `DaysRailLayout` and `DaysRailPainter` in `lib/core/widgets/days_rail/`; change both together.
 */
object DaysRail {
    private const val TODAY = 10f
    private const val LATER = 6f
    private const val SMALLEST = 2f
    private const val MIN_GAP = 2f
    private const val EDGE = 1.5f
    private const val RING = 2f
    private const val OUTLINE = 1.2f
    private const val HATCH_SPACING = 3.5f

    /** The rail's height in dp: today's dot. */
    const val HEIGHT = TODAY

    /** Draws [spec] across [widthDp]. */
    fun draw(spec: DotsSpec, widthDp: Float, density: Float, palette: WidgetPalette, rtl: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap((widthDp * density).toInt().coerceAtLeast(1), (TODAY * density).toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.scale(density, density)
        if (rtl) canvas.scale(-1f, 1f, widthDp / 2, 0f)
        val count = spec.count.coerceAtLeast(1)
        val slot = if (count > 1) (widthDp - TODAY) / (count - 1) else 0f
        val later = (slot - MIN_GAP).coerceIn(SMALLEST, LATER)
        val y = TODAY / 2
        today(canvas, TODAY / 2, y, TODAY / 2, spec.style, palette)
        for (i in 1 until count) {
            later(canvas, TODAY + slot * (i - 1) + slot / 2, y, later / 2, spec.style, palette)
        }
        return bitmap
    }

    private fun today(canvas: Canvas, x: Float, y: Float, r: Float, style: String, palette: WidgetPalette) {
        when (style) {
            "onTrack" -> {
                canvas.drawCircle(x, y, r, fill(palette.signal))
                edge(canvas, x, y, r, palette)
            }
            "slowDown" -> {
                canvas.drawCircle(x, y, r, fill(palette.idle))
                canvas.drawCircle(x, y, r - RING / 2, stroke(palette.signal, RING))
                edge(canvas, x, y, r, palette)
            }
            else -> hatched(canvas, x, y, r, palette)
        }
    }

    private fun later(canvas: Canvas, x: Float, y: Float, r: Float, style: String, palette: WidgetPalette) {
        if (style == "overCycle") {
            canvas.drawCircle(x, y, r - OUTLINE / 2, stroke(palette.ink2, OUTLINE))
        } else {
            canvas.drawCircle(x, y, r, fill(palette.idle))
        }
    }

    private fun hatched(canvas: Canvas, x: Float, y: Float, r: Float, palette: WidgetPalette) {
        canvas.save()
        canvas.clipPath(Path().apply { addCircle(x, y, r, Path.Direction.CW) })
        canvas.drawCircle(x, y, r, fill(palette.display))
        val line = stroke(palette.ink2, OUTLINE)
        var lx = x - r - 2 * r
        while (lx < x + r) {
            canvas.drawLine(lx, y + r, lx + 2 * r, y - r, line)
            lx += HATCH_SPACING
        }
        canvas.restore()
        canvas.drawCircle(x, y, r - EDGE / 2, stroke(palette.ink2, EDGE))
    }

    private fun edge(canvas: Canvas, x: Float, y: Float, r: Float, palette: WidgetPalette) {
        if (Color.alpha(palette.edge) > 0) canvas.drawCircle(x, y, r - EDGE / 2, stroke(palette.edge, EDGE))
    }

    private fun fill(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }

    private fun stroke(color: Int, width: Float) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color
        style = Paint.Style.STROKE
        strokeWidth = width
    }
}
