package com.sanzoghenzo.markdownr

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import net.dankito.readability4j.extended.Readability4JExtended

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sanzoghenzo/readability"
        ).setMethodCallHandler { call, result ->
            if (call.method == "makeReadable") {
                val html: String? = call.argument<String>("html")
                val url: String? = call.argument<String>("url")
                val readableHtml = makeReadable(html, url)
                result.success(readableHtml)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun makeReadable(html: String?, url: String?): String {
        if (html == null || url == null) {
            return ""
        }
        val readabilityService = Readability4JExtended(url, html)
        val article = readabilityService.parse()
        if (article.content != null) return article.content!!
        return ""
    }
}