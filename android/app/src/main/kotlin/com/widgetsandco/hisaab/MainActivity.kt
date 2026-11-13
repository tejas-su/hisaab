package com.widgetsandco.hisaab

import android.app.ActivityManager
import android.app.StatusBarManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.service.quicksettings.TileService
import com.widgetsandco.hisaab.tile.AddSpendTileService
import com.widgetsandco.hisaab.widget.HisaabWidgetProvider
import com.widgetsandco.hisaab.widget.LaunchIntents
import com.widgetsandco.hisaab.widget.SnapshotStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** The `hisaab://` URI whose tap started the app, until Dart reads it (widget spec §8). */
    private var launchUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // why: a restored or recents-relaunched activity carries the old tap; only a fresh tap opens anything.
        val fresh = savedInstanceState == null && intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == 0
        if (fresh) launchUri = uriOf(intent)
        // why: the recent-apps preview would show today's money to anyone who opens the app
        // switcher. This hides only that preview; screenshots keep working, unlike FLAG_SECURE,
        // which blocks them too. API 33+ only: below it, no reliable preview-only option exists
        // (case study 15 §3, NFR-10).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
            // why: with the capture off, Android paints the recents card from the task's colours,
            // which default to a white card under a black status bar. Home's `bg` keeps the card
            // one colour with the app (D134).
            val bg = getColor(R.color.splash_bg)
            setTaskDescription(
                ActivityManager.TaskDescription.Builder()
                    .setBackgroundColor(bg)
                    .setStatusBarColor(bg)
                    .setNavigationBarColor(bg)
                    .build(),
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result -> handle(call, result) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        uriOf(intent)?.let { channel?.invokeMethod("launch", it) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "publish" -> {
                SnapshotStore.write(this, call.arguments as String)
                HisaabWidgetProvider.updateAll(this)
                result.success(null)
            }
            "launchAction" -> {
                result.success(launchUri)
                launchUri = null
            }
            "canPinWidget" -> result.success(canPinWidget())
            "pinWidget" -> {
                if (canPinWidget()) AppWidgetManager.getInstance(this).requestPinAppWidget(widget(), null, null)
                result.success(null)
            }
            "canAddTile" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            "addTile" -> {
                addTile()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun canPinWidget(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && AppWidgetManager.getInstance(this).isRequestPinAppWidgetSupported

    private fun widget() = ComponentName(this, HisaabWidgetProvider::class.java)

    // why: the system dialog is the feedback; its answer changes nothing in the app (FR-SE-6).
    private fun addTile() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        getSystemService(StatusBarManager::class.java)?.requestAddTileService(
            ComponentName(this, AddSpendTileService::class.java),
            getString(R.string.tile_add_spend),
            Icon.createWithResource(this, R.drawable.ic_tile_add_spend),
            mainExecutor,
        ) { }
    }

    // why: a long-press on the tile opens its "preferences", which for hisaab is Home (FR-WG-6 AC-3).
    private fun uriOf(intent: Intent?): String? = when {
        intent == null -> null
        intent.action == TileService.ACTION_QS_TILE_PREFERENCES -> LaunchIntents.HOME
        intent.data?.scheme == SCHEME -> intent.dataString
        else -> null
    }

    private companion object {
        const val CHANNEL = "hisaab/shortcuts"
        const val SCHEME = "hisaab"
    }
}
