package com.example.manage_notif_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.util.Log
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File

class MyNotificationListener : NotificationListenerService() {
    private val TAG = "MyNotificationListener"

    companion object {
        var instance: MyNotificationListener? = null
        // Store pending intents in memory to allow launching specific notification targets
        val activePendingIntents = HashMap<String, android.app.PendingIntent>()
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

        // Store active PendingIntent in memory map using the unique sbn.key
        val contentIntent = sbn.notification?.contentIntent
        val sbnKey = sbn.key
        if (contentIntent != null && sbnKey != null) {
            activePendingIntents[sbnKey] = contentIntent
        }

        // Save and cleanup using a single SQLite connection session with WAL enabled
        saveAndCleanupNotification(packageName, appName, title, body, timestamp, sbnKey)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn != null && sbn.key != null) {
            activePendingIntents.remove(sbn.key)
        }
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

    private fun getAppIconBytes(packageName: String): ByteArray? {
        try {
            val pm = packageManager
            val icon = pm.getApplicationIcon(packageName)
            
            val bitmap = when (icon) {
                is BitmapDrawable -> icon.bitmap
                else -> {
                    val width = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 128
                    val height = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 128
                    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    icon.setBounds(0, 0, canvas.width, canvas.height)
                    icon.draw(canvas)
                    bmp
                }
            }

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            return stream.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app icon bytes for $packageName: ${e.message}")
            return null
        }
    }

    private fun saveAndCleanupNotification(packageName: String, appName: String, title: String, body: String, timestamp: Long, sbnKey: String?) {
        try {
            val dbFile = File(applicationContext.filesDir.parentFile, "databases/manage_notifications.db")
            if (!dbFile.exists()) {
                dbFile.parentFile?.mkdirs()
            }
            
            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
            // Enable WAL mode to prevent any concurrent database locks
            db.enableWriteAheadLogging()
            
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
                    is_auto_removed INTEGER DEFAULT 0,
                    app_icon BLOB
                )
            """)

            // Attempt to alter table if column doesn't exist (in case database was created on v1)
            try {
                db.execSQL("ALTER TABLE notifications ADD COLUMN app_icon BLOB")
            } catch (e: Exception) {
                // Ignore if it already exists
            }

            val appIconBytes = getAppIconBytes(packageName)

            val values = ContentValues().apply {
                put("package_name", packageName)
                put("app_name", appName)
                put("title", title)
                put("body", body)
                put("timestamp", timestamp)
                put("is_read", 0)
                put("is_auto_removed", 0)
                put("app_icon", appIconBytes)
                put("channel_id", sbnKey)
            }

            val insertedId = db.insert("notifications", null, values)
            Log.d(TAG, "Saved to SQLite successfully. ID: $insertedId")

            // Apply cleanup rules inside the same database transaction/connection
            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val settingsJsonStr = prefs.getString("flutter.auto_remove_settings_v1", null)
            if (settingsJsonStr != null) {
                val settings = JSONObject(settingsJsonStr)
                val retentionHours = settings.optInt("retentionHours", 0)
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

                // Check blocked app or keyword for immediate purge
                var shouldPurge = false
                if (blockedApps.contains(packageName)) {
                    shouldPurge = true
                } else {
                    val lowercaseTitle = title.lowercase()
                    val lowercaseBody = body.lowercase()
                    for (keyword in blockedKeywords) {
                        if (keyword.isNotEmpty() && (lowercaseTitle.contains(keyword) || lowercaseBody.contains(keyword))) {
                            shouldPurge = true
                            break
                        }
                    }
                }

                if (shouldPurge) {
                    db.delete("notifications", "id = ?", arrayOf(insertedId.toString()))
                    Log.d(TAG, "Purged matching blocked notification successfully")
                }

                // Apply retention policy if enabled
                val totalHours = if (retentionHours > 0) retentionHours.toLong() else retentionDays.toLong() * 24
                if (totalHours > 0) {
                    val cutoffTimestamp = System.currentTimeMillis() - (totalHours * 60 * 60 * 1000)
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
            }

            db.close()

            // Send broadcast to notify UI
            val intent = Intent("com.example.manage_notif_app.NOTIFICATION_SAVED")
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error in saveAndCleanupNotification: ${e.message}", e)
        }
    }
}
