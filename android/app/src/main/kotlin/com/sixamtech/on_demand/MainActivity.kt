package com.sixamtech.on_demand

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.sixamtech.demandium.user/provider_app"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openProviderApp" -> {
                        val packageName = call.argument<String>("packageName")
                            ?: "com.panunkaergar.providers"
                        @Suppress("UNCHECKED_CAST")
                        val fallbackPackages =
                            call.argument<List<String>>("fallbackPackageNames")
                                ?: emptyList()
                        val playStoreUrl = call.argument<String>("playStoreUrl")
                            ?: "https://play.google.com/store/apps/details?id=$packageName"
                        val opened = openProviderApp(
                            packageName,
                            fallbackPackages,
                            playStoreUrl,
                        )
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openProviderApp(
        primaryPackage: String,
        fallbackPackages: List<String>,
        playStoreUrl: String,
    ): Boolean {
        val packages = listOf(primaryPackage) + fallbackPackages
        for (pkg in packages.distinct()) {
            val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                return true
            }
        }

        openPlayStore(primaryPackage, playStoreUrl)
        return false
    }

    private fun openPlayStore(packageName: String, playStoreUrl: String) {
        val marketUri = Uri.parse("market://details?id=$packageName")
        try {
            val marketIntent = Intent(Intent.ACTION_VIEW, marketUri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(marketIntent)
            return
        } catch (_: Exception) {
            // Play Store app not available — open HTTPS listing.
        }

        val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(playStoreUrl)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(webIntent)
    }
}
