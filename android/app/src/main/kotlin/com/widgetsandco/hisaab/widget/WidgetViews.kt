package com.widgetsandco.hisaab.widget

import android.content.Context
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.widgetsandco.hisaab.R

/**
 * Builds one widget's views for what it shows and its size (FR-WG-1 to FR-WG-4, mockup 38). Every
 * word and amount comes from the snapshot; this only places them, colours them and sets the taps.
 */
class WidgetViews(private val context: Context) {
    private val density = context.resources.displayMetrics.density
    private val rtl = context.resources.configuration.layoutDirection == View.LAYOUT_DIRECTION_RTL
    private val text = WidgetText(context)

    /** The views for [content] at [size]. */
    fun build(content: WidgetContent, size: WidgetSize): RemoteViews {
        val palette = WidgetPalette.forLook(context, content.look)
        return when (content) {
            is WidgetContent.Stale -> message(size, palette, context.getString(R.string.widget_stale), null)
            is WidgetContent.Day -> if (content.row.isSetUp) {
                message(size, palette, content.strings.setUpBody, content.strings.setUp)
            } else {
                day(content, size, palette)
            }
        }
    }

    private fun day(content: WidgetContent.Day, size: WidgetSize, palette: WidgetPalette): RemoteViews {
        val row = content.row
        val views = RemoteViews(context.packageName, layoutOf(size.layout))
        paper(views, size, palette)
        views.setContentDescription(R.id.widget_root, row.spoken)
        views.setOnClickPendingIntent(R.id.widget_root, LaunchIntents.pending(context, LaunchIntents.HOME))
        views.setOnClickPendingIntent(R.id.widget_add, LaunchIntents.pending(context, LaunchIntents.ADD))
        views.setContentDescription(R.id.widget_add, content.strings.addSpoken)
        addKey(views, size.layout, palette)
        val amountColor = if (row.heroMuted) palette.ink2 else palette.ink
        val column = if (size.layout == WidgetLayout.WIDE) wideColumn(views, content, size, palette) else 0
        views.setImageViewBitmap(R.id.widget_amount, text.amount(row.hero, amountSize(size.layout), AMOUNT_WEIGHT, amountColor, px(amountRoom(size, column))))
        when (size.layout) {
            WidgetLayout.SMALL -> words(views, R.id.widget_glance, row.glance, palette.ink2)
            WidgetLayout.WIDE -> {
                over(views, content, palette)
                bar(views, row, WideColumn.barWidth(column, size.widthDp), WIDE_BAR, palette)
            }
            WidgetLayout.SQUARE -> {
                titleAndOver(views, content, palette)
                bar(views, row, size.widthDp - 2 * PADDING, SQUARE_BAR, palette)
                words(views, R.id.widget_days_left, row.daysLeft, palette.ink2)
                flag(views, row, palette)
                views.setTextViewText(R.id.widget_add_label, content.strings.add)
            }
            WidgetLayout.LARGE -> {
                titleAndOver(views, content, palette)
                bar(views, row, size.widthDp - 2 * PADDING, LARGE_BAR, palette)
                views.setImageViewBitmap(R.id.widget_dots, DaysRail.draw(row.dots, (size.widthDp - 2 * PADDING - FLAG_ROOM).toFloat(), density, palette, rtl))
                flag(views, row, palette)
                views.setInt(R.id.widget_divider, "setBackgroundColor", palette.etch)
                words(views, R.id.widget_range, row.range, palette.ink)
                words(views, R.id.widget_days, row.days, palette.ink2)
            }
        }
        return views
    }

