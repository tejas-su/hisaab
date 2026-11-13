package com.widgetsandco.hisaab.widget

import android.appwidget.AppWidgetManager
import android.os.Bundle

/** Which of the four layouts a widget gets (FR-WG-1), from the size the launcher gave it. */
enum class WidgetLayout { SMALL, WIDE, SQUARE, LARGE }

/** A placed widget's size in dp, and the layout it gets. */
data class WidgetSize(val widthDp: Int, val heightDp: Int) {
    /** Two cells wide or more becomes 4×, two rows tall or more becomes ×2. */
    val layout: WidgetLayout
        get() = when {
            widthDp >= WIDE_FROM && heightDp >= TALL_FROM -> WidgetLayout.LARGE
            widthDp >= WIDE_FROM -> WidgetLayout.WIDE
            heightDp >= TALL_FROM -> WidgetLayout.SQUARE
            else -> WidgetLayout.SMALL
        }

    /** Whether there is room for a key under the words. */
    val tall: Boolean get() = heightDp >= TALL_FROM

    companion object {
        private const val WIDE_FROM = 250
        private const val TALL_FROM = 130

        // why: the placed 4×2 on a 360dp phone (mockup 38), for a launcher that hasn't reported a size yet.
        private val PLACED = WidgetSize(320, 184)

        /** The portrait size Android reports in [options]: the narrowest width and the tallest height. */
        fun of(options: Bundle?): WidgetSize {
            val width = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
            val height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0
            return if (width <= 0 || height <= 0) PLACED else WidgetSize(width, height)
        }
    }
}
