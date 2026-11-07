#!/usr/bin/env bash
# تنظيف شاشة السيارة عبر ADB (لاسلكي أو USB). لا يحذف شيئاً نهائياً: يعطّل فقط.
# الاستخدام:  ./debloat.sh 192.168.1.50:5555        (أو بدون عنوان إذا كانت متصلة بـ USB)
# للتراجع عن أي تطبيق:  adb shell pm enable <package>
set -e
[ -n "$1" ] && adb connect "$1"

PKGS="
com.android.email com.android.calendar com.android.deskclock com.android.gallery3d com.android.music
com.android.soundrecorder com.android.printspooler com.android.bips com.android.egg com.android.dreams.basic
com.android.dreams.phototable com.android.wallpaper.livepicker com.android.stk com.android.bookmarkprovider
com.android.quicksearchbox com.android.calllogbackup com.android.wallpaperbackup com.android.traceur
com.google.android.videos com.google.android.apps.photos com.google.android.apps.docs
com.google.android.apps.tachyon com.google.android.feedback com.google.android.apps.wellbeing
com.facebook.appmanager com.facebook.services com.facebook.system
"

echo "== نسخة احتياطية لقائمة التطبيقات: packages_before.txt"
adb shell pm list packages -e > packages_before.txt

for p in $PKGS; do
  if grep -q "package:$p\$" packages_before.txt; then
    echo "تعطيل $p"
    adb shell pm disable-user --user 0 "$p" >/dev/null || true
  fi
done

echo "== تسريع الحركة (0.5x)"
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

echo "== تحسين أداء التطبيقات (قد يستغرق عدة دقائق)"
adb shell cmd package bg-dexopt-job || true

echo "تم. أعد تشغيل الشاشة."
