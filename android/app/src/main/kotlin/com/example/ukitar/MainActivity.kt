package com.example.ukitar

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.Display
import android.view.Window
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ukitar.external_launcher"

    override fun onResume() {
        super.onResume()
        setPreferredRefreshRate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.arguments as? String
                if (url.isNullOrBlank()) {
                    result.error("INVALID_URL", "URL was null or blank", null)
                    return@setMethodCallHandler
                }

                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                val packageManager = applicationContext.packageManager
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setPreferredRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }

        val activityDisplay: Display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display ?: return
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        }

        val preferredMode = activityDisplay.supportedModes.maxByOrNull { it.refreshRate } ?: return

        val layoutParams = window.attributes
        if (layoutParams.preferredDisplayModeId != preferredMode.modeId) {
            layoutParams.preferredDisplayModeId = preferredMode.modeId
            window.attributes = layoutParams
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val frameRate = preferredMode.refreshRate
            runCatching {
                val windowClass = Window::class.java
                val setFrameRate = windowClass.getMethod(
                    "setFrameRate",
                    Float::class.javaPrimitiveType,
                    Int::class.javaPrimitiveType,
                    Int::class.javaPrimitiveType
                )
                val frameRateCompatibilityDefault = windowClass
                    .getField("FRAME_RATE_COMPATIBILITY_DEFAULT")
                    .getInt(null)
                val changeFrameRateAlways = windowClass
                    .getField("CHANGE_FRAME_RATE_ALWAYS")
                    .getInt(null)

                setFrameRate.invoke(
                    window,
                    frameRate,
                    frameRateCompatibilityDefault,
                    changeFrameRateAlways
                )
            }
        }
    }
}
