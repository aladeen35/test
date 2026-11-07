package com.aladeen.cardash;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Size;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.util.Collections;

/** Floating rear-camera "mirror" using the head unit's camera through Camera2. */
public class CameraWindow extends FloatWindow implements TextureView.SurfaceTextureListener {
    private final CameraManager cm;
    private final TextureView texture;
    private final TextView status;
    private final Handler main = new Handler(Looper.getMainLooper());
    private HandlerThread thread;
    private Handler bg;
    private CameraDevice device;
    private CameraCaptureSession session;
    private Size previewSize;
    private String currentId;
    private boolean closing = false;

    private final Runnable retry = this::openCamera;

    public CameraWindow(Context ctx) {
        super(ctx, "cam", "◉  الكاميرا الخلفية", 0.62f, 0.03f, 0.36f, 0.36f);
        cm = (CameraManager) ctx.getSystemService(Context.CAMERA_SERVICE);

        texture = new TextureView(ctx);
        texture.setSurfaceTextureListener(this);
        content.addView(texture, match());

        status = new TextView(ctx);
        status.setTextColor(Color.WHITE);
        status.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        status.setGravity(Gravity.CENTER);
        status.setPadding(dp(12), dp(12), dp(12), dp(12));
        status.setText("جاري تشغيل الكاميرا…");
        content.addView(status, new FrameLayout.LayoutParams(-1, -1));

        addButton("⇄", v -> { Prefs.setCameraMirror(ctx, !Prefs.cameraMirror(ctx)); applyTransform(); });
        addButton("⟳", v -> { Prefs.setCameraRotation(ctx, (Prefs.cameraRotation(ctx) + 90) % 360); applyTransform(); });
        addButton("⇆", v -> nextCamera());
    }

    @Override protected void onShown() {
        thread = new HandlerThread("cam");
        thread.start();
        bg = new Handler(thread.getLooper());
        if (texture.isAvailable()) openCamera();
    }

    @Override protected void onClosing() {
        closing = true;
        main.removeCallbacks(retry);
        closeCamera();
        if (thread != null) thread.quitSafely();
    }

    @Override protected void onResized() { applyTransform(); }

    // ------------------------------------------------------------------ camera

