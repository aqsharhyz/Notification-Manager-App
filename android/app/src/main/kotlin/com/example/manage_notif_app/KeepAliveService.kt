package com.example.manage_notif_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class KeepAliveService : Service() {
    companion object {
        private const val TAG = "KeepAliveService"
        const val CHANNEL_ID = "manage_notif_keep_alive_channel"
        const val NOTIFICATION_ID = 9901
        const val ACTION_START = "com.example.manage_notif_app.START_KEEP_ALIVE"
        const val ACTION_STOP = "com.example.manage_notif_app.STOP_KEEP_ALIVE"

        var isRunning = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, KeepAliveService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, KeepAliveService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            Log.d(TAG, "Stopping KeepAliveService")
            isRunning = false
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        Log.d(TAG, "Starting KeepAliveService as Foreground Service")
        val notification = buildForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true

        // Also ensure NotificationListenerService is bound
        MyNotificationListener.ensureServiceBound(applicationContext)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        Log.d(TAG, "KeepAliveService Destroyed")
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Layanan Pemantau Notifikasi (Background Monitor)",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Menjaga aplikasi tetap aktif di latar belakang untuk mencatat riwayat notifikasi"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Pemantau Notifikasi Aktif")
            .setContentText("Mencatat riwayat notifikasi secara otomatis di latar belakang")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .build()
    }
}
