package com.widgetsandco.hisaab.tile

import android.annotation.SuppressLint
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.widgetsandco.hisaab.R
import com.widgetsandco.hisaab.widget.LaunchIntents

/**
 * The Quick Settings tile "Add a spend · hisaab" (SPEC FR-WG-6, T1). It reads no data and never
 * shows money, so the shade shows nothing about money on the lock screen (E56). A tap unlocks if
 * needed, collapses the shade and opens the Add tray at the keypad.
 */
class AddSpendTileService : TileService() {
    override fun onStartListening() {
        val tile = qsTile ?: return
        tile.state = Tile.STATE_INACTIVE
        tile.label = getString(R.string.tile_add_spend)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) tile.subtitle = getString(R.string.widget_name)
        tile.updateTile()
    }

    override fun onClick() {
        if (isLocked) unlockAndRun(::open) else open()
    }

    // why: Android 14 takes only a PendingIntent here; earlier versions only the Intent form.
    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun open() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(LaunchIntents.pending(this, LaunchIntents.ADD))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(LaunchIntents.intent(this, LaunchIntents.ADD))
        }
    }
}