    private String pickCameraId() throws CameraAccessException {
        String[] ids = cm.getCameraIdList();
        if (ids.length == 0) return null;
        String saved = Prefs.cameraId(ctx);
        for (String id : ids) if (id.equals(saved)) return id;
        // Prefer a back-facing / external camera (rear-view cameras usually report as one of these).
        for (String id : ids) {
            Integer f = cm.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING);
            if (f != null && (f == CameraCharacteristics.LENS_FACING_BACK || f == CameraCharacteristics.LENS_FACING_EXTERNAL))
                return id;
        }
        return ids[0];
    }

    private void nextCamera() {
        try {
            String[] ids = cm.getCameraIdList();
            if (ids.length == 0) return;
            int idx = 0;
            for (int i = 0; i < ids.length; i++) if (ids[i].equals(currentId)) idx = (i + 1) % ids.length;
            Prefs.setCameraId(ctx, ids[idx]);
            closeCamera();
            openCamera();
        } catch (Exception e) { showStatus("خطأ: " + e.getMessage()); }
    }

    @SuppressLint("MissingPermission")
    private void openCamera() {
        if (closing || !texture.isAvailable()) return;
        if (ctx.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            showStatus("لا يوجد إذن للكاميرا.\nافتح تطبيق «لوحة السيارة» واسمح بالكاميرا.");
            return;
        }
        try {
            currentId = pickCameraId();
            if (currentId == null) {
                showStatus("الشاشة لا تعرض أي كاميرا للتطبيقات.\nجرّب تشغيل الكاميرا من تطبيق الشاشة الأصلي مرة ثم أعد المحاولة.");
                scheduleRetry(5000);
                return;
            }
            StreamConfigurationMap map = cm.getCameraCharacteristics(currentId)
                    .get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            previewSize = choosePreviewSize(map);
            showStatus("جاري تشغيل الكاميرا " + currentId + "…");
            cm.openCamera(currentId, new CameraDevice.StateCallback() {
                @Override public void onOpened(CameraDevice d) { device = d; startPreview(); }
                @Override public void onDisconnected(CameraDevice d) {
                    d.close(); device = null;
                    showStatus("الكاميرا مستخدمة من النظام (ربما وضع الرجوع R)…\nسيتم إعادة الاتصال تلقائياً");
                    scheduleRetry(2500);
                }
                @Override public void onError(CameraDevice d, int error) {
                    d.close(); device = null;
                    showStatus("تعذر فتح الكاميرا (رمز " + error + ")\nإعادة المحاولة…");
                    scheduleRetry(3000);
                }
            }, bg);
        } catch (Exception e) {
            showStatus("تعذر فتح الكاميرا: " + e.getMessage());
            scheduleRetry(4000);
        }
    }

    private Size choosePreviewSize(StreamConfigurationMap map) {
        Size best = new Size(1280, 720);
        if (map == null) return best;
        Size[] sizes = map.getOutputSizes(SurfaceTexture.class);
        if (sizes == null || sizes.length == 0) return best;
        Size pick = sizes[0];
        long target = 1280L * 720L, bestDiff = Long.MAX_VALUE;
        for (Size s : sizes) {
            long diff = Math.abs((long) s.getWidth() * s.getHeight() - target);
            if (diff < bestDiff) { bestDiff = diff; pick = s; }
        }
        return pick;
    }

    private void startPreview() {
        try {
            SurfaceTexture st = texture.getSurfaceTexture();
            if (st == null || device == null) return;
            st.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
            Surface surface = new Surface(st);
            final CaptureRequest.Builder req = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            req.addTarget(surface);
            //noinspection deprecation
            device.createCaptureSession(Collections.singletonList(surface), new CameraCaptureSession.StateCallback() {
                @Override public void onConfigured(CameraCaptureSession s) {
                    if (device == null) return;
                    session = s;
                    try {
                        s.setRepeatingRequest(req.build(), null, bg);
                        main.post(() -> { status.setVisibility(View.GONE); applyTransform(); });
                    } catch (Exception e) { showStatus("خطأ في العرض: " + e.getMessage()); }
                }
                @Override public void onConfigureFailed(CameraCaptureSession s) {
                    showStatus("فشل إعداد عرض الكاميرا");
                    scheduleRetry(3000);
                }
            }, bg);
        } catch (Exception e) {
            showStatus("خطأ: " + e.getMessage());
            scheduleRetry(3000);
        }
    }

    private void closeCamera() {
        try { if (session != null) session.close(); } catch (Exception ignored) {}
        try { if (device != null) device.close(); } catch (Exception ignored) {}
        session = null;
        device = null;
    }

    private void scheduleRetry(long ms) {
        if (closing) return;
        main.removeCallbacks(retry);
        main.postDelayed(retry, ms);
    }

    private void showStatus(String msg) {
        main.post(() -> { status.setText(msg); status.setVisibility(View.VISIBLE); });
    }

    /** Fill the window (center-crop) and apply mirror + rotation. */
    private void applyTransform() {
        int vw = texture.getWidth(), vh = texture.getHeight();
        if (vw == 0 || vh == 0 || previewSize == null) return;
        float bw = previewSize.getWidth(), bh = previewSize.getHeight();
        int rot = Prefs.cameraRotation(ctx);
        boolean swap = rot == 90 || rot == 270;
        float rw = swap ? bh : bw, rh = swap ? bw : bh;
        float cx = vw / 2f, cy = vh / 2f;

        Matrix m = new Matrix();
        m.setScale(bw / vw, bh / vh, cx, cy);       // undo TextureView stretching -> native size
        m.postRotate(rot, cx, cy);                    // rotate
        float s = Math.max(vw / rw, vh / rh);         // center-crop to fill the window
        m.postScale(s, s, cx, cy);
        if (Prefs.cameraMirror(ctx)) m.postScale(-1, 1, cx, cy); // mirror like a real rear-view mirror
        texture.setTransform(m);
    }

    // ------------------------------------------------------------------ SurfaceTextureListener

    @Override public void onSurfaceTextureAvailable(SurfaceTexture s, int w, int h) { if (bg != null) openCamera(); }
    @Override public void onSurfaceTextureSizeChanged(SurfaceTexture s, int w, int h) { applyTransform(); }
    @Override public boolean onSurfaceTextureDestroyed(SurfaceTexture s) { closeCamera(); return true; }
    @Override public void onSurfaceTextureUpdated(SurfaceTexture s) {}
}
