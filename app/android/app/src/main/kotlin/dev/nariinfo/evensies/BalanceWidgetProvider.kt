package dev.nariinfo.evensies

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/** The 2×2 home-screen balance (docs/API.md, Home screen widget): the app writes a pre-formatted, pre-translated JSON under
 * `summary`; this only draws it. Never written: only the title. */
class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val summary = widgetData.getString("summary", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
        val lineIds = listOf(
            Triple(R.id.line1, R.id.line1_text, R.id.line1_amount),
            Triple(R.id.line2, R.id.line2_text, R.id.line2_amount),
            Triple(R.id.line3, R.id.line3_text, R.id.line3_amount),
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget)
            views.setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            // The ≈ total first (when every currency converts), then the balance per currency.
            val lines = buildList {
                summary?.optJSONObject("total")?.let { add(it) }
                val each = summary?.optJSONArray("lines")
                for (i in 0 until (each?.length() ?: 0)) each?.optJSONObject(i)?.let { add(it) }
            }
            for ((i, ids) in lineIds.withIndex()) {
                val line = lines.getOrNull(i)
                if (line == null) {
                    views.setViewVisibility(ids.first, View.GONE)
                    continue
                }
                views.setViewVisibility(ids.first, View.VISIBLE)
                views.setTextViewText(ids.second, line.optString("text"))
                views.setTextViewText(ids.third, line.optString("amount"))
                val color = if (line.optString("tone") == "owe") R.color.widget_owe else R.color.widget_owed
                views.setTextColor(ids.third, context.getColor(color))
            }
            val more = lines.size > lineIds.size
            views.setViewVisibility(R.id.more, if (more) View.VISIBLE else View.GONE)
            val empty = summary?.optString("empty")?.takeIf { !summary.isNull("empty") && it.isNotEmpty() }
            views.setViewVisibility(R.id.empty, if (empty == null) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.empty, empty ?: "")
            val updated = summary?.optString("updated")?.takeIf { !summary.isNull("updated") }
            views.setViewVisibility(R.id.updated, if (updated == null) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.updated, updated ?: "")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
