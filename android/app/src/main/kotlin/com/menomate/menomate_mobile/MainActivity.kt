package com.menomate.menomate_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // IANA timezone for user-local calendar semantics (Batch 2D-1).
        // TimeZone.getDefault().id is always an IANA/Olson identifier
        // on Android (e.g. "Asia/Kolkata"), never a bare offset.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "menomate/timezone",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getLocalTimezone") {
                result.success(java.util.TimeZone.getDefault().id)
            } else {
                result.notImplemented()
            }
        }
    }
}
