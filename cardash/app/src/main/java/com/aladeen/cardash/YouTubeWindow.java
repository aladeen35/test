package com.aladeen.cardash;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.TextView;

/** Floating YouTube player (mobile YouTube site inside a WebView). */
public class YouTubeWindow extends FloatWindow {
    private static final String HOME = "https://m.youtube.com/";

    private final WebView web;
    private final TextView driveCover;
    private final TextView keyboardBtn;
    private View customView;
    private WebChromeClient.CustomViewCallback customCallback;

    @SuppressLint("SetJavaScriptEnabled")
    public YouTubeWindow(Context ctx) {
        super(ctx, "yt", "▶  يوتيوب", 0.02f, 0.45f, 0.42f, 0.50f);

        web = new WebView(ctx);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        // Look like normal Chrome so YouTube does not push "open in app".
        s.setUserAgentString(s.getUserAgentString().replace("; wv", ""));
        CookieManager.getInstance().setAcceptCookie(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, true);

        web.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                String scheme = r.getUrl().getScheme();
                // Block intent:// / vnd.youtube:// redirects that try to leave the window.
                return scheme == null || !(scheme.equals("http") || scheme.equals("https"));
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override public void onShowCustomView(View view, CustomViewCallback cb) {
                // YouTube "full screen" button -> fill the floating window.
                customView = view;
                customCallback = cb;
                content.addView(view, 1, match());
                web.setVisibility(View.INVISIBLE);
            }

            @Override public void onHideCustomView() { exitCustomView(); }
        });
        content.addView(web, match());

        driveCover = new TextView(ctx);
        driveCover.setText("🚗\nالصورة متوقفة أثناء القيادة\nالصوت مستمر — تعود الصورة عند التوقف");
        driveCover.setTextColor(Color.WHITE);
        driveCover.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16);
        driveCover.setGravity(Gravity.CENTER);
        driveCover.setBackgroundColor(0xF2000000);
        driveCover.setVisibility(View.GONE);
        driveCover.setClickable(true); // swallow touches while locked
        content.addView(driveCover, new FrameLayout.LayoutParams(-1, -1));

        addButton("⌂", v -> web.loadUrl(HOME));
        addButton("↶", v -> { if (web.canGoBack()) web.goBack(); });
        keyboardBtn = addButton("⌨", v -> toggleKeyboard());

        web.loadUrl(HOME);
    }

    private void toggleKeyboard() {
        boolean on = !isFocusable();
        setFocusable(on);
        keyboardBtn.setTextColor(on ? 0xFF29B6F6 : Color.WHITE);
        if (on) web.requestFocus();
    }

    private void exitCustomView() {
        if (customView != null) {
            content.removeView(customView);
            customView = null;
            if (customCallback != null) customCallback.onCustomViewHidden();
            customCallback = null;
        }
        web.setVisibility(View.VISIBLE);
    }

    /** Called by the service when GPS speed crosses the limit. */
    public void setDriving(boolean driving) {
        if (driving) {
            if (Prefs.pauseWhileDriving(ctx)) {
                web.evaluateJavascript("document.querySelectorAll('video').forEach(function(v){v.pause()})", null);
                driveCover.setText("🚗\nتم إيقاف الفيديو أثناء القيادة");
            } else {
                driveCover.setText("🚗\nالصورة متوقفة أثناء القيادة\nالصوت مستمر — تعود الصورة عند التوقف");
            }
            if (isFocusable()) toggleKeyboard();
            driveCover.setVisibility(View.VISIBLE);
        } else {
            driveCover.setVisibility(View.GONE);
        }
    }

    @Override protected void onClosing() {
        exitCustomView();
        web.loadUrl("about:blank");
        web.destroy();
    }
}
