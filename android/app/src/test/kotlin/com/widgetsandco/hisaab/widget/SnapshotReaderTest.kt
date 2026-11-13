package com.widgetsandco.hisaab.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class SnapshotReaderTest {
    private fun row(date: String, hero: String = "₹1,430", over: String = "null", tick: String = "null", state: String = "onTrack") = """
        {"date":"$date","state":"$state","hero":"$hero","heroMuted":false,"over":$over,"glance":"left today",
         "range":"Lasts till payday · about ₹9,300 spare","days":"9 days","daysLeft":"9 days left","flag":"4 Nov",
         "bar":{"style":"onTrack","left":0.773,"bites":[0.205,0.022],"tick":$tick},
         "dots":{"count":9,"style":"onTrack"},"spoken":"Safe to spend today: 1,430 rupees."}
    """.trimIndent()

    private fun snapshot(vararg rows: String, version: Int = 1, look: String = "dark") = """
        {"v":$version,"writtenAt":"2026-10-26T21:14:05.000","look":"$look",
         "strings":{"title":"Safe to spend today","add":"Add","addSpoken":"Add a spend","setUp":"Set up","setUpBody":"Set up hisaab."},
         "rows":[${rows.joinToString(",")}]}
    """.trimIndent()

    private val today: LocalDate = LocalDate.of(2026, 10, 26)

    @Test
    fun picksTodaysRow() {
        val content = SnapshotReader.contentFor(snapshot(row("2026-10-25", hero = "₹9"), row("2026-10-26"), row("2026-10-27", hero = "₹2,000")), today)

        content as WidgetContent.Day
        assertEquals("dark", content.look)
        assertEquals("Add a spend", content.strings.addSpoken)
        assertEquals("₹1,430", content.row.hero)
        assertEquals(listOf(0.205, 0.022), content.row.bar.bites)
        assertNull(content.row.bar.tick)
        assertNull(content.row.over)
        assertEquals(9, content.row.dots.count)
    }

    @Test
    fun readsTheOverLineAndTick() {
        val content = SnapshotReader.contentFor(snapshot(row("2026-10-26", over = "\"₹220 over today\"", tick = "0.9")), today) as WidgetContent.Day

        assertEquals("₹220 over today", content.row.over)
        assertEquals(0.9, content.row.bar.tick!!, 0.0)
    }

    @Test
    fun aNoIncomeDayAsksToSetUp() {
        val content = SnapshotReader.contentFor(snapshot(row("2026-10-26", state = "setUp")), today) as WidgetContent.Day

        assertTrue(content.row.isSetUp)
    }

    @Test
    fun aDayPastTheLastRowIsStaleInTheSavedLook() {
        assertEquals(WidgetContent.Stale("dark"), SnapshotReader.contentFor(snapshot(row("2026-10-26")), today.plusDays(1)))
    }

    @Test
    fun aDayBeforeTheFirstRowIsStale() {
        assertEquals(WidgetContent.Stale("dark"), SnapshotReader.contentFor(snapshot(row("2026-10-26")), today.minusDays(1)))
    }

    @Test
    fun noSnapshotIsStaleInThePhonesLook() {
        assertEquals(WidgetContent.Stale("system"), SnapshotReader.contentFor(null, today))
        assertEquals(WidgetContent.Stale("system"), SnapshotReader.contentFor("", today))
    }

    @Test
    fun badJsonIsStale() {
        assertEquals(WidgetContent.Stale("system"), SnapshotReader.contentFor("{not json", today))
    }

    @Test
    fun anUnknownVersionIsStale() {
        assertEquals(WidgetContent.Stale("system"), SnapshotReader.contentFor(snapshot(row("2026-10-26"), version = 2), today))
    }

    @Test
    fun aRowMissingAFieldIsStale() {
        val broken = snapshot(row("2026-10-26").replace("\"hero\":\"₹1,430\",", ""))

        assertEquals(WidgetContent.Stale("dark"), SnapshotReader.contentFor(broken, today))
    }

    @Test
    fun aBadDateIsStale() {
        assertEquals(WidgetContent.Stale("dark"), SnapshotReader.contentFor(snapshot(row("26-10-2026")), today))
    }
}
