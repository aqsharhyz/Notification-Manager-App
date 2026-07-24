package com.example.manage_notif_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONObject
import java.io.File

class MyNotificationListener : NotificationListenerService() {
    private val TAG = "MyNotificationListener"

    companion object {
        var instance: MyNotificationListener? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Notification Listener Service Created")
    }

    override fun onDestroy() {
        instance = null
        Log.d(TAG, "Notification Listener Service Destroyed")
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        // Skip notifications from our own app
        val packageName = sbn.packageName ?: "unknown"
        if (packageName == applicationContext.packageName) return

        val extras = sbn.notification?.extras
        val title = extras?.getCharSequence("android.title")?.toString() ?: ""
        val text = extras?.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras?.getCharSequence("android.bigText")?.toString() ?: ""
        
        var body = if (bigText.isNotEmpty()) bigText else text
        if (body.isEmpty()) {
            body = extras?.getCharSequence("android.subText")?.toString() ?: ""
        }

        // Skip completely empty notifications
        if (title.isEmpty() && body.isEmpty()) return

        val appName = try {
            val pm = packageManager
            val ai = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(ai).toString()
        } catch (e: Exception) {
            packageName.split(".").lastOrNull()?.replaceFirstChar { it.uppercase() } ?: packageName
        }

        val timestamp = System.currentTimeMillis()

        Log.d(TAG, "Notification Received: $packageName ($appName) | Title: $title | Body: $body")

        // 1. Saved First requirement: Insert notification to SQLite DB first
        val insertedId = saveToDatabase(packageName, appName, title, body, timestamp)
        if (insertedId == -1L) return

        // 2. Load settings and apply auto-remove and retention policies
        applyCleanupRules(packageName, title, body)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Handle notification removal if needed
    }

    fun fetchAndSaveActiveNotifications() {
        try {
            val activeNotifs = activeNotifications
            if (activeNotifs != null) {
                Log.d(TAG, "Fetching ${activeNotifs.size} active notifications from status bar")
                for (sbn in activeNotifs) {
                    onNotificationPosted(sbn)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching active notifications: ${e.message}", e)
        }
    }

    private fun saveToDatabase(packageName: String, appName: String, title: String, body: String, timestamp: Long): Long {
        var insertedId: Long = -1
        try {
            val dbFile = File(applicationContext.filesDir.parentFile, "databases/manage_notifications.db")
            if (!dbFile.exists()) {
                dbFile.parentFile?.mkdirs()
            }
            
            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
            
            db.execSQL("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    package_name TEXT NOT NULL,
                    app_name TEXT NOT NULL,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL,
                    timestamp INTEGER NOT NULL,
                    is_read INTEGER DEFAULT 0,
                    channel_id TEXT,
                    is_auto_removed INTEGER DEFAULT 0
                )
            """)

            val values = ContentValues().apply {
                put("package_name", packageName)
                put("app_name", appName)
                put("title", title)
                put("body", body)
                put("timestamp", timestamp)
                put("is_read", 0)
                put("is_auto_removed", 0)
            }

            insertedId = db.insert("notifications", null, values)
            db.close()
            Log.d(TAG, "Saved to SQLite successfully. ID: $insertedId")

            // Send broadcast to notify UI
            val intent = Intent("com.example.manage_notif_app.NOTIFICATION_SAVED")
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to SQLite: ${e.message}", e)
        }
        return insertedId
    }

    private fun applyCleanupRules(packageName: String, title: String, body: String) {
        try {
            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val settingsJsonStr = prefs.getString("flutter.auto_remove_settings_v1", null) ?: return
            
            val settings = JSONObject(settingsJsonStr)
            val retentionDays = settings.optInt("retentionDays", 0)
            
            val blockedAppsJson = settings.optJSONArray("blockedApps")
            val blockedApps = mutableListOf<String>()
            if (blockedAppsJson != null) {
                for (i in 0 until blockedAppsJson.length()) {
                    blockedApps.add(blockedAppsJson.getString(i))
                }
            }

            val blockedKeywordsJson = settings.optJSONArray("blockedKeywords")
            val blockedKeywords = mutableListOf<String>()
            if (blockedKeywordsJson != null) {
                for (i in 0 until blockedKeywordsJson.length()) {
                    blockedKeywords.add(blockedKeywordsJson.getString(i).lowercase())
                }
            }

            val excludedAppsJson = settings.optJSONArray("excludedAppsFromRetention")
            val excludedApps = mutableListOf<String>()
            if (excludedAppsJson != null) {
                for (i in 0 until excludedAppsJson.length()) {
                    excludedApps.add(excludedAppsJson.getString(i))
                }
            }

            val excludedKeywordsJson = settings.optJSONArray("excludedKeywordsFromRetention")
            val excludedKeywords = mutableListOf<String>()
            if (excludedKeywordsJson != null) {
                for (i in 0 until excludedKeywordsJson.length()) {
                    excludedKeywords.add(excludedKeywordsJson.getString(i).lowercase())
                }
            }

            val dbFile = File(applicationContext.filesDir.parentFile, "databases/manage_notifications.db")
            if (!dbFile.exists()) return
            
            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)

            // A. Check blocked app or keyword for immediate purge
            var shouldPurge = false
            if (blockedApps.contains(packageName)) {
                shouldPurge = true
                Log.d(TAG, "Notification matches blocked app: $packageName")
            } else {
                val lowercaseTitle = title.lowercase()
                val lowercaseBody = body.lowercase()
                for (keyword in blockedKeywords) {
                    if (keyword.isNotEmpty() && (lowercaseTitle.contains(keyword) || lowercaseBody.contains(keyword))) {
                        shouldPurge = true
                        Log.d(TAG, "Notification matches blocked keyword: $keyword")
                        break
                    }
                }
            }

            if (shouldPurge) {
                db.delete("notifications", "package_name = ? AND title = ? AND body = ?", arrayOf(packageName, title, body))
                Log.d(TAG, "Purged matching blocked notification successfully")
            }

            // B. Apply retention policy if enabled (retentionDays > 0)
            if (retentionDays > 0) {
                val cutoffTimestamp = System.currentTimeMillis() - (retentionDays.toLong() * 24 * 60 * 60 * 1000)
                val whereClauses = mutableListOf("timestamp < ?")
                val whereArgs = mutableListOf(cutoffTimestamp.toString())

                if (excludedApps.isNotEmpty()) {
                    val placeholders = excludedApps.map { "?" }.joinToString(",")
                    whereClauses.add("package_name NOT IN ($placeholders)")
                    whereArgs.addAll(excludedApps)
                }

                for (kw in excludedKeywords) {
                    if (kw.isNotEmpty()) {
                        whereClauses.add("LOWER(title) NOT LIKE ?")
                        whereClauses.add("LOWER(body) NOT LIKE ?")
                        whereArgs.add("%$kw%")
                        whereArgs.add("%$kw%")
                    }
                }

                val deletedRows = db.delete("notifications", whereClauses.joinToString(" AND "), whereArgs.toTypedArray())
                if (deletedRows > 0) {
                    Log.d(TAG, "Retention policy purged $deletedRows old notifications")
                }
            }

            db.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error applying cleanup rules: ${e.message}", e)
        }
    }
}
