package com.widgetsandco.hisaab.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WideColumnTest {
    @Test
    fun keepsTheDesignWidthWhenTheTitleFits() {
        assertEquals(112, WideColumn.width(titleDp = 104.2f, widgetWidthDp = 395))
    }

    @Test
    fun growsToTheTitleWhenItIsWider() {
        // why: "Safe to spend today" at 12sp in Mukta measured about 131dp on a moto g45.
        assertEquals(132, WideColumn.width(titleDp = 131.2f, widgetWidthDp = 395))
    }

    @Test
    fun leavesTheBarItsMinimumOnANarrowWidget() {
        // 260dp less padding 38, gaps 24, key 48 and a 48dp bar leaves 102 — under the design width.
        assertEquals(112, WideColumn.width(titleDp = 180f, widgetWidthDp = 260))
        // 395dp less 38 + 24 + 48 + 48 leaves 237 for a large-font title.
        assertEquals(237, WideColumn.width(titleDp = 300f, widgetWidthDp = 395))
    }

    @Test
    fun theBarTakesWhatTheColumnLeaves() {
        assertEquals(395 - 38 - 24 - 48 - 132, WideColumn.barWidth(columnDp = 132, widgetWidthDp = 395))
    }
}
