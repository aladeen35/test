package com.albushra.amir_tools.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.albushra.amir_tools.R
import kotlin.math.roundToInt

/**
 * ودجت أنبوبة الغاز (2×2): الأيام الباقية (رقم كبير)، شريط ذهبي لما تبقّى، تاريخ النفاد المتوقع وآخر تعبئة.
 * فلاتر يكتب لحظة النفاد وآخر تعبئة؛ الأيام تُحسب هنا من الساعة الحالية فتبقى صحيحة يوميًا.
 */
class GasWidgetProvider : HwProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = Hw.data(widgetData, "hw_gas")
        val now = System.currentTimeMillis()
        val out = d?.optLong("out", 0L) ?: 0L
        val last = d?.optLong("last", 0L) ?: 0L
        val has = out > 0L && last > 0L

        for (widgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.hw_gas)
                views.setOnClickPendingIntent(R.id.gas_root, Hw.open(context, "ameertools://tool/gas"))
                views.setTextViewText(R.id.gas_title, "🔥 " + Hw.str(d, "title", context.getString(R.string.hw_gas_label)))
                if (!has) {
                    views.setViewVisibility(R.id.gas_content, View.GONE)
                    views.setViewVisibility(R.id.gas_empty, View.VISIBLE)
                    views.setTextViewText(R.id.gas_empty, Hw.str(d, "empty", context.getString(R.string.hw_open_app)))
                } else {
                    val daysLeft = ((out - Hw.startOfToday(now)).toDouble() / Hw.DAY_MS).roundToInt()
                    val span = (out - last).coerceAtLeast(1L)
                    val remaining = ((out - now).toDouble() / span).coerceIn(0.0, 1.0)
                    views.setViewVisibility(R.id.gas_empty, View.GONE)
                    views.setViewVisibility(R.id.gas_content, View.VISIBLE)
                    views.setTextViewText(R.id.gas_days, maxOf(daysLeft, 0).toString())
                    views.setTextViewText(
                        R.id.gas_days_l,
                        when {
                            daysLeft > 0 -> Hw.str(d, "days")
                            daysLeft == 0 -> Hw.str(d, "today")
                            else -> Hw.str(d, "over")
                        },
                    )
                    views.setProgressBar(R.id.gas_bar, 100, (remaining * 100).roundToInt(), false)
                    views.setTextViewText(R.id.gas_out, Hw.str(d, "outL"))
                    views.setTextViewText(R.id.gas_last, Hw.str(d, "lastL"))
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
            }
        }

        // يتغيّر العدّ بعد منتصف الليل
        if (has) {
            Hw.scheduleAt(context, GasWidgetProvider::class.java, REQ, Hw.startOfTomorrow(now) + 60_000L)
        } else {
            Hw.cancel(context, GasWidgetProvider::class.java, REQ)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Hw.cancel(context, GasWidgetProvider::class.java, REQ)
    }

    companion object {
        private const val REQ = 7102
    }
}