    private fun message(size: WidgetSize, palette: WidgetPalette, body: String, key: String?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_message)
        paper(views, size, palette)
        views.setImageViewBitmap(R.id.widget_wordmark, text.wordmark(context.getString(R.string.widget_name), WORDMARK_SIZE, palette))
        words(views, R.id.widget_message, body, palette.ink2)
        views.setContentDescription(R.id.widget_root, body)
        val uri = if (key == null) LaunchIntents.HOME else LaunchIntents.SET_UP
        views.setOnClickPendingIntent(R.id.widget_root, LaunchIntents.pending(context, uri))
        if (key != null && size.tall) {
            views.setViewVisibility(R.id.widget_set_up, View.VISIBLE)
            views.setTextViewText(R.id.widget_set_up, key)
            views.setTextColor(R.id.widget_set_up, palette.display)
            views.setInt(R.id.widget_set_up, "setBackgroundResource", if (palette.dark) R.drawable.widget_set_up_key_dark else R.drawable.widget_set_up_key_light)
            views.setOnClickPendingIntent(R.id.widget_set_up, LaunchIntents.pending(context, LaunchIntents.SET_UP))
        }
        if (!size.tall) views.setTextViewTextSize(R.id.widget_message, TypedValue.COMPLEX_UNIT_SP, SHORT_MESSAGE_SIZE)
        if (!size.tall) views.setInt(R.id.widget_message, "setMaxLines", 2)
        return views
    }

    private fun paper(views: RemoteViews, size: WidgetSize, palette: WidgetPalette) {
        views.setImageViewBitmap(
            R.id.widget_paper,
            EtchPaper.draw(px(size.widthDp), px(size.heightDp), density, palette, rtl, cornerDp()),
        )
    }

    private fun titleAndOver(views: RemoteViews, content: WidgetContent.Day, palette: WidgetPalette) {
        words(views, R.id.widget_title, content.strings.title, palette.ink2)
        over(views, content, palette)
    }

    private fun over(views: RemoteViews, content: WidgetContent.Day, palette: WidgetPalette) {
        val over = content.row.over
        views.setViewVisibility(R.id.widget_over, if (over == null) View.GONE else View.VISIBLE)
        if (over != null) words(views, R.id.widget_over, over, palette.ink2)
    }

    private fun bar(views: RemoteViews, row: WidgetRow, widthDp: Int, heightDp: Float, palette: WidgetPalette) {
        views.setImageViewBitmap(R.id.widget_bar, TodayBar.draw(row.bar, widthDp.toFloat().coerceAtLeast(MIN_BAR), heightDp, density, palette, rtl))
    }

    private fun flag(views: RemoteViews, row: WidgetRow, palette: WidgetPalette) {
        words(views, R.id.widget_flag, row.flag, palette.ink)
        views.setInt(R.id.widget_flag_icon, "setColorFilter", palette.ink)
    }

    private fun addKey(views: RemoteViews, layout: WidgetLayout, palette: WidgetPalette) {
        val (id, light, dark) = when (layout) {
            WidgetLayout.SMALL -> Triple(R.id.widget_add_face, R.drawable.widget_add_key_small_light, R.drawable.widget_add_key_small_dark)
            WidgetLayout.SQUARE -> Triple(R.id.widget_add, R.drawable.widget_add_key_wide_light, R.drawable.widget_add_key_wide_dark)
            WidgetLayout.WIDE, WidgetLayout.LARGE -> Triple(R.id.widget_add, R.drawable.widget_add_key_light, R.drawable.widget_add_key_dark)
        }
        views.setInt(id, "setBackgroundResource", if (palette.dark) dark else light)
    }

    private fun words(views: RemoteViews, id: Int, value: String, color: Int) {
        views.setTextViewText(id, value)
        views.setTextColor(id, color)
    }

    // why: in a fixed 112dp column the 4×1's title was cut to "Safe to spend to…" (D158). The
    // title is drawn in Mukta so its width is known, the column grows to fit it, and the over line
    // is pinned to the column so the bar bitmap, drawn for what the column leaves, fills its slot.
    private fun wideColumn(views: RemoteViews, content: WidgetContent.Day, size: WidgetSize, palette: WidgetPalette): Int {
        val title = content.strings.title
        val column = WideColumn.width(text.wordsWidthDp(title, WIDE_TITLE_SIZE), size.widthDp)
        views.setImageViewBitmap(R.id.widget_title, text.words(title, WIDE_TITLE_SIZE, palette.ink2, px(column)))
        views.setInt(R.id.widget_over, "setMinWidth", px(column))
        views.setInt(R.id.widget_over, "setMaxWidth", px(column))
        return column
    }

    // why: the amount gets the width left beside the Add key, or under it on the 2×2.
    private fun amountRoom(size: WidgetSize, wideColumn: Int): Int = when (size.layout) {
        WidgetLayout.SMALL -> size.widthDp - SMALL_FIXED
        WidgetLayout.WIDE -> wideColumn
        WidgetLayout.SQUARE -> size.widthDp - 2 * PADDING
        WidgetLayout.LARGE -> (size.widthDp - 2 * PADDING - KEY - KEY_GAP) * 2 / 3
    }

    private fun amountSize(layout: WidgetLayout): Float = when (layout) {
        WidgetLayout.SMALL -> 24f
        WidgetLayout.WIDE -> 28f
        WidgetLayout.SQUARE -> 30f
        WidgetLayout.LARGE -> 36f
    }

    private fun layoutOf(layout: WidgetLayout): Int = when (layout) {
        WidgetLayout.SMALL -> R.layout.widget_small
        WidgetLayout.WIDE -> R.layout.widget_wide
        WidgetLayout.SQUARE -> R.layout.widget_square
        WidgetLayout.LARGE -> R.layout.widget_large
    }

    // why: Android 12+ rounds every widget to the launcher's radius; the paper's corners and
    // keylines follow it so the frame stays concentric (widget spec §6).
    private fun cornerDp(): Float = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        context.resources.getDimension(android.R.dimen.system_app_widget_background_radius) / density
    } else {
        CORNER
    }

    private fun px(dp: Int): Int = (dp * density).toInt().coerceAtLeast(1)

    private companion object {
        const val AMOUNT_WEIGHT = 600
        const val WORDMARK_SIZE = 17f
        const val SHORT_MESSAGE_SIZE = 12f
        const val CORNER = 28f
        const val PADDING = 20
        const val KEY = 48
        const val KEY_GAP = 10
        const val FLAG_ROOM = 64
        const val MIN_BAR = 24f
        const val LARGE_BAR = 20f
        const val WIDE_BAR = 20f
        const val SQUARE_BAR = 14f
        // why: mockup 38's 4×1 title size.
        const val WIDE_TITLE_SIZE = 12f
        // why: the 2×1's padding (20 + 12) and its 48dp key target.
        const val SMALL_FIXED = 20 + 12 + 48
    }
}
