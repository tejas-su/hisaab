package com.widgetsandco.hisaab.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import java.time.LocalDate

/**
 * The home-screen widget (SPEC FR-WG). Each update reads the snapshot the app wrote, picks the row
 * for today's date and draws it; nothing here works out money (FR-WG-5, widget spec §6–7).
 *
 * Updates come from the app's publish, Android's periodic refresh, the midnight alarm and job, a
 * resize, and a date, time, time-zone, boot or app-update broadcast.
 */
class HisaabWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        draw(context, manager, intArrayOf(id))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action in REDRAW_ON) {
            updateAll(context)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onDisabled(context: Context) {
        Midnight.cancel(context)
    }

    companion object {
        /** Sent by the midnight alarm. */
        const val ACTION_MIDNIGHT = "com.widgetsandco.hisaab.widget.MIDNIGHT"

        private val REDRAW_ON = setOf(
            ACTION_MIDNIGHT,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )

        /** Redraws every placed widget from the stored snapshot. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            draw(context, manager, manager.getAppWidgetIds(ComponentName(context, HisaabWidgetProvider::class.java)))
        }

        private fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val content = SnapshotReader.contentFor(SnapshotStore.read(context), LocalDate.now())
            val views = WidgetViews(context)
            for (id in ids) {
                manager.updateAppWidget(id, views.build(content, WidgetSize.of(manager.getAppWidgetOptions(id))))
            }
            Midnight.schedule(context)
        }
    }
}
