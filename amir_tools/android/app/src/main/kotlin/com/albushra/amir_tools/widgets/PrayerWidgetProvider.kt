package com.albushra.amir_tools.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.albushra.amir_tools.R
import org.json.JSONObject

/**
 * ودجت الصلاة (3×2، وتصميم مختصر عند 4×1): الصلاة القادمة، وقتها، عدّاد تنازلي حي، المدينة، والتاريخ الهجري.
 * فلاتر يكتب مواقيت الأيام القادمة [{n, t, l, h}]؛ هنا نختار أول وقت بعد الآن ونجدول تحديثًا عنده.
 */
class PrayerWidgetProvider : HwProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = Hw.data(widgetData, "hw_prayer")
        val now = System.currentTimeMillis()
        var next: JSONObject? = null
        for (e in Hw.objects(d?.optJSONArray("ev"))) {
            if (e.optLong("t", 0L) > now) {
                next = e
                break
            }
        }

        for (widgetId in appWidgetIds) {
            try {
                val compact = Hw.heightDp(appWidgetManager, widgetId) in 1..99
                val views = RemoteViews(context.packageName, if (compact) R.layout.hw_prayer_wide else R.layout.hw_prayer)
                views.setOnClickPendingIntent(R.id.pr_root, Hw.open(context, "ameertools://tab/prayer"))
                val n = next
                if (n == null) {
                    views.setViewVisibility(R.id.pr_content, View.GONE)
                    views.setViewVisibility(R.id.pr_empty, View.VISIBLE)
                    views.setTextViewText(R.id.pr_empty, Hw.str(d, "empty", context.getString(R.string.hw_open_app)))
                } else {
                    views.setViewVisibility(R.id.pr_empty, View.GONE)
                    views.setViewVisibility(R.id.pr_content, View.VISIBLE)
                    views.setTextViewText(R.id.pr_city, Hw.str(d, "city"))
                    views.setTextViewText(R.id.pr_label, Hw.str(d, "lbl"))
                    views.setTextViewText(R.id.pr_name, Hw.str(n, "n"))
                    views.setTextViewText(R.id.pr_time, Hw.str(n, "l"))
                    views.setTextViewText(R.id.pr_hijri, Hw.str(n, "h"))
                    Hw.countdown(views, R.id.pr_count, n.optLong("t", now))
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
            }
        }

        val n = next
        if (n != null) {
            // ثانية بعد دخول الوقت ننتقل للصلاة التالية
            Hw.scheduleAt(context, PrayerWidgetProvider::class.java, REQ, n.optLong("t", 0L) + 1000L)
        } else {
            Hw.cancel(context, PrayerWidgetProvider::class.java, REQ)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Hw.cancel(context, PrayerWidgetProvider::class.java, REQ)
    }

    companion object {
        private const val REQ = 7101
    }
}
