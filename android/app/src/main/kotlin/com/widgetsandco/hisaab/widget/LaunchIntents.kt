package com.widgetsandco.hisaab.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.widgetsandco.hisaab.MainActivity

/**
 * The taps that open hisaab from outside it (widget spec §8): explicit intents to [MainActivity]
 * carrying a `hisaab://` URI, which the app routes in Dart (`LaunchAction.parse`).
 */
object LaunchIntents {
    const val ADD = "hisaab://add"
    const val HOME = "hisaab://home"
    const val SET_UP = "hisaab://setup"

    /** An intent that opens [uri] in hisaab. */
    fun intent(context: Context, uri: String): Intent = Intent(context, MainActivity::class.java)
        .setAction(Intent.ACTION_VIEW)
        .setData(Uri.parse(uri))
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    /** The same, ready for a widget or tile; each URI gets its own request code so they never merge. */
    fun pending(context: Context, uri: String): PendingIntent = PendingIntent.getActivity(
        context,
        uri.hashCode(),
        intent(context, uri),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
