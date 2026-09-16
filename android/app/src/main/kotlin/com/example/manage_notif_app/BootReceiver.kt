package com.example.manage_notif_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            // 1. Force rebind NotificationListenerService
            MyNotificationListener.ensureServiceBound(context)

            // 2. Check if KeepAlive is enabled in settings
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val settingsJsonStr = prefs.getString("flutter.auto_remove_settings_v1", null)
            var keepAliveEnabled = true
            if (settingsJsonStr != null) {
                try {
                    val settings = JSONObject(settingsJsonStr)
                    keepAliveEnabled = settings.optBoolean("keepAliveNotificationEnabled", true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing settings: ${e.message}")
                }
            }

            if (keepAliveEnabled) {
                KeepAliveService.start(context)
            }
        }
    }
}
