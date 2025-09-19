package com.ravan.Maya


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL = "maya.ravan.ai/deeplink"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val initialLink = getInitialLink()
                    result.success(initialLink)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInitialLink(): String? {
        val intent = intent
        val data: Uri? = intent?.data
        return data?.toString()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        val data: Uri? = intent.data
        if (data != null) {
            // Handle the deep link
            val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            channel.invokeMethod("onDeepLink", data.toString())
        }
    }
}
