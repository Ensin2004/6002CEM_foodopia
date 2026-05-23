package com.example.foodopia

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.example.foodopia.notifications.NotificationReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "foodopia/notifications"
    private val notificationChannelId = "foodopia_reminders_v2"
    private val socialNotificationChannelId = "foodopia_social_notifications"
    private val notificationPrefsName = "foodopia_native_notifications"
    private val scheduledIdsKey = "scheduled_notification_ids"
    private val suppressAllKey = "suppress_all_demo_notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "scheduleNotification" -> {
                    val id = call.argument<Int>("id") ?: 1
                    val notificationKey = call.argument<String>("notificationKey") ?: "read_$id"
                    val title = call.argument<String>("title") ?: "Foodopia"
                    val message = call.argument<String>("message") ?: "You have a reminder"
                    val scheduledAt = call.argument<Long>("scheduledAt") ?: System.currentTimeMillis()
                    scheduleNotification(id, notificationKey, title, message, scheduledAt)
                    result.success(null)
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id") ?: 1
                    val notificationKey = call.argument<String>("notificationKey") ?: "read_$id"
                    cancelNotification(id, notificationKey)
                    result.success(null)
                }
                "cancelAllNotifications" -> {
                    cancelAllNotifications()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 5001)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            notificationChannelId,
            "Foodopia reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Meal planning and Foodopia activity reminders"
            enableVibration(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
        val socialChannel = NotificationChannel(
            socialNotificationChannelId,
            "Foodopia notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Follower, rating, comment, reply, and recipe notifications"
            enableVibration(true)
        }
        manager.createNotificationChannel(socialChannel)
    }

    private fun scheduleNotification(
        id: Int,
        notificationKey: String,
        title: String,
        message: String,
        scheduledAt: Long,
    ) {
        getSharedPreferences(notificationPrefsName, Context.MODE_PRIVATE)
            .also { prefs ->
                val ids = prefs.getStringSet(scheduledIdsKey, emptySet()).orEmpty().toMutableSet()
                ids.add(id.toString())
                prefs.edit()
                    .putBoolean(notificationKey, false)
                    .putBoolean(suppressAllKey, false)
                    .putStringSet(scheduledIdsKey, ids)
                    .apply()
            }

        val intent = Intent(this, NotificationReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("notificationKey", notificationKey)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("channelId", notificationChannelId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledAt,
                pendingIntent
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledAt,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                scheduledAt,
                pendingIntent
            )
        }
    }

    private fun cancelNotification(id: Int, notificationKey: String) {
        getSharedPreferences(notificationPrefsName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(notificationKey, true)
            .putBoolean(suppressAllKey, true)
            .apply()

        val intent = Intent(this, NotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancel(id)
    }

    private fun cancelAllNotifications() {
        val prefs = getSharedPreferences(notificationPrefsName, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(scheduledIdsKey, emptySet()).orEmpty()
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val editor = prefs.edit()
        editor.putBoolean(suppressAllKey, true)

        for (rawId in ids) {
            val id = rawId.toIntOrNull() ?: continue
            val intent = Intent(this, NotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            editor.putBoolean("read_$id", true)
        }

        editor.remove(scheduledIdsKey).apply()

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancelAll()
    }
}
