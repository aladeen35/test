package com.aladeen.cardash;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;
import android.provider.Settings;
import android.widget.Toast;

/** Keeps the floating windows alive above maps / Android Auto / any app. */
public class FloatingService extends Service implements SpeedMonitor.Listener {
    public static final String ACTION_YOUTUBE = "yt";
    public static final String ACTION_CAMERA = "cam";
    public static final String ACTION_DRIVE = "drive";
    public static final String ACTION_STOP = "stop";

    private static final String CHANNEL = "floating";
    private YouTubeWindow youtube;
    private CameraWindow camera;
    private SpeedMonitor speed;

    public static void send(Context c, String action) {
        Intent i = new Intent(c, FloatingService.class).setAction(action);
        c.startForegroundService(i);
    }

    @Override public IBinder onBind(Intent i) { return null; }

    @Override public void onCreate() {
        super.onCreate();
        NotificationManager nm = getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel(CHANNEL, "النوافذ العائمة", NotificationManager.IMPORTANCE_LOW));
        startInForeground();
        speed = new SpeedMonitor(this, this);
        speed.start();
    }

    private void startInForeground() {
        PendingIntent open = PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class),
                PendingIntent.FLAG_IMMUTABLE);
        PendingIntent stop = PendingIntent.getService(this, 1,
                new Intent(this, FloatingService.class).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE);
        Notification n = new Notification.Builder(this, CHANNEL)
                .setSmallIcon(android.R.drawable.ic_menu_view)
                .setContentTitle("لوحة السيارة تعمل")
                .setContentText("اليوتيوب والكاميرا العائمة")
                .setContentIntent(open)
                .addAction(new Notification.Action.Builder(null, "إغلاق الكل", stop).build())
                .setOngoing(true)
                .build();

        int types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK;
        if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED)
            types |= ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA;
        if (SpeedMonitor.hasPermission(this))
            types |= ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION;
        try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, types);
            else startForeground(1, n);
        } catch (Exception e) {
            // Fallback: start with media type only (e.g. camera type refused by system).
            if (Build.VERSION.SDK_INT >= 29)
                startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
        }
    }

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        if (action == null) return START_NOT_STICKY;

        if (ACTION_STOP.equals(action)) { closeAll(); return START_NOT_STICKY; }

        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "فعّل إذن «الظهور فوق التطبيقات» أولاً", Toast.LENGTH_LONG).show();
            stopIfEmpty();
            return START_NOT_STICKY;
        }

        switch (action) {
            case ACTION_YOUTUBE: toggleYouTube(); break;
            case ACTION_CAMERA: toggleCamera(); break;
            case ACTION_DRIVE:
                if (camera == null) toggleCamera();
                if (youtube == null) toggleYouTube();
                break;
        }
        stopIfEmpty();
        return START_NOT_STICKY;
    }

    private void toggleYouTube() {
        if (youtube != null) { youtube.close(); return; }
        youtube = new YouTubeWindow(this);
        youtube.setOnClosed(w -> { youtube = null; stopIfEmpty(); });
        youtube.show();
        if (Prefs.speedLock(this) && speed.isDriving()) youtube.setDriving(true);
    }

    private void toggleCamera() {
        if (camera != null) { camera.close(); return; }
        camera = new CameraWindow(this);
        camera.setOnClosed(w -> { camera = null; stopIfEmpty(); });
        camera.show();
    }

    private void closeAll() {
        if (youtube != null) youtube.close();
        if (camera != null) camera.close();
        stopIfEmpty();
    }

    private void stopIfEmpty() {
        if (youtube == null && camera == null) stopSelf();
    }

    @Override public void onDrivingChanged(boolean driving, float kmh) {
        if (youtube != null && Prefs.speedLock(this)) youtube.setDriving(driving);
    }

    @Override public void onDestroy() {
        speed.stop();
        if (youtube != null) youtube.close();
        if (camera != null) camera.close();
        super.onDestroy();
    }
}
