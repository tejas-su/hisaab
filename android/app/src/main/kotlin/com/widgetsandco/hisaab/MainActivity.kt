package com.widgetsandco.hisaab

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
        }
    }
}
