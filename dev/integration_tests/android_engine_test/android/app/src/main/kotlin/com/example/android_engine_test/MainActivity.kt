package com.example.android_engine_test

import com.example.android_engine_test.plugins.DrawCheckerboardPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        flutterEngine.plugins.add(DrawCheckerboardPlugin())
    }
}
