package com.albushra.amir_tools.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.albushra.amir_tools.R

/**
 * ودجت الدولار (2×1 / 3×1): سعر الموازي والرسمي بالجنيه ووقت آخر تحديث.
 */
class DollarWidgetProvider : HwProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = Hw.data(widgetData, "hw_fx")
        for (widgetId in appWidgetIds) {
            try {
                val h = Hw.heightDp(appWidgetManager, widgetId)
                val views = RemoteViews(context.packageName, R.layout.hw_fx)
                views.setOnClickPendingIntent(R.id.fx_root, Hw.open(context, "ameertools://tool/currency"))
                views.setTextViewText(R.id.fx_title, "💵 " + Hw.str(d, "title", context.getString(R.string.hw_fx_label)))
                // في الارتفاع الصغير نخفي العنوان ليتسع الرقمان
                views.setViewVisibility(R.id.fx_title, if (h in 1..69) View.GONE else View.VISIBLE)
                views.setTextViewText(R.id.fx_par_l, Hw.str(d, "parL"))
                views.setTextViewText(R.id.fx_par, Hw.str(d, "par", "—"))
                views.setTextViewText(R.id.fx_off_l, Hw.str(d, "offL"))
                views.setTextViewText(R.id.fx_off, Hw.str(d, "off", "—"))
                views.setTextViewText(R.id.fx_upd, Hw.str(d, "upd", context.getString(R.string.hw_open_app)))
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
            }
        }
    }
}
