package com.widgetsandco.hisaab.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * The hero's paper as a bitmap (FR-WG-2, D106, D107): the guilloché rosette near the top end corner,
 * the grain, and the solid and dashed keylines, on `display` with the widget's corners.
 *
 * A port of `DisplayEtchPainter` in `lib/core/widgets/display_etch.dart`; change both together.
 * The grain's dots fall in other places than Dart's, because Kotlin's and Dart's random numbers
 * differ for the same seed; the grain is texture, so only its density has to match.
 */
object EtchPaper {
    private const val ROSETTE_INSET = 80f
    private const val ROSETTE_TOP = 60f
    private const val STROKE = 0.6f
    private const val GRAIN_AREA = 60f
    private const val GRAIN_SEED = 7
    private const val FRAME_INSET = 6f
    private const val DASHED_INSET = 10f
    private const val DASH = 4f
    private const val DASH_GAP = 3f
    private const val RINGS = 14
    private const val STEPS = 720

    /** Draws the paper at [width] × [height] px; [density] is px per dp, [cornerDp] the widget's corner radius. */
    fun draw(width: Int, height: Int, density: Float, palette: WidgetPalette, rtl: Boolean, cornerDp: Float): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val w = width / density
        val h = height / density
        canvas.scale(density, density)
        val card = Path().apply { addRoundRect(RectF(0f, 0f, w, h), cornerDp, cornerDp, Path.Direction.CW) }
        canvas.drawPath(card, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = palette.display })
        canvas.save()
        canvas.clipPath(card)
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.etch
            style = Paint.Style.STROKE
            strokeWidth = STROKE
        }
        canvas.save()
        canvas.translate(if (rtl) ROSETTE_INSET else w - ROSETTE_INSET, ROSETTE_TOP)
        canvas.drawPath(rosette, line)
        canvas.restore()
        drawGrain(canvas, w, h, line)
        canvas.restore()
        drawFrame(canvas, w, h, FRAME_INSET, cornerDp, line.apply { strokeWidth = 1f })
        drawFrame(
            canvas, w, h, DASHED_INSET, cornerDp,
            Paint(line).apply {
                color = palette.hairline
                pathEffect = DashPathEffect(floatArrayOf(DASH, DASH_GAP), 0f)
            },
        )
        return bitmap
    }

    private val rosette: Path by lazy {
        Path().apply {
            for (ring in 0 until RINGS) {
                val base = 40 + ring * 7.5
                for (i in 0 until STEPS) {
                    val t = i.toDouble() / STEPS * 2 * PI
                    val radius = base + 6 * sin(18 * t + ring * 0.35) + 3 * sin(5 * t)
                    val x = (radius * cos(t)).toFloat()
                    val y = (radius * sin(t)).toFloat()
                    if (i == 0) moveTo(x, y) else lineTo(x, y)
                }
                close()
            }
        }
    }

    private fun drawGrain(canvas: Canvas, w: Float, h: Float, line: Paint) {
        val random = Random(GRAIN_SEED)
        val count = (w * h / GRAIN_AREA).toInt()
        val points = FloatArray(count * 2) { i -> random.nextFloat() * if (i % 2 == 0) w else h }
        canvas.drawPoints(points, Paint(line).apply { strokeWidth = 1f })
    }

    // why: each keyline's radius shrinks by its inset, so the lines stay concentric with the corner.
    private fun drawFrame(canvas: Canvas, w: Float, h: Float, inset: Float, cornerDp: Float, paint: Paint) {
        val radius = (cornerDp - inset).coerceAtLeast(0f)
        canvas.drawRoundRect(RectF(inset, inset, w - inset, h - inset), radius, radius, paint)
    }
}
