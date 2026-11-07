package com.aladeen.cardash;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity {
    private LinearLayout permCard;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().getDecorView().setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        buildUi();
        requestRuntimePermissions();
    }

    @Override protected void onResume() {
        super.onResume();
        buildUi(); // refresh tiles (e.g. an app installed meanwhile)
        refreshPermissionCard();
    }

    // ------------------------------------------------------------------ UI

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        LinearLayout col = new LinearLayout(this);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setPadding(dp(20), dp(16), dp(20), dp(24));
        scroll.addView(col);

        TextView title = text("لوحة السيارة", 26, Color.WHITE);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        col.addView(title);
        col.addView(text("خرائط + يوتيوب عائم + مرآة الكاميرا الخلفية", 14, 0xFF9AA4B2));

        // ---- permissions ----
        permCard = card();
        col.addView(permCard, lpTop(16));

        // ---- tiles ----
        GridLayout grid = new GridLayout(this);
        boolean wide = getResources().getConfiguration().screenWidthDp > 600;
        grid.setColumnCount(wide ? 3 : 2);
        col.addView(grid, lpTop(16));

        addTile(grid, "🚗", "وضع القيادة", "خرائط + كاميرا + يوتيوب", 0xFF1E88E5, v -> driveMode());
        addTile(grid, "🗺️", "الخرائط", "فتح تطبيق الخرائط", 0xFF2E7D32, v -> openMaps());
        addTile(grid, "▶️", "يوتيوب عائم", "إظهار / إخفاء", 0xFFC62828, v -> FloatingService.send(this, FloatingService.ACTION_YOUTUBE));
        addAppTile(grid, "com.albushra.player", "البشرى", 0xFF00695C);
        addTile(grid, "📷", "مرآة الكاميرا", "إظهار / إخفاء", 0xFF6A1B9A, v -> FloatingService.send(this, FloatingService.ACTION_CAMERA));
        addTile(grid, "⏹", "إغلاق النوافذ", "إيقاف كل النوافذ العائمة", 0xFF37474F, v -> FloatingService.send(this, FloatingService.ACTION_STOP));
        addTile(grid, "🧹", "تنظيف النظام", "تعطيل التطبيقات الزائدة", 0xFFEF6C00, v -> startActivity(new Intent(this, DebloatActivity.class)));

        // ---- settings ----
        col.addView(section("الأمان أثناء القيادة"), lpTop(24));
        LinearLayout safety = card();
        col.addView(safety, lpTop(8));

        Switch lock = sw("إيقاف صورة الفيديو عند الحركة", Prefs.speedLock(this));
        lock.setOnCheckedChangeListener((x, on) -> Prefs.setSpeedLock(this, on));
        safety.addView(lock);

        Switch pause = sw("إيقاف الفيديو بالكامل (بدل الصوت فقط)", Prefs.pauseWhileDriving(this));
        pause.setOnCheckedChangeListener((x, on) -> Prefs.setPauseWhileDriving(this, on));
        safety.addView(pause, lpTop(8));

        LinearLayout speedRow = row();
        TextView speedLbl = text("", 15, Color.WHITE);
        Runnable upd = () -> speedLbl.setText("السرعة التي يبدأ عندها القفل: " + Prefs.speedLimitKmh(this) + " كم/س");
        upd.run();
        speedRow.addView(speedLbl, new LinearLayout.LayoutParams(0, -2, 1));
        speedRow.addView(smallBtn("−", v -> { Prefs.setSpeedLimitKmh(this, Math.max(3, Prefs.speedLimitKmh(this) - 1)); upd.run(); }));
        speedRow.addView(smallBtn("+", v -> { Prefs.setSpeedLimitKmh(this, Math.min(40, Prefs.speedLimitKmh(this) + 1)); upd.run(); }));
        safety.addView(speedRow, lpTop(8));

        col.addView(section("الكاميرا"), lpTop(24));
        LinearLayout camCard = card();
        col.addView(camCard, lpTop(8));
        Switch mirror = sw("عكس الصورة (مثل المرآة)", Prefs.cameraMirror(this));
        mirror.setOnCheckedChangeListener((x, on) -> Prefs.setCameraMirror(this, on));
        camCard.addView(mirror);
        TextView camLbl = text("", 14, 0xFF9AA4B2);
        camCard.addView(camLbl, lpTop(8));
        LinearLayout camRow = row();
        android.widget.HorizontalScrollView camScroll = new android.widget.HorizontalScrollView(this);
        camScroll.addView(camRow);
        camCard.addView(camScroll, lpTop(8));
        fillCameraChoices(camRow, camLbl);

        col.addView(section("تطبيق الخرائط"), lpTop(24));
        LinearLayout mapsCard = card();
        col.addView(mapsCard, lpTop(8));
        LinearLayout mapsRow = row();
        mapsCard.addView(mapsRow);
        TextView mapsLbl = text("الحالي: " + mapsName(Prefs.mapsPackage(this)), 14, 0xFF9AA4B2);
        mapsCard.addView(mapsLbl, lpTop(8));
        mapsRow.addView(smallBtn("Google Maps", v -> { Prefs.setMapsPackage(this, "com.google.android.apps.maps"); mapsLbl.setText("الحالي: Google Maps"); }));
        mapsRow.addView(smallBtn("Waze", v -> { Prefs.setMapsPackage(this, "com.waze"); mapsLbl.setText("الحالي: Waze"); }));

        col.addView(text("\nنصيحة: اسحب النافذة من شريط العنوان، وغيّر حجمها من الزاوية ◢، واضغط على العنوان لتصغيرها.", 13, 0xFF9AA4B2));

        setContentView(scroll);
    }

    private void fillCameraChoices(LinearLayout row, TextView lbl) {
        CameraManager cm = (CameraManager) getSystemService(CAMERA_SERVICE);
        try {
            String[] ids = cm.getCameraIdList();
            if (ids.length == 0) {
                lbl.setText("لم يتم العثور على كاميرا متاحة للتطبيقات على هذه الشاشة.");
                return;
            }
            String sel = Prefs.cameraId(this);
            lbl.setText("اختر الكاميرا (المختارة: " + (sel.isEmpty() ? "تلقائي" : sel) + ")");
            for (String id : ids) {
                Integer f = cm.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING);
                String face = f == null ? "" : f == CameraCharacteristics.LENS_FACING_BACK ? " خلفية"
                        : f == CameraCharacteristics.LENS_FACING_FRONT ? " أمامية" : " خارجية";
                row.addView(smallBtn("كاميرا " + id + face, v -> {
                    Prefs.setCameraId(this, id);
                    lbl.setText("اختر الكاميرا (المختارة: " + id + ")");
                }));
            }
        } catch (Exception e) {
            lbl.setText("الكاميرا: " + e.getMessage());
        }
    }

    // ------------------------------------------------------------------ actions

    private void driveMode() {
        if (!Settings.canDrawOverlays(this)) { askOverlay(); return; }
        FloatingService.send(this, FloatingService.ACTION_DRIVE);
        openMaps();
    }

    private void openMaps() {
        String pkg = Prefs.mapsPackage(this);
        Intent i = getPackageManager().getLaunchIntentForPackage(pkg);
        if (i == null) i = getPackageManager().getLaunchIntentForPackage("com.google.android.apps.maps");
        if (i == null) i = new Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q="));
        try { startActivity(i); }
        catch (Exception e) { Toast.makeText(this, "لا يوجد تطبيق خرائط مثبت", Toast.LENGTH_LONG).show(); }
    }

    private static String mapsName(String pkg) { return pkg.equals("com.waze") ? "Waze" : "Google Maps"; }

    // ------------------------------------------------------------------ permissions

    private void requestRuntimePermissions() {
        List<String> need = new ArrayList<>();
        need.add(Manifest.permission.CAMERA);
        need.add(Manifest.permission.ACCESS_FINE_LOCATION);
        if (Build.VERSION.SDK_INT >= 33) need.add(Manifest.permission.POST_NOTIFICATIONS);
        List<String> missing = new ArrayList<>();
        for (String p : need) if (checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED) missing.add(p);
        if (!missing.isEmpty()) requestPermissions(missing.toArray(new String[0]), 1);
    }

    @Override public void onRequestPermissionsResult(int code, String[] perms, int[] res) {
        refreshPermissionCard();
    }

    private void askOverlay() {
        Toast.makeText(this, "اسمح لـ «لوحة السيارة» بالظهور فوق التطبيقات", Toast.LENGTH_LONG).show();
        startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName())));
    }

    private void refreshPermissionCard() {
        permCard.removeAllViews();
        boolean overlay = Settings.canDrawOverlays(this);
        boolean cam = checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
        boolean loc = SpeedMonitor.hasPermission(this);
        if (overlay && cam && loc) { permCard.setVisibility(View.GONE); return; }
        permCard.setVisibility(View.VISIBLE);
        permCard.addView(text("⚠️ أذونات مطلوبة", 17, 0xFFFFCA28));
        if (!overlay) permCard.addView(wideBtn("السماح بالظهور فوق التطبيقات (للنوافذ العائمة)", v -> askOverlay()), lpTop(8));
        if (!cam || !loc) permCard.addView(wideBtn("السماح بالكاميرا والموقع (للمرآة وقفل السرعة)", v -> {
            requestRuntimePermissions();
            if (!shouldShowRequestPermissionRationale(Manifest.permission.CAMERA) && !cam)
                startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + getPackageName())));
        }), lpTop(8));
    }

    // ------------------------------------------------------------------ view helpers

    private void addTile(GridLayout grid, String icon, String title, String sub, int color, View.OnClickListener l) {
        LinearLayout t = new LinearLayout(this);
        t.setOrientation(LinearLayout.VERTICAL);
        t.setGravity(Gravity.CENTER);
        t.setPadding(dp(12), dp(18), dp(12), dp(18));
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(color);
        bg.setCornerRadius(dp(18));
        t.setBackground(bg);
        t.setClickable(true);
        t.setForeground(getDrawable(android.R.drawable.list_selector_background));
        t.setOnClickListener(l);
        t.addView(text(icon, 34, Color.WHITE));
        TextView tt = text(title, 18, Color.WHITE);
        tt.setTypeface(Typeface.DEFAULT_BOLD);
        t.addView(tt);
        t.addView(text(sub, 12, 0xDDFFFFFF));
        for (int i = 0; i < t.getChildCount(); i++) ((TextView) t.getChildAt(i)).setGravity(Gravity.CENTER);

        GridLayout.LayoutParams p = new GridLayout.LayoutParams(
                GridLayout.spec(GridLayout.UNDEFINED, 1f), GridLayout.spec(GridLayout.UNDEFINED, 1f));
        p.width = 0;
        p.setMargins(dp(6), dp(6), dp(6), dp(6));
        grid.addView(t, p);
    }

    /**
     * Tile that launches another installed app, showing that app's own icon and name
     * (read from the system at runtime, like any launcher). If it is not installed, explains how.
     */
    private void addAppTile(GridLayout grid, String pkg, String fallbackName, int color) {
        android.content.pm.PackageManager pm = getPackageManager();
        Intent launch = pm.getLaunchIntentForPackage(pkg);
        if (launch == null) launch = pm.getLeanbackLaunchIntentForPackage(pkg);
        final Intent target = launch;
        if (target == null) {
            addTile(grid, "📺", fallbackName, "غير مثبت — اضغط للتعليمات", color, v ->
                    Toast.makeText(this, "انسخ ملف " + fallbackName + " (APK) للشاشة وثبّته من مدير الملفات، ثم ارجع هنا.",
                            Toast.LENGTH_LONG).show());
            return;
        }
        String name = fallbackName;
        android.graphics.drawable.Drawable icon = null;
        try {
            android.content.pm.ApplicationInfo ai = pm.getApplicationInfo(pkg, 0);
            name = String.valueOf(pm.getApplicationLabel(ai));
            icon = pm.getApplicationIcon(ai);
        } catch (Exception ignored) {}
        addTile(grid, "📺", name, "فتح التطبيق", color, v -> {
            target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(target);
        });
        if (icon != null) {
            // Replace the emoji with the app's real icon.
            LinearLayout tile = (LinearLayout) grid.getChildAt(grid.getChildCount() - 1);
            android.widget.ImageView iv = new android.widget.ImageView(this);
            iv.setImageDrawable(icon);
            tile.removeViewAt(0);
            tile.addView(iv, 0, new LinearLayout.LayoutParams(dp(48), dp(48)));
        }
    }

    private TextView text(String s, float sp, int color) {
        TextView t = new TextView(this);
        t.setText(s);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp);
        t.setTextColor(color);
        return t;
    }

    private TextView section(String s) {
        TextView t = text(s, 18, 0xFF29B6F6);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        return t;
    }

    private LinearLayout card() {
        LinearLayout c = new LinearLayout(this);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setPadding(dp(16), dp(14), dp(16), dp(14));
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(0xFF1A1F27);
        bg.setCornerRadius(dp(14));
        c.setBackground(bg);
        return c;
    }

    private LinearLayout row() {
        LinearLayout r = new LinearLayout(this);
        r.setOrientation(LinearLayout.HORIZONTAL);
        r.setGravity(Gravity.CENTER_VERTICAL);
        return r;
    }

    private Switch sw(String label, boolean checked) {
        Switch s = new Switch(this);
        s.setText(label);
        s.setTextColor(Color.WHITE);
        s.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        s.setChecked(checked);
        return s;
    }

    private Button smallBtn(String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setAllCaps(false);
        b.setOnClickListener(l);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-2, -2);
        p.setMarginStart(dp(6));
        b.setLayoutParams(p);
        return b;
    }

    private Button wideBtn(String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setAllCaps(false);
        b.setOnClickListener(l);
        return b;
    }

    private LinearLayout.LayoutParams lpTop(int topDp) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.topMargin = dp(topDp);
        return p;
    }

    private int dp(float v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, getResources().getDisplayMetrics());
    }
}
