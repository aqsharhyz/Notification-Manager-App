package com.example.manage_notif_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.manage_notif_app/notifications"
    private var methodChannel: MethodChannel? = null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            methodChannel?.invokeMethod("onNotificationSaved", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val isGranted = isNotificationServiceEnabled()
                    result.success(isGranted)
                }
                "requestPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (ex: Exception) {
                            result.error("ERROR", ex.message, null)
                        }
                    }
                }
                "fetchActiveNotifications" -> {
                    val serviceInstance = MyNotificationListener.instance
                    if (serviceInstance != null) {
                        serviceInstance.fetchAndSaveActiveNotifications()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "launchNotificationAction" -> {
                    val sbnKey = call.argument<String>("sbnKey")
                    val pendingIntent = MyNotificationListener.activePendingIntents[sbnKey]
                    if (pendingIntent != null) {
                        try {
                            pendingIntent.send()
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Error sending pending intent: ${e.message}")
                            result.success(false)
                        }
                    } else {
                        // Fallback: Launch app using package manager
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val intent = packageManager.getLaunchIntentForPackage(packageName)
                                if (intent != null) {
                                    startActivity(intent)
                                    result.success(true)
                                } else {
                                    result.success(false)
                                }
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register broadcast receiver to notify Dart when a new notification is saved
        val filter = IntentFilter("com.example.manage_notif_app.NOTIFICATION_SAVED")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(receiver)
        } catch (e: Exception) {
            // Ignore if already unregistered
        }
        super.onDestroy()
    }

    private fun isNotificationServiceEnabled(): Boolean {
        return try {
            val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
            enabledPackages.contains(packageName)
        } catch (e: Exception) {
            val cn = android.content.ComponentName(this, MyNotificationListener::class.java)
            val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            flat != null && flat.contains(cn.flattenToString())
        }
    }
}
