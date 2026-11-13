package com.widgetsandco.hisaab.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.time.Duration
import java.time.LocalDateTime
import java.util.concurrent.TimeUnit

/**
 * Wakes the widget just after midnight so it shows the new day's row (FR-WG-5, widget spec §7,
 * §15 #3). Two ways, both inexact so no exact-alarm permission is needed: an alarm, and a
 * WorkManager job for phones whose maker delays alarms. A late wake only delays the swap; every
 * redraw picks the row by date, and Android's 30-minute refresh is the floor.
 */
object Midnight {
    private const val WORK = "hisaab.widget.midnight"
    private const val AFTER_MIDNIGHT_SECONDS = 60L

    /** Sets both for the coming midnight, replacing any set before. */
    fun schedule(context: Context) {
        val wait = untilJustAfterMidnight()
        val alarms = context.getSystemService(AlarmManager::class.java)
        alarms?.set(AlarmManager.RTC, System.currentTimeMillis() + wait.toMillis(), alarm(context))
        WorkManager.getInstance(context).enqueueUniqueWork(
            WORK,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<MidnightWorker>().setInitialDelay(wait.toMillis(), TimeUnit.MILLISECONDS).build(),
        )
    }

    /** Stops both once the last widget is removed. */
    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(alarm(context))
        WorkManager.getInstance(context).cancelUniqueWork(WORK)
    }

    private fun untilJustAfterMidnight(): Duration {
        val now = LocalDateTime.now()
        val next = now.toLocalDate().plusDays(1).atStartOfDay().plusSeconds(AFTER_MIDNIGHT_SECONDS)
        return Duration.between(now, next)
    }

    private fun alarm(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, HisaabWidgetProvider::class.java).setAction(HisaabWidgetProvider.ACTION_MIDNIGHT),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}

/** The midnight job: redraws the widgets, which also sets the next midnight. */
class MidnightWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        HisaabWidgetProvider.updateAll(applicationContext)
        return Result.success()
    }
}
