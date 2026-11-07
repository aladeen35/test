package com.aladeen.cardash;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Lists installed apps, highlights ones that are usually safe to disable on a car head unit,
 * and produces ADB commands (pm disable-user) that can be pasted into Bugjaeger / a PC.
 * Nothing is uninstalled; everything can be re-enabled with "pm enable".
 */
public class DebloatActivity extends Activity {

    /** Apps that are usually useless on a car screen. */
    private static final String[] SUGGESTED = {
            "com.android.email", "com.android.calendar", "com.android.deskclock", "com.android.gallery3d",
            "com.android.music", "com.android.soundrecorder", "com.android.printspooler", "com.android.bips",
            "com.android.egg", "com.android.dreams.basic", "com.android.dreams.phototable",
            "com.android.wallpaper.livepicker", "com.android.stk", "com.android.bookmarkprovider",
            "com.android.quicksearchbox", "com.android.browser", "com.android.calllogbackup",
            "com.android.wallpaperbackup", "com.android.traceur", "com.android.musicfx",
            "com.google.android.videos", "com.google.android.apps.photos", "com.google.android.apps.docs",
            "com.google.android.apps.tachyon", "com.google.android.feedback", "com.google.android.printservice.recommendation",
            "com.google.android.apps.wellbeing", "com.facebook.appmanager", "com.facebook.services", "com.facebook.system",
    };
    private static final String[] SUGGESTED_WORDS = {
            "kuwo", "qqmusic", "tencent", "baidu", "iqiyi", "kugou", "ximalaya", "autonavi", "amap", "netease",
            "facebook", "tiktok", "demo", "guide", "manual", "game"
    };
    /** Never touch these: system, Android Auto / phone link, CAN bus, radio, camera, Google services. */
    private static final String[] PROTECTED_WORDS = {
            "systemui", "settings", "launcher", "canbus", ".can", "mcu", "zlink", "carlink", "autokit", "carplay",
            "projection", "androidauto", "projection", "gms", "gsf", "vending", "webview", "bluetooth", ".bt",
            "radio", "avm", "camera", "reverse", "backcar", "phone", "telephony", "inputmethod", "keyboard",
            "packageinstaller", "permissioncontroller", "providers", "shell", "server", "media", "audio",
            "location", "documentsui", "externalstorage", "networkstack", "wifi", "tethering", "ota", "update",
            "aladeen", "youtube", "maps", "waze"
    };

    private final Set<String> selected = new LinkedHashSet<>();
    private LinearLayout list;
    private boolean showAll = false;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().getDecorView().setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        LinearLayout col = new LinearLayout(this);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setPadding(dp(16), dp(12), dp(16), dp(12));

        TextView t = text("تنظيف النظام", 22, Color.WHITE);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        col.addView(t);
        col.addView(text("التطبيقات البرتقالية مقترحة للتعطيل. الحمراء لا تلمسها. اضغط على أي تطبيق لفتح صفحته "
                + "(تعطيل / إيقاف إجباري / مسح البيانات). للتطبيقات التي لا يظهر لها زر تعطيل: حدّدها ثم انسخ أوامر ADB.", 13, 0xFF9AA4B2));

        LinearLayout btns = new LinearLayout(this);
        btns.setOrientation(LinearLayout.HORIZONTAL);
        col.addView(btns);
        btns.addView(btn("تحديد المقترح", v -> { selectSuggested(); render(); }));
        btns.addView(btn("نسخ أوامر ADB", v -> copyCommands()));
        btns.addView(btn("عرض الكل", v -> { showAll = !showAll; ((Button) v).setText(showAll ? "المقترح فقط" : "عرض الكل"); render(); }));
        btns.addView(btn("تسريع الحركة", v -> openDevSettings()));

        ScrollView sv = new ScrollView(this);
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        sv.addView(list);
        col.addView(sv, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(col);
        render();
    }

    private enum Kind { SUGGESTED, NORMAL, PROTECTED }

    private static Kind classify(String pkg) {
        String p = pkg.toLowerCase(Locale.ROOT);
        for (String s : SUGGESTED) if (p.equals(s)) return Kind.SUGGESTED;
        for (String w : PROTECTED_WORDS) if (p.contains(w)) return Kind.PROTECTED;
        for (String w : SUGGESTED_WORDS) if (p.contains(w)) return Kind.SUGGESTED;
        return Kind.NORMAL;
    }

