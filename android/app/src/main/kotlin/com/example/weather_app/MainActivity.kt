package com.example.weather_app // Altere para o seu package real

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splash ->
                splash.remove() // Remove imediatamente o splash com ícone
            }
        }
        super.onCreate(savedInstanceState)
    }
}