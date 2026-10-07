# Tesseract (استخراج النص): الكود الأصلي يصل لهذه الأصناف وحقولها بالاسم عبر JNI
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }
# تنبيهات flutter_local_notifications (تُقرأ بالاسم عند إعادة تشغيل الجهاز)
-keep class com.dexterous.** { *; }
# ودجات الشاشة الرئيسية (تُستدعى بالاسم من المشغّل عبر المانيفست والمنبّهات)
-keep class com.albushra.amir_tools.widgets.** { *; }
-keep class es.antonborri.home_widget.** { *; }
