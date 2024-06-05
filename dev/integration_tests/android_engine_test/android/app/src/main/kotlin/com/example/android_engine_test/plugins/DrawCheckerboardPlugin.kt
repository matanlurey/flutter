package com.example.android_engine_test.plugins

import android.graphics.Color
import android.graphics.Paint
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.view.TextureRegistry.SurfaceProducer
import kotlin.properties.Delegates

// TODO(matanlurey): DefaultLifecycleObserver, ActivityAware are a result of bug XYZ, where Flutter
// on Android API 29+ destroys ImageReaders when the app is backgrounded, and plugins need to detect
// this state and redraw.
class DrawCheckerboardPlugin : FlutterPlugin, MethodCallHandler, DefaultLifecycleObserver,
    ActivityAware {
    companion object {
        const val SQUARES = 8
    }

    private lateinit var channel: MethodChannel
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding

    private var lastWidth by Delegates.notNull<Int>()
    private var lastHeight by Delegates.notNull<Int>()
    private var lifecycle: Lifecycle? = null
    private var producer: SurfaceProducer? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        channel = MethodChannel(binding.binaryMessenger, "draw_checkerboard")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "draw" -> {
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                if (width == null) {
                    return result.error(
                        "MISSING_PARAM",
                        null,
                        "The parameter 'width' was omitted but expected"
                    )
                }
                if (height == null) {
                    return result.error(
                        "MISSING_PARAM",
                        null,
                        "The parameter 'height' was omitted but expected"
                    )
                }
                draw(width, height)
                return result.success(producer!!.id())
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun draw(width: Int, height: Int) {
        lastWidth = width
        lastHeight = height

        if (producer == null) {
            producer = binding.textureRegistry.createSurfaceProducer()
        }
        val producer = this.producer!!
        producer.setSize(width, height)

        val surface = producer.surface
        val canvas = surface.lockCanvas(null)

        val size = minOf(width, height) / SQUARES
        val paint = Paint().apply {
            style = Paint.Style.FILL
        }

        for (row in 0..SQUARES) {
            for (col in 0..SQUARES) {
                val x = col * size
                val y = row * size

                paint.color = if ((row + col) % 2 == 0) Color.RED else Color.GREEN
                canvas.drawRect(
                    x.toFloat(), y.toFloat(), (x + size).toFloat(), (y + size).toFloat(), paint
                )
            }
        }

        surface.unlockCanvasAndPost(canvas)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val hidden = binding.lifecycle as HiddenLifecycleReference
        lifecycle = hidden.lifecycle
        lifecycle!!.addObserver(this)
    }

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDestroy(owner: LifecycleOwner) {
        lifecycle?.removeObserver(this)
    }

    override fun onResume(owner: LifecycleOwner) {
        if (producer == null) {
            return
        }
        draw(lastWidth, lastHeight)
    }
}
