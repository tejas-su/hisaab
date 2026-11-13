package com.widgetsandco.hisaab.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import androidx.annotation.ColorInt
import com.widgetsandco.hisaab.R
import kotlin.math.ceil

/**
 * Amounts and the wordmark drawn as bitmaps in the app's own Anek Latin, read from the Flutter
 * assets already in the APK, so they keep `wdth` 85 and tabular figures on every Android version
 * (UI_DESIGN §10 build note). RemoteViews text can't set a variable font's axes before Android 8.
 */
class WidgetText(private val context: Context) {
    private val typefaces = mutableMapOf<Int, Typeface>()

    /** [text] at [sizeSp] in Anek Latin at [weight], no wider than [maxWidthPx]; it shrinks to fit. */
    fun amount(text: String, sizeSp: Float, weight: Int, @ColorInt color: Int, maxWidthPx: Int): Bitmap {
        val paint = paint(sizeSp, weight, color)
        val width = paint.measureText(text)
        if (width > maxWidthPx && width > 0f) paint.textSize *= maxWidthPx / width
        return render(text, paint, dot = null)
    }

    /** The "hisaab•" wordmark (D16): the name with a marigold dot, ringed in [edge] when it isn't clear. */
    fun wordmark(name: String, sizeSp: Float, palette: WidgetPalette): Bitmap =
        render(name, paint(sizeSp, WORDMARK_WEIGHT, palette.ink), dot = palette)

    /** How wide [text] is in dp in Mukta at [sizeSp] and the phone's font scale. */
    fun wordsWidthDp(text: String, sizeSp: Float): Float =
        wordsPaint(sizeSp, Color.BLACK).measureText(text) / context.resources.displayMetrics.density

    /**
     * [text] at [sizeSp] in Mukta Regular, no wider than [maxWidthPx]; it shrinks to fit. For words
     * a launcher would otherwise draw in its own font.
     */
    fun words(text: String, sizeSp: Float, @ColorInt color: Int, maxWidthPx: Int): Bitmap {
        val paint = wordsPaint(sizeSp, color)
        val width = paint.measureText(text)
        if (width > maxWidthPx && width > 0f) paint.textSize *= maxWidthPx / width
        return render(text, paint, dot = null)
    }

    private fun wordsPaint(sizeSp: Float, @ColorInt color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        val resources = context.resources
        typeface = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) resources.getFont(R.font.mukta_regular) else Typeface.DEFAULT
        textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sizeSp, resources.displayMetrics)
        this.color = color
    }

    private fun render(text: String, paint: Paint, dot: WidgetPalette?): Bitmap {
        val metrics = paint.fontMetrics
        val dotSize = paint.textSize * DOT_SHARE
        val textWidth = paint.measureText(text)
        val width = ceil(textWidth + if (dot != null) dotSize * 1.3f else 0f).toInt().coerceAtLeast(1)
        val height = ceil(metrics.descent - metrics.ascent).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawText(text, 0f, -metrics.ascent, paint)
        if (dot != null) drawDot(canvas, textWidth + dotSize * 0.65f, -metrics.ascent - dotSize / 2, dotSize / 2, dot)
        return bitmap
    }

    private fun drawDot(canvas: Canvas, x: Float, y: Float, r: Float, palette: WidgetPalette) {
        canvas.drawCircle(x, y, r, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = palette.signal })
        if (Color.alpha(palette.edge) > 0) {
            canvas.drawCircle(x, y, r - 0.75f, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.edge
                style = Paint.Style.STROKE
                strokeWidth = 1.5f
            })
        }
    }

    private fun paint(sizeSp: Float, weight: Int, @ColorInt color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = typeface(weight)
        textSize = sizeSp * context.resources.displayMetrics.density * context.resources.configuration.fontScale
        this.color = color
        fontFeatureSettings = "'tnum'"
    }

    private fun typeface(weight: Int): Typeface = typefaces.getOrPut(weight) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Typeface.Builder(context.assets, ANEK).setFontVariationSettings("'wght' $weight, 'wdth' 85").build()
        } else {
            Typeface.createFromAsset(context.assets, ANEK)
        }
    }

    private companion object {
        const val ANEK = "flutter_assets/assets/fonts/AnekLatin-Variable.ttf"
        const val WORDMARK_WEIGHT = 700
        const val DOT_SHARE = 0.32f
    }
}
