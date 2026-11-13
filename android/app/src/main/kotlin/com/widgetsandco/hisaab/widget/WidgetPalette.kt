package com.widgetsandco.hisaab.widget

import android.content.Context
import android.content.res.Configuration
import androidx.annotation.ColorInt
import com.widgetsandco.hisaab.R

/**
 * The hero's display tokens for one look, read from `widget_colors.xml`, which a Dart test keeps
 * equal to `HisaabColors` (FR-WG-2). Never the wallpaper's dynamic colours.
 */
data class WidgetPalette(
    @ColorInt val display: Int,
    @ColorInt val ink: Int,
    @ColorInt val ink2: Int,
    @ColorInt val idle: Int,
    @ColorInt val etch: Int,
    @ColorInt val hairline: Int,
    @ColorInt val signal: Int,
    @ColorInt val edge: Int,
    val dark: Boolean,
) {
    companion object {
        /** The palette for the app's [look] (`system`, `light` or `dark`); `system` follows the phone. */
        fun forLook(context: Context, look: String): WidgetPalette {
            val dark = when (look) {
                "dark" -> true
                "light" -> false
                else -> context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            }
            return if (dark) darkOf(context) else lightOf(context)
        }

        private fun lightOf(context: Context) = WidgetPalette(
            display = context.getColor(R.color.widget_light_display),
            ink = context.getColor(R.color.widget_light_display_ink),
            ink2 = context.getColor(R.color.widget_light_display_ink2),
            idle = context.getColor(R.color.widget_light_block_idle),
            etch = context.getColor(R.color.widget_light_display_etch),
            hairline = context.getColor(R.color.widget_light_hairline),
            signal = context.getColor(R.color.widget_light_signal),
            edge = context.getColor(R.color.widget_light_display_edge),
            dark = false,
        )

        private fun darkOf(context: Context) = WidgetPalette(
            display = context.getColor(R.color.widget_dark_display),
            ink = context.getColor(R.color.widget_dark_display_ink),
            ink2 = context.getColor(R.color.widget_dark_display_ink2),
            idle = context.getColor(R.color.widget_dark_block_idle),
            etch = context.getColor(R.color.widget_dark_display_etch),
            hairline = context.getColor(R.color.widget_dark_hairline),
            signal = context.getColor(R.color.widget_dark_signal),
            edge = context.getColor(R.color.widget_dark_display_edge),
            dark = true,
        )
    }
}
