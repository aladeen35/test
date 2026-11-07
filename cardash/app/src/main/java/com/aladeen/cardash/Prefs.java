package com.aladeen.cardash;

import android.content.Context;
import android.content.SharedPreferences;

/** Central place for all user settings. */
public final class Prefs {
    private Prefs() {}

    public static SharedPreferences get(Context c) {
        return c.getSharedPreferences("cardash", Context.MODE_PRIVATE);
    }

    public static String cameraId(Context c) { return get(c).getString("cam_id", ""); }
    public static void setCameraId(Context c, String id) { get(c).edit().putString("cam_id", id).apply(); }

    public static boolean cameraMirror(Context c) { return get(c).getBoolean("cam_mirror", true); }
    public static void setCameraMirror(Context c, boolean v) { get(c).edit().putBoolean("cam_mirror", v).apply(); }

    public static int cameraRotation(Context c) { return get(c).getInt("cam_rot", 0); }
    public static void setCameraRotation(Context c, int v) { get(c).edit().putInt("cam_rot", v).apply(); }

    public static boolean speedLock(Context c) { return get(c).getBoolean("speed_lock", true); }
    public static void setSpeedLock(Context c, boolean v) { get(c).edit().putBoolean("speed_lock", v).apply(); }

    public static int speedLimitKmh(Context c) { return get(c).getInt("speed_kmh", 8); }
    public static void setSpeedLimitKmh(Context c, int v) { get(c).edit().putInt("speed_kmh", v).apply(); }

    /** true = pause video while driving, false = hide picture but keep audio. */
    public static boolean pauseWhileDriving(Context c) { return get(c).getBoolean("lock_pause", false); }
    public static void setPauseWhileDriving(Context c, boolean v) { get(c).edit().putBoolean("lock_pause", v).apply(); }

    public static String mapsPackage(Context c) { return get(c).getString("maps_pkg", "com.google.android.apps.maps"); }
    public static void setMapsPackage(Context c, String p) { get(c).edit().putString("maps_pkg", p).apply(); }
}
