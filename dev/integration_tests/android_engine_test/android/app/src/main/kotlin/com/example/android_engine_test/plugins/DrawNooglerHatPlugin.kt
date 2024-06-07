package com.example.android_engine_test.plugins

import android.media.MediaExtractor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DrawNooglerHatPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var binding: FlutterPluginBinding

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.binding = binding
    }

    private fun createMediaExtractor(dataSource: String): MediaExtractor {
        val extractor = MediaExtractor()
        extractor.setDataSource(dataSource)
        return extractor
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        TODO("Not yet implemented")
    }
}