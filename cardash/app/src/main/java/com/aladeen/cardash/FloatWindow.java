package com.aladeen.cardash;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.drawable.GradientDrawable;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * A draggable, resizable window that floats above every app (maps, Android Auto, launcher).
 * Subclasses put their content inside {@link #content}.
 */
public abstract class FloatWindow {
    public interface OnClosed { void onClosed(FloatWindow w); }

    protected final Context ctx;
    protected final WindowManager wm;
    protected final WindowManager.LayoutParams lp;
    protected final FrameLayout root;
    protected final LinearLayout bar;
    protected final LinearLayout actions;
    protected final FrameLayout content;
    private final String key;
    private final SharedPreferences prefs;
    private OnClosed onClosed;
    private boolean attached = false;
    private boolean minimized = false;
    private boolean maximized = false;
    private int restoreX, restoreY, restoreW, restoreH;

    protected FloatWindow(Context ctx, String key, String title,
                          float defXFrac, float defYFrac, float defWFrac, float defHFrac) {
        this.ctx = ctx;
        this.key = key;
        this.wm = (WindowManager) ctx.getSystemService(Context.WINDOW_SERVICE);
        this.prefs = Prefs.get(ctx);

        DisplayMetrics dm = ctx.getResources().getDisplayMetrics();
        int sw = dm.widthPixels, sh = dm.heightPixels;

        lp = new WindowManager.LayoutParams(
                prefs.getInt(key + "_w", (int) (sw * defWFrac)),
                prefs.getInt(key + "_h", (int) (sh * defHFrac)),
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT);
        lp.gravity = Gravity.TOP | Gravity.LEFT;
        lp.x = prefs.getInt(key + "_x", (int) (sw * defXFrac));
        lp.y = prefs.getInt(key + "_y", (int) (sh * defYFrac));
        clampToScreen();

        root = new FrameLayout(ctx);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.BLACK);
        bg.setCornerRadius(dp(12));
        bg.setStroke(dp(2), 0xFF1E88E5);
        root.setBackground(bg);
        root.setClipToOutline(true);
        root.setElevation(dp(8));

        LinearLayout column = new LinearLayout(ctx);
        column.setOrientation(LinearLayout.VERTICAL);
        root.addView(column, new FrameLayout.LayoutParams(-1, -1));

        // ---- Title bar (drag handle) ----
        bar = new LinearLayout(ctx);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setBackgroundColor(0xEE1A1F27);
        bar.setLayoutDirection(View.LAYOUT_DIRECTION_LTR);
        bar.setPadding(dp(8), 0, dp(4), 0);
        column.addView(bar, new LinearLayout.LayoutParams(-1, dp(40)));

        TextView tv = new TextView(ctx);
        tv.setText(title);
        tv.setTextColor(Color.WHITE);
        tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        tv.setSingleLine(true);
        bar.addView(tv, new LinearLayout.LayoutParams(0, -2, 1));

        actions = new LinearLayout(ctx);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        bar.addView(actions, new LinearLayout.LayoutParams(-2, -1));

        addButton("⤢", v -> toggleMaximize());
        addButton("–", v -> toggleMinimize());
        addButton("✕", v -> close());

        content = new FrameLayout(ctx);
        content.setBackgroundColor(Color.BLACK);
        column.addView(content, new LinearLayout.LayoutParams(-1, 0, 1));

        // ---- Resize grip (bottom-right) ----
        TextView grip = new TextView(ctx);
        grip.setText("◢");
        grip.setTextColor(0xCC29B6F6);
        grip.setTextSize(TypedValue.COMPLEX_UNIT_SP, 22);
        grip.setGravity(Gravity.BOTTOM | Gravity.RIGHT);
        FrameLayout.LayoutParams gp = new FrameLayout.LayoutParams(dp(44), dp(44), Gravity.BOTTOM | Gravity.RIGHT);
        root.addView(grip, gp);

        bar.setOnTouchListener(new DragListener());
        grip.setOnTouchListener(new ResizeListener());
    }

    // ------------------------------------------------------------------ public API

    public void setOnClosed(OnClosed l) { onClosed = l; }

    public void show() {
        if (attached) return;
        wm.addView(root, lp);
        attached = true;
        onShown();
    }

    public void close() {
        if (!attached) return;
        onClosing();
        try { wm.removeView(root); } catch (Exception ignored) {}
        attached = false;
        if (onClosed != null) onClosed.onClosed(this);
    }

    public boolean isShowing() { return attached; }

    /** Allow the keyboard (needed for typing a YouTube search). */
    public void setFocusable(boolean focusable) {
        if (focusable) lp.flags &= ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
        else lp.flags |= WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
        update();
    }

    public boolean isFocusable() { return (lp.flags & WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE) == 0; }

    // ------------------------------------------------------------------ hooks

    protected void onShown() {}
    protected void onClosing() {}
    protected void onResized() {}

    // ------------------------------------------------------------------ helpers

    protected TextView addButton(String label, View.OnClickListener l) {
        TextView b = new TextView(ctx);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18);
        b.setGravity(Gravity.CENTER);
        b.setOnClickListener(l);
        b.setBackgroundResource(android.R.drawable.list_selector_background);
        actions.addView(b, 0, new LinearLayout.LayoutParams(dp(42), -1));
        return b;
    }

    protected int dp(float v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, ctx.getResources().getDisplayMetrics());
    }

    private void update() {
        if (attached) try { wm.updateViewLayout(root, lp); } catch (Exception ignored) {}
    }

    private void save() {
        if (minimized || maximized) {
            prefs.edit().putInt(key + "_x", lp.x).putInt(key + "_y", lp.y).apply();
            return;
        }
        prefs.edit().putInt(key + "_x", lp.x).putInt(key + "_y", lp.y)
                .putInt(key + "_w", lp.width).putInt(key + "_h", lp.height).apply();
    }

    private void clampToScreen() {
        DisplayMetrics dm = ctx.getResources().getDisplayMetrics();
        int w = lp.width > 0 ? lp.width : dp(200);
        lp.x = Math.max(-w + dp(80), Math.min(lp.x, dm.widthPixels - dp(80)));
        lp.y = Math.max(0, Math.min(lp.y, dm.heightPixels - dp(40)));
    }

    private void toggleMinimize() {
        // Content is shrunk (not hidden) so video/audio keeps playing in the background.
        if (!minimized) {
            if (maximized) toggleMaximize();
            restoreH = lp.height;
            lp.height = dp(41);
            minimized = true;
        } else {
            lp.height = restoreH;
            minimized = false;
        }
        update();
        onResized();
    }

    private void toggleMaximize() {
        DisplayMetrics dm = ctx.getResources().getDisplayMetrics();
        if (minimized) toggleMinimize();
        if (!maximized) {
            restoreX = lp.x; restoreY = lp.y; restoreW = lp.width; restoreH = lp.height;
            lp.x = dp(8); lp.y = dp(8);
            lp.width = dm.widthPixels - dp(16);
            lp.height = dm.heightPixels - dp(16);
            maximized = true;
        } else {
            lp.x = restoreX; lp.y = restoreY; lp.width = restoreW; lp.height = restoreH;
            maximized = false;
        }
        update();
        onResized();
    }

    private class DragListener implements View.OnTouchListener {
        float downX, downY; int startX, startY; boolean moved;

        @SuppressLint("ClickableViewAccessibility")
        @Override public boolean onTouch(View v, MotionEvent e) {
            switch (e.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    downX = e.getRawX(); downY = e.getRawY();
                    startX = lp.x; startY = lp.y; moved = false;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    float dx = e.getRawX() - downX, dy = e.getRawY() - downY;
                    if (Math.abs(dx) + Math.abs(dy) > dp(4)) moved = true;
                    lp.x = startX + (int) dx;
                    lp.y = startY + (int) dy;
                    clampToScreen();
                    update();
                    return true;
                case MotionEvent.ACTION_UP:
                    if (!moved) toggleMinimize(); // tap on title = minimize/restore
                    save();
                    return true;
            }
            return false;
        }
    }

    private class ResizeListener implements View.OnTouchListener {
        float downX, downY; int startW, startH;

        @SuppressLint("ClickableViewAccessibility")
        @Override public boolean onTouch(View v, MotionEvent e) {
            switch (e.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    if (minimized) toggleMinimize();
                    maximized = false;
                    downX = e.getRawX(); downY = e.getRawY();
                    startW = lp.width; startH = lp.height;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    lp.width = Math.max(dp(220), startW + (int) (e.getRawX() - downX));
                    lp.height = Math.max(dp(150), startH + (int) (e.getRawY() - downY));
                    update();
                    onResized();
                    return true;
                case MotionEvent.ACTION_UP:
                    save();
                    return true;
            }
            return false;
        }
    }

    protected static ViewGroup.LayoutParams match() { return new FrameLayout.LayoutParams(-1, -1); }
}
