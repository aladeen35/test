package com.albushra.amir_tools.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.view.View
import android.widget.RemoteViews
import com.albushra.amir_tools.R
import org.json.JSONObject

/**
 * ودجت المفضلة (4×2): حتى 8 أدوات. كل بلاطة صورة PNG رسمها فلاتر (أيقونة الأداة بتدرّجها واسمها)،
 * والضغط عليها يفتح ameertools://tool/<id>. الرأس يفتح التطبيق.
 */
class FavoritesWidgetProvider : HwProvider() {

    private val tiles = intArrayOf(
        R.id.fav_t0, R.id.fav_t1, R.id.fav_t2, R.id.fav_t3,
        R.id.fav_t4, R.id.fav_t5, R.id.fav_t6, R.id.fav_t7,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = Hw.data(widgetData, "hw_fav")
        val ids = d?.optJSONArray("ids")
        val imgs = d?.optJSONArray("imgs")
        val count = minOf(ids?.length() ?: 0, tiles.size)
        // فك الصور مرة واحدة لكل التحديث
        val bitmaps = (0 until count).map { Hw.bitmap(imgs?.optString(it, null)) }

        for (widgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(widgetId, build(context, d, count, bitmaps))
            } catch (e: Exception) {
                // إن تجاوزت الصور حد RemoteViews: نعيد المحاولة بنصف الدقة
                try {
                    val small = bitmaps.map { b ->
                        if (b == null) null else Bitmap.createScaledBitmap(b, maxOf(1, b.width / 2), maxOf(1, b.height / 2), true)
                    }
                    appWidgetManager.updateAppWidget(widgetId, build(context, d, count, small))
                } catch (e2: Exception) {
                    // نتجاهل: يبقى آخر شكل معروض
                }
            }
        }
    }

    private fun build(context: Context, d: JSONObject?, count: Int, bitmaps: List<Bitmap?>): RemoteViews {
        val ids = d?.optJSONArray("ids")
        val names = d?.optJSONArray("names")
        val views = RemoteViews(context.packageName, R.layout.hw_favorites)
        views.setOnClickPendingIntent(R.id.fav_root, Hw.openApp(context))
        views.setOnClickPendingIntent(R.id.fav_header, Hw.openApp(context))
        views.setTextViewText(R.id.fav_title, Hw.str(d, "title", context.getString(R.string.hw_app_name)))

        if (count == 0) {
            views.setViewVisibility(R.id.fav_row1, View.GONE)
            views.setViewVisibility(R.id.fav_row2, View.GONE)
            views.setViewVisibility(R.id.fav_empty, View.VISIBLE)
            views.setTextViewText(R.id.fav_empty, Hw.str(d, "empty", context.getString(R.string.hw_open_app)))
            return views
        }
        views.setViewVisibility(R.id.fav_empty, View.GONE)
        views.setViewVisibility(R.id.fav_row1, View.VISIBLE)
        views.setViewVisibility(R.id.fav_row2, if (count > 4) View.VISIBLE else View.GONE)
        for (i in tiles.indices) {
            val v = tiles[i]
            if (i < count) {
                val id = ids?.optString(i, "") ?: ""
                val bmp = bitmaps.getOrNull(i)
                if (bmp != null) {
                    views.setImageViewBitmap(v, bmp)
                } else {
                    views.setImageViewResource(v, R.drawable.hw_tile_ph)
                }
                views.setContentDescription(v, names?.optString(i, id) ?: id)
                views.setViewVisibility(v, View.VISIBLE)
                if (id.isNotEmpty()) {
                    views.setOnClickPendingIntent(v, Hw.open(context, "ameertools://tool/$id"))
                }
            } else {
                // مكان فارغ: مخفي مع الحفاظ على محاذاة الشبكة
                views.setViewVisibility(v, View.INVISIBLE)
            }
        }
        return views
    }
}
