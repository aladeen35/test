package com.aladeen.cardash;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.Looper;

/** Watches GPS speed and reports when the car starts/stops moving. */
public class SpeedMonitor implements LocationListener {
    public interface Listener { void onDrivingChanged(boolean driving, float kmh); }

    private final Context ctx;
    private final Listener listener;
    private LocationManager lm;
    private boolean driving = false;
    private long belowSince = 0;

    public SpeedMonitor(Context ctx, Listener l) { this.ctx = ctx; this.listener = l; }

    public static boolean hasPermission(Context c) {
        return c.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    @SuppressLint("MissingPermission")
    public void start() {
        if (!hasPermission(ctx)) return;
        lm = (LocationManager) ctx.getSystemService(Context.LOCATION_SERVICE);
        try {
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER))
                lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000, 0, this, Looper.getMainLooper());
        } catch (Exception ignored) {}
    }

    public void stop() {
        if (lm != null) try { lm.removeUpdates(this); } catch (Exception ignored) {}
        lm = null;
    }

    public boolean isDriving() { return driving; }

    @Override public void onLocationChanged(Location loc) {
        if (!loc.hasSpeed()) return;
        float kmh = loc.getSpeed() * 3.6f;
        int limit = Prefs.speedLimitKmh(ctx);
        long now = System.currentTimeMillis();
        if (!driving && kmh >= limit) {
            driving = true;
            belowSince = 0;
            listener.onDrivingChanged(true, kmh);
        } else if (driving) {
            // Hysteresis: must stay slow for 3 seconds before unlocking.
            if (kmh < Math.max(1, limit - 3)) {
                if (belowSince == 0) belowSince = now;
                else if (now - belowSince > 3000) {
                    driving = false;
                    listener.onDrivingChanged(false, kmh);
                }
            } else belowSince = 0;
        }
    }

    @Override public void onStatusChanged(String p, int s, Bundle b) {}
    @Override public void onProviderEnabled(String p) {}
    @Override public void onProviderDisabled(String p) {}
}
