package com.widgetsandco.hisaab

import android.app.ActivityManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
}
