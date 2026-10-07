package com.albushra.amir_tools

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // قناة استخراج النص (OCR) عبر Tesseract4Android — تعمل على الجهاز بالكامل
    private val ocrExecutor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    // روابط ameertools:// من خارج الودجت (متصفح، رسالة…) تُعامل كضغطة ودجت حتى تصل لفلاتر بنفس الطريق
    override fun onCreate(savedInstanceState: Bundle?) {
        adoptDeepLink(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        adoptDeepLink(intent)
        super.onNewIntent(intent)
    }

    private fun adoptDeepLink(i: Intent?) {
        if (i != null && i.action == Intent.ACTION_VIEW && i.data?.scheme == "ameertools") {
            i.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ameer/ocr").setMethodCallHandler { call, result ->
            if (call.method != "extractText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val imagePath = call.argument<String>("imagePath")
            val dataPath = call.argument<String>("dataPath")
            val lang = call.argument<String>("lang") ?: "ara+eng"
            if (imagePath == null || dataPath == null) {
                result.error("args", "missing imagePath/dataPath", null)
                return@setMethodCallHandler
            }
            ocrExecutor.execute {
                val tess = TessBaseAPI()
                try {
                    if (!tess.init(dataPath, lang)) {
                        main.post { result.error("init", "Tesseract init failed for $lang", null) }
                        return@execute
                    }
                    tess.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
                    tess.setVariable("preserve_interword_spaces", "1")
                    tess.setImage(File(imagePath))
                    val text = tess.getUTF8Text() ?: ""
                    main.post { result.success(text) }
                } catch (e: Throwable) {
                    main.post { result.error("ocr", e.message, null) }
                } finally {
                    tess.recycle()
                }
            }
        }
    }
}
