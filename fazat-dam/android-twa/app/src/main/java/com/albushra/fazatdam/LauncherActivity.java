package com.albushra.fazatdam;

import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;

/** Opens the FAZAT DAM web app full screen in a Trusted Web Activity. */
public class LauncherActivity extends com.google.androidbrowserhelper.trusted.LauncherActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Setting an orientation crashes Android 8.0 with a translucent theme (Bubblewrap #496).
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        }
    }
}
