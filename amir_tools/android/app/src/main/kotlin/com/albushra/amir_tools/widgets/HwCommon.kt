package com.albushra.amir_tools.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.os.SystemClock
import android.widget.RemoteViews
import com.albushra.amir_tools.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * أساس كل ودجات «أدوات أمير»: يعيد الرسم عند تغيير حجم الودجت (لاختيار التصميم المختصر).
 * البيانات يكتبها فلاتر (lib/services/home_widgets.dart) كنص JSON مترجم جاهز لكل ودجت.
 */
abstract class HwProvider : HomeWidgetProvider() {
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        try {
            onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
        } catch (e: Exception) {
            // لا نُسقط عملية المشغّل أبدًا
        }
    }
}

internal object Hw {
    const val DAY_MS = 86_400_000L

    /** قراءة JSON محفوظ من فلاتر (أو null إن لم يُكتب بعد / تلف) */
    fun data(prefs: SharedPreferences, key: String): JSONObject? = try {
        val raw = prefs.getString(key, null)
        if (raw.isNullOrEmpty()) null else JSONObject(raw)
    } catch (e: Exception) {
        null
    }

    fun objects(arr: JSONArray?): List<JSONObject> {
        if (arr == null) return emptyList()
        val out = ArrayList<JSONObject>(arr.length())
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i)
            if (o != null) out.add(o)
        }
        return out
    }

    /** نص من JSON مع بديل إن كان فارغًا */
    fun str(o: JSONObject?, key: String, fallback: String = ""): String {
        if (o == null || !o.has(key) || o.isNull(key)) return fallback
        val v = o.optString(key, fallback)
        return if (v.isEmpty()) fallback else v
    }

    /** فتح التطبيق على رابط عميق: ameertools://tool/<id> أو ameertools://tab/<name> */
    fun open(context: Context, link: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(link))

    /** فتح التطبيق فقط */
    fun openApp(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

    /** ارتفاع الودجت الفعلي بالـ dp (الوضع العمودي)، أو 0 إن لم يُعرف */
    fun heightDp(mgr: AppWidgetManager, id: Int): Int = try {
        val o = mgr.getAppWidgetOptions(id)
        if (o == null) {
            0
        } else {
            val h = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            if (h > 0) h else o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        }
    } catch (e: Exception) {
        0
    }

    /** عدّاد تنازلي حي حتى [target] (وقت حائط بالمللي ثانية) */
    fun countdown(views: RemoteViews, viewId: Int, target: Long) {
        val base = SystemClock.elapsedRealtime() + (target - System.currentTimeMillis())
        views.setChronometer(viewId, base, null, true)
        views.setChronometerCountDown(viewId, true)
    }

    fun startOfToday(now: Long): Long {
        val c = Calendar.getInstance()
        c.timeInMillis = now
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }

    fun startOfTomorrow(now: Long): Long {
        val c = Calendar.getInstance()
        c.timeInMillis = startOfToday(now)
        c.add(Calendar.DAY_OF_YEAR, 1)
        return c.timeInMillis
    }

    fun bitmap(path: String?): Bitmap? = try {
        if (path.isNullOrEmpty()) null else BitmapFactory.decodeFile(path)
    } catch (e: Throwable) {
        null
    }

    private fun updateIntent(context: Context, provider: Class<*>, requestCode: Int): PendingIntent {
        val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, provider))
        val intent = Intent(context, provider)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * تحديث الودجت عند لحظة معيّنة (منبّه غير دقيق، بلا صلاحية المنبّهات الدقيقة).
     * RTC (لا يوقظ الجهاز): يصل عند إيقاظ الشاشة، وهو وقت رؤية الودجت أصلًا.
     */
    fun scheduleAt(context: Context, provider: Class<*>, requestCode: Int, at: Long) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val pi = updateIntent(context, provider, requestCode)
            if (at <= System.currentTimeMillis()) {
                am.cancel(pi)
                return
            }
            am.set(AlarmManager.RTC, at, pi)
        } catch (e: Exception) {
            // لا شيء: التحديث الدوري (30 دقيقة) يبقى احتياطًا
        }
    }

    fun cancel(context: Context, provider: Class<*>, requestCode: Int) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            am.cancel(updateIntent(context, provider, requestCode))
        } catch (e: Exception) {
        }
    }
}
