package com.albushra.amir_tools.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import com.albushra.amir_tools.R
import org.json.JSONObject

/**
 * ودجت قطوعات الكهرباء (3×2، ومختصرة 3×1): الحالة الآن حسب الجدول، التغيير الجاي مع عدّاد،
 * وقطوعات اليوم الباقية. فلاتر يكتب انتقالات الأيام القادمة [{on, t, l}] وفترات القطع [{s, e, l}].
 */
class PowerCutsWidgetProvider : HwProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = Hw.data(widgetData, "hw_power")
        val now = System.currentTimeMillis()
        val events = Hw.objects(d?.optJSONArray("ev")).sortedBy { it.optLong("t", 0L) }
        val has = events.isNotEmpty()

        // الحالة الآن = آخر انتقال مضى؛ التالي = أول انتقال قادم
        var on = true
        var next: JSONObject? = null
        for (e in events) {
            if (e.optLong("t", 0L) <= now) {
                on = e.optBoolean("on", true)
            } else {
                next = e
                break
            }
        }
        if (has && next == null && events.last().optLong("t", 0L) <= now) {
            // انتهت البيانات المكتوبة: الأرجح أن الكهرباء جاية حتى يُفتح التطبيق
            on = true
        }

        val tomorrow = Hw.startOfTomorrow(now)
        val today = ArrayList<String>()
        for (s in Hw.objects(d?.optJSONArray("sl"))) {
            if (s.optLong("e", 0L) > now && s.optLong("s", 0L) < tomorrow) today.add(Hw.str(s, "l"))
        }

        for (widgetId in appWidgetIds) {
            try {
                val compact = Hw.heightDp(appWidgetManager, widgetId) in 1..99
                val views = RemoteViews(context.packageName, if (compact) R.layout.hw_power_small else R.layout.hw_power)
                views.setOnClickPendingIntent(R.id.pw_root, Hw.open(context, "ameertools://tool/power_cuts"))
                val title = Hw.str(d, "title", context.getString(R.string.hw_power_label))
                views.setTextViewText(R.id.pw_title, "⚡ $title")
                if (!has) {
                    views.setViewVisibility(R.id.pw_content, View.GONE)
                    views.setViewVisibility(R.id.pw_title, View.VISIBLE)
                    views.setViewVisibility(R.id.pw_empty, View.VISIBLE)
                    views.setTextViewText(R.id.pw_empty, Hw.str(d, "empty", context.getString(R.string.hw_open_app)))
                } else {
                    views.setViewVisibility(R.id.pw_empty, View.GONE)
                    views.setViewVisibility(R.id.pw_content, View.VISIBLE)
                    views.setTextViewText(R.id.pw_status, Hw.str(d, if (on) "on" else "off"))
                    views.setTextColor(R.id.pw_status, if (on) ON_COLOR else OFF_COLOR)
                    views.setTextViewText(R.id.pw_sched, Hw.str(d, "sched"))
                    val n = next
                    if (n != null) {
                        val label = Hw.str(d, if (n.optBoolean("on", true)) "nextOn" else "nextOff")
                        views.setTextViewText(R.id.pw_next, label + " " + Hw.str(n, "l"))
                        views.setViewVisibility(R.id.pw_count, View.VISIBLE)
                        Hw.countdown(views, R.id.pw_count, n.optLong("t", now))
                    } else {
                        views.setTextViewText(R.id.pw_next, Hw.str(d, "noNext"))
                        views.setViewVisibility(R.id.pw_count, View.GONE)
                    }
                    if (!compact) {
                        views.setTextViewText(R.id.pw_today_l, Hw.str(d, "todayL"))
                        views.setTextViewText(
                            R.id.pw_today,
                            if (today.isEmpty()) Hw.str(d, "none") else today.take(3).joinToString("\n"),
                        )
                    }
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
            }
        }

        if (has) {
            // عند الانتقال القادم، أو منتصف الليل لتحديث قائمة اليوم — أيهما أقرب
            val at = next?.optLong("t", tomorrow) ?: tomorrow
            Hw.scheduleAt(context, PowerCutsWidgetProvider::class.java, REQ, minOf(at, tomorrow) + 1000L)
        } else {
            Hw.cancel(context, PowerCutsWidgetProvider::class.java, REQ)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Hw.cancel(context, PowerCutsWidgetProvider::class.java, REQ)
    }

    companion object {
        private const val REQ = 7103
        private val ON_COLOR = Color.parseColor("#FF8EE59B")
        private val OFF_COLOR = Color.parseColor("#FFFF8A80")
    }
}
