package com.widgetsandco.hisaab.widget

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeParseException

/** The words that are the same on every day, worded by the app (widget spec §4). */
data class WidgetStrings(
    val title: String,
    val add: String,
    val addSpoken: String,
    val setUp: String,
    val setUpBody: String,
)

/** Today's bar as shares of its span (BR-6): [style] is `onTrack`, `slowDown` or `over`. */
data class BarSpec(val style: String, val left: Double, val bites: List<Double>, val tick: Double?)

/** The days rail: [count] dots, today's first, drawn in [style] (BR-5). */
data class DotsSpec(val count: Int, val style: String)

/** One day of the widget, every word already formatted by the app. */
data class WidgetRow(
    val date: LocalDate,
    val state: String,
    val hero: String,
    val heroMuted: Boolean,
    val over: String?,
    val glance: String,
    val range: String,
    val days: String,
    val daysLeft: String,
    val flag: String,
    val bar: BarSpec,
    val dots: DotsSpec,
    val spoken: String,
) {
    /** No income yet: the widget asks to set up (FR-WG-3). */
    val isSetUp: Boolean get() = state == "setUp"
}

/** What the widget draws now. */
sealed interface WidgetContent {
    /** The app's *Look*: `system`, `light` or `dark`. */
    val look: String

    /** [row] is today's. */
    data class Day(override val look: String, val strings: WidgetStrings, val row: WidgetRow) : WidgetContent

    /** No row for today: the app hasn't been opened for too long, or never wrote one (E53, W3). */
    data class Stale(override val look: String) : WidgetContent
}

/**
 * Reads the snapshot the app writes (`WidgetSnapshotJson` in Dart) and picks today's row. Pure: no
 * Android, so it is unit-tested on the JVM. Native code never words or formats anything.
 */
object SnapshotReader {
    /** The only format version this reader knows; keep in step with `WidgetSnapshotJson.version`. */
    const val VERSION = 1

    private const val DEFAULT_LOOK = "system"

    /** What to draw on [today] from [json]; stale when it is missing, unreadable, of another version or has no row for [today]. */
    fun contentFor(json: String?, today: LocalDate): WidgetContent {
        val root = parse(json) ?: return WidgetContent.Stale(DEFAULT_LOOK)
        val look = root.optString("look", DEFAULT_LOOK)
        return try {
            val row = rows(root.getJSONArray("rows")).firstOrNull { it.date == today }
                ?: return WidgetContent.Stale(look)
            WidgetContent.Day(look, strings(root.getJSONObject("strings")), row)
        } catch (error: JSONException) {
            WidgetContent.Stale(look)
        } catch (error: DateTimeParseException) {
            WidgetContent.Stale(look)
        }
    }

    private fun parse(json: String?): JSONObject? {
        if (json.isNullOrBlank()) return null
        return try {
            JSONObject(json).takeIf { it.optInt("v", -1) == VERSION }
        } catch (error: JSONException) {
            null
        }
    }

    private fun strings(json: JSONObject) = WidgetStrings(
        title = json.getString("title"),
        add = json.getString("add"),
        addSpoken = json.getString("addSpoken"),
        setUp = json.getString("setUp"),
        setUpBody = json.getString("setUpBody"),
    )

    private fun rows(array: JSONArray): List<WidgetRow> = (0 until array.length()).map { row(array.getJSONObject(it)) }

    private fun row(json: JSONObject): WidgetRow {
        val bar = json.getJSONObject("bar")
        val bites = bar.getJSONArray("bites")
        val dots = json.getJSONObject("dots")
        return WidgetRow(
            date = LocalDate.parse(json.getString("date")),
            state = json.getString("state"),
            hero = json.getString("hero"),
            heroMuted = json.getBoolean("heroMuted"),
            over = json.optStringOrNull("over"),
            glance = json.getString("glance"),
            range = json.getString("range"),
            days = json.getString("days"),
            daysLeft = json.getString("daysLeft"),
            flag = json.getString("flag"),
            bar = BarSpec(
                style = bar.getString("style"),
                left = bar.getDouble("left"),
                bites = (0 until bites.length()).map { bites.getDouble(it) },
                tick = if (bar.isNull("tick")) null else bar.getDouble("tick"),
            ),
            dots = DotsSpec(count = dots.getInt("count"), style = dots.getString("style")),
            spoken = json.getString("spoken"),
        )
    }

    private fun JSONObject.optStringOrNull(key: String): String? = if (isNull(key)) null else getString(key)
}
