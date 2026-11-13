package com.widgetsandco.hisaab.widget

import kotlin.math.ceil

/**
 * The 4×1's widths in dp (FR-WG-1): the label-and-amount column and the today's bar beside it.
 * The column is mockup 38's 112dp, wider when "Safe to spend today" needs it at the phone's
 * font and font scale, and never so wide that the bar drops under [MIN_BAR].
 */
object WideColumn {
    /** The design width of the column. */
    const val DESIGN = 112

    // why: the 4×1's padding (20 + 18), the gaps before the bar (14) and the key (10), and the 48dp key.
    private const val FIXED = 20 + 18 + 14 + 10 + 48
    private const val MIN_BAR = 48

    /** The column for a title [titleDp] wide on a widget [widgetWidthDp] wide. */
    fun width(titleDp: Float, widgetWidthDp: Int): Int {
        val most = (widgetWidthDp - FIXED - MIN_BAR).coerceAtLeast(DESIGN)
        return ceil(titleDp).toInt().coerceIn(DESIGN, most)
    }

    /** What the bar gets beside a column [columnDp] wide. */
    fun barWidth(columnDp: Int, widgetWidthDp: Int): Int = widgetWidthDp - FIXED - columnDp
}