    private List<ApplicationInfo> apps() {
        PackageManager pm = getPackageManager();
        List<ApplicationInfo> all = pm.getInstalledApplications(PackageManager.MATCH_DISABLED_COMPONENTS);
        List<ApplicationInfo> out = new ArrayList<>();
        for (ApplicationInfo a : all) {
            Kind k = classify(a.packageName);
            if (showAll || k == Kind.SUGGESTED) out.add(a);
        }
        Collections.sort(out, (x, y) -> {
            int c = classify(x.packageName).ordinal() - classify(y.packageName).ordinal();
            return c != 0 ? c : x.packageName.compareTo(y.packageName);
        });
        return out;
    }

    private void selectSuggested() {
        for (ApplicationInfo a : getPackageManager().getInstalledApplications(0))
            if (classify(a.packageName) == Kind.SUGGESTED && a.enabled) selected.add(a.packageName);
    }

    private void render() {
        list.removeAllViews();
        PackageManager pm = getPackageManager();
        List<ApplicationInfo> apps = apps();
        if (apps.isEmpty()) {
            list.addView(text("\n✅ لا توجد تطبيقات زائدة معروفة. اضغط «عرض الكل» لرؤية بقية التطبيقات.", 15, Color.WHITE));
            return;
        }
        for (ApplicationInfo a : apps) {
            Kind k = classify(a.packageName);
            LinearLayout r = new LinearLayout(this);
            r.setOrientation(LinearLayout.HORIZONTAL);
            r.setGravity(Gravity.CENTER_VERTICAL);
            r.setPadding(0, dp(6), 0, dp(6));

            CheckBox cb = new CheckBox(this);
            cb.setChecked(selected.contains(a.packageName));
            cb.setEnabled(k != Kind.PROTECTED);
            cb.setOnCheckedChangeListener((x, on) -> { if (on) selected.add(a.packageName); else selected.remove(a.packageName); });
            r.addView(cb);

            LinearLayout info = new LinearLayout(this);
            info.setOrientation(LinearLayout.VERTICAL);
            int color = k == Kind.SUGGESTED ? 0xFFFFA726 : k == Kind.PROTECTED ? 0xFFEF5350 : Color.WHITE;
            String label = String.valueOf(a.loadLabel(pm));
            String state = a.enabled ? "" : "  (معطّل)";
            info.addView(text(label + state, 15, color));
            info.addView(text(a.packageName + (k == Kind.PROTECTED ? "  — لا تعطّله" : ""), 11, 0xFF9AA4B2));
            r.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
            r.setOnClickListener(v -> startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:" + a.packageName))));
            list.addView(r);
        }
    }

    private void copyCommands() {
        if (selected.isEmpty()) { Toast.makeText(this, "حدّد تطبيقات أولاً", Toast.LENGTH_SHORT).show(); return; }
        StringBuilder sb = new StringBuilder();
        for (String p : selected) sb.append("pm disable-user --user 0 ").append(p).append('\n');
        ClipboardManager cm = getSystemService(ClipboardManager.class);
        cm.setPrimaryClip(ClipData.newPlainText("adb", sb.toString()));
        Toast.makeText(this, "تم نسخ " + selected.size() + " أمر. الصقها في Bugjaeger (Shell).", Toast.LENGTH_LONG).show();
    }

    private void openDevSettings() {
        Toast.makeText(this, "اضبط: Window/Transition/Animator animation scale على 0.5x", Toast.LENGTH_LONG).show();
        try { startActivity(new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)); }
        catch (Exception e) {
            Toast.makeText(this, "فعّل خيارات المطوّر: اضغط 7 مرات على Build number", Toast.LENGTH_LONG).show();
            startActivity(new Intent(Settings.ACTION_DEVICE_INFO_SETTINGS));
        }
    }

    private TextView text(String s, float sp, int color) {
        TextView t = new TextView(this);
        t.setText(s);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp);
        t.setTextColor(color);
        return t;
    }

    private Button btn(String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setAllCaps(false);
        b.setOnClickListener(l);
        return b;
    }

    private int dp(float v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, getResources().getDisplayMetrics());
    }
}
