package com.example.foodopia.notifications

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.example.foodopia.MainActivity
import com.example.foodopia.R

// Receives scheduled notification alarms from Android and displays them.
// It also checks whether the notification was already read or whether Android
// notification permission is missing before showing anything.
class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(
            "foodopia_native_notifications",
            Context.MODE_PRIVATE
        )
        // Skip demo/scheduled notifications when the app has temporarily
        // disabled them, for example during testing.
        if (prefs.getBoolean("suppress_all_demo_notifications", false)) return

        val notificationKey = intent.getStringExtra("notificationKey")
        if (notificationKey != null) {
            // If Flutter already marked this notification as read, do not show
            // it again from Android.
            val wasRead = prefs.getBoolean(notificationKey, false)
            if (wasRead) return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val id = intent.getIntExtra("id", 1)
        val title = intent.getStringExtra("title") ?: "Foodopia"
        val message = intent.getStringExtra("message") ?: "You have a reminder"
        val channelId = intent.getStringExtra("channelId") ?: "foodopia_reminders_v2"
        // Open the main Flutter activity when the user taps the notification.
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            id,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, channelId)
        } else {
            android.app.Notification.Builder(context)
        }
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(android.app.Notification.BigTextStyle().bigText(message))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, notification)
    }
}
