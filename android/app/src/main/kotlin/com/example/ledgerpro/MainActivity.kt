package com.example.ledgerpro

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import android.content.Context

class MainActivity: FlutterFragmentActivity() {
    override fun provideFlutterEngine(@NonNull context: Context): FlutterEngine? {
        return provideEngine(this)
    }

    private fun provideEngine(context: Context): FlutterEngine {
        val engine = FlutterEngine(context)
        GeneratedPluginRegistrant.registerWith(engine)
        return engine
    }
}
