package com.widgetsandco.hisaab.widget

import android.content.Context

/** Where the app keeps the widget's snapshot: one string in the app's own preferences (widget spec §4). */
object SnapshotStore {
    private const val FILE = "hisaab.widget"
    private const val KEY = "hisaab.widget.snapshot"

    /** The stored snapshot JSON, or null before the app has written one. */
    fun read(context: Context): String? = context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString(KEY, null)

    /** Stores [json], replacing the last one; done before the widgets redraw. */
    fun write(context: Context, json: String) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putString(KEY, json).commit()
    }
}
