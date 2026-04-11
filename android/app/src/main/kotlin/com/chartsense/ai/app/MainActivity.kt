package com.chartsense.ai.app

import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterFragmentActivity() {

    private val channelName = "com.chartsense.ai.app/media_store"
    private var deleteResult: MethodChannel.Result? = null

    private val deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest> =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            val res = deleteResult
            deleteResult = null
            if (result.resultCode == RESULT_OK) {
                res?.success(true)
            } else {
                res?.success(false)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteVideo" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Content URI is required", null)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val uri = Uri.parse(uriString)
                            val pendingIntent = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                            deleteResult = result
                            deleteRequestLauncher.launch(
                                IntentSenderRequest.Builder(pendingIntent.intentSender).build()
                            )
                        } catch (e: Exception) {
                            deleteResult = null
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "mediumNativeAd",
            MediumNativeAdFactory(this)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "mediumNativeAd")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
