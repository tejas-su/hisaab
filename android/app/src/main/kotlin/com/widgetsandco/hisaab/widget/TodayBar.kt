package com.widgetsandco.hisaab.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import kotlin.math.max
import kotlin.math.min

/**
 * Today's bar as a bitmap (BR-6), without names: the yellow from the start edge, the bites from the
 * end edge, and when overspent the share tick with a hatch past it.
 *
 * A port of `TodayBarLayout` and `TodayBarPainter` in `lib/core/widgets/today_bar/`; change both together.
 */
object TodayBar {
    private const val GAP = 3f
    private const val MIN_BITE = 4f
    private const val RADIUS = 8f
    private const val EDGE = 1.5f
    private const val RING = 3f
    private const val TICK = 2f
    private const val TICK_OVERHANG = 4f
    private const val HATCH_SPACING = 5f

    /** Space the tick needs above and below the bar, in dp. */
    const val OVERHANG = TICK_OVERHANG

    /** Draws [spec] [widthDp] wide and [heightDp] tall (plus the tick's overhang above and below). */
    fun draw(spec: BarSpec, widthDp: Float, heightDp: Float, density: Float, palette: WidgetPalette, rtl: Boolean): Bitmap {
        val total = heightDp + 2 * TICK_OVERHANG
        val bitmap = Bitmap.createBitmap((widthDp * density).toInt().coerceAtLeast(1), (total * density).toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.scale(density, density)
        if (rtl) canvas.scale(-1f, 1f, widthDp / 2, 0f)
        canvas.translate(0f, TICK_OVERHANG)
        Painter(canvas, widthDp, heightDp, palette, spec.style).paint(spec)
        return bitmap
    }

    private class Painter(val canvas: Canvas, val width: Float, val height: Float, val palette: WidgetPalette, val style: String) {
        fun paint(spec: BarSpec) {
            val bites = bitePieces(spec.bites)
            val yellow = if (bites.isEmpty()) spec.left.toFloat() * width else min(spec.left.toFloat() * width, bites.last().first - GAP)
            if (bites.isEmpty() && yellow <= 0f) piece(0f, width, palette.idle)
            yellow(yellow)
            bites.forEach { (left, w) -> piece(max(left, yellow + GAP), left + w, palette.idle) }
            spec.tick?.let { tick ->
                val x = tick.toFloat() * width
                hatch(x, width)
                tick(x)
            }
        }

        // why: as TodayBarLayout: the first bite at the end edge, each later one nearer the yellow;
        // one narrower than MIN_BITE joins the next, so any spend shows and nothing is a sliver.
        private fun bitePieces(shares: List<Double>): List<Pair<Float, Float>> {
            val pieces = mutableListOf<Pair<Float, Float>>()
            var end = width
            var pending = 0f
            for (share in shares) {
                pending += share.toFloat() * width
                if (pending - GAP >= MIN_BITE) {
                    pieces += (end - pending + GAP) to (pending - GAP)
                    end -= pending
                    pending = 0f
                }
            }
            if (pending <= 0f) return pieces
            if (pieces.isEmpty()) {
                val w = max(pending - GAP, MIN_BITE)
                return listOf((end - w) to w)
            }
            val last = pieces.removeAt(pieces.lastIndex)
            return pieces + ((end - pending + GAP) to (last.second + pending))
        }

        private fun shape(left: Float, right: Float) = RectF(left, 0f, right, height)

        private fun radius(left: Float, right: Float) = min(RADIUS, (right - left) / 2)

        private fun yellow(right: Float) {
            if (right <= 0f) return
            val rect = shape(0f, right)
            val r = radius(0f, right)
            if (style == "slowDown") {
                canvas.drawRoundRect(rect, r, r, fill(palette.idle))
                canvas.drawRoundRect(inset(rect, RING / 2), r, r, stroke(palette.signal, RING))
            } else {
                canvas.drawRoundRect(rect, r, r, fill(palette.signal))
            }
            if (Color.alpha(palette.edge) > 0) canvas.drawRoundRect(inset(rect, EDGE / 2), r, r, stroke(palette.edge, EDGE))
        }

        private fun piece(left: Float, right: Float, color: Int) {
            if (right - left <= 0f) return
            val r = radius(left, right)
            canvas.drawRoundRect(shape(left, right), r, r, fill(color))
        }

        private fun hatch(left: Float, right: Float) {
            if (right - left <= 0f) return
            val rect = shape(left, right)
            val r = radius(left, right)
            canvas.save()
            canvas.clipRect(rect)
            canvas.drawRoundRect(rect, r, r, fill(palette.display))
            val line = stroke(palette.ink2, EDGE)
            var x = left - height
            while (x < right) {
                canvas.drawLine(x, height, x + height, 0f, line)
                x += HATCH_SPACING
            }
            canvas.restore()
            canvas.drawRoundRect(inset(rect, EDGE / 2), r, r, stroke(palette.ink2, EDGE))
        }

        private fun tick(x: Float) {
            val rect = RectF(x - TICK / 2, -TICK_OVERHANG, x + TICK / 2, height + TICK_OVERHANG)
            canvas.drawRect(RectF(rect.left - 1, rect.top - 1, rect.right + 1, rect.bottom + 1), fill(palette.display))
            canvas.drawRect(rect, fill(palette.ink))
        }

        private fun inset(rect: RectF, by: Float) = RectF(rect.left + by, rect.top + by, rect.right - by, rect.bottom - by)

        private fun fill(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }

        private fun stroke(color: Int, width: Float) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            strokeWidth = width
        }
    }
}
