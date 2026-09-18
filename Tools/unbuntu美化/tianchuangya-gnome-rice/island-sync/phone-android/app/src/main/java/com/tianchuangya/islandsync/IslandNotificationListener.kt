package com.tianchuangya.islandsync

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * 系统通知监听。需要用户在「设置 → 通知使用权」里授权本应用。
 * 收到微信/QQ 通知后，做 1.5 秒合并（连发消息只推一次），再推送到 Gitee。
 */
class IslandNotificationListener : NotificationListenerService() {

    companion object {
        const val CHANNEL_ID = "island_sync_service"
        const val PREFS = "island_sync"
        val DEFAULT_WATCH_PACKAGES = setOf(
            "com.tencent.mm",
            "com.tencent.mobileqq",
            "com.tencent.mobileqqi",
            "com.tencent.tim",
        )

        fun packageNameToApp(packageName: String): String = when (packageName) {
            "com.tencent.mm" -> "wechat"
            "com.tencent.mobileqq" -> "qq"
            "com.tencent.mobileqqi" -> "qq"
            "com.tencent.tim" -> "qq"
            else -> packageName.substringAfterLast('.').take(24)
        }
    }

    private lateinit var prefs: SharedPreferences
    private lateinit var workerThread: HandlerThread
    private lateinit var workerHandler: Handler
    private val pending = JSONArray()
    private val pendingLock = Any()

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        workerThread = HandlerThread("island-push").also { it.start() }
        workerHandler = Handler(workerThread.looper)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.take(64) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.take(500) ?: ""
        rememberNotificationProbe(sbn.packageName, title, text, "received")
        if (title.isEmpty() && text.isEmpty()) return
        if (sbn.isOngoing) return

        val app = packageNameToApp(sbn.packageName)
        if (!isPackageWatched(sbn.packageName, app)) {
            rememberNotificationProbe(sbn.packageName, title, text, "filtered")
            return
        }
        val appLabel = appLabelForPackage(sbn.packageName).ifBlank { title.ifBlank { app } }

        val entry = JSONObject().apply {
            put("id", "${app}-${sbn.postTime}")
            put("app", app)
            put("packageName", sbn.packageName)
            put("appLabel", appLabel)
            put("title", title.ifEmpty { appLabel })
            put("text", text)
            put("ts", sbn.postTime)
        }

        synchronized(pendingLock) {
            pending.put(entry)
            workerHandler.removeCallbacksAndMessages(FLUSH_TOKEN)
            workerHandler.postDelayed({ flush() }, FLUSH_TOKEN, 1500)
        }
    }

    private fun isPackageWatched(packageName: String, app: String): Boolean {
        val watchedPackages = prefs.getStringSet("watched_packages", null)
        if (watchedPackages != null)
            return watchedPackages.contains(packageName)

        // 兼容旧版手写字段 watch_apps="wechat,qq"。
        val legacy = prefs.getString("watch_apps", "wechat,qq")
            ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() }
            ?: listOf("wechat", "qq")
        return legacy.isEmpty() || legacy.contains(app) || legacy.contains(packageName)
    }

    private fun appLabelForPackage(packageName: String): String = try {
        val pm = packageManager
        val info = pm.getApplicationInfo(packageName, 0)
        pm.getApplicationLabel(info).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        packageName
    }

    private val FLUSH_TOKEN = Any()

    private fun flush() {
        val batch = synchronized(pendingLock) {
            if (pending.length() == 0) return
            val copy = JSONArray()
            for (i in 0 until pending.length()) copy.put(pending.getJSONObject(i))
            while (pending.length() > 0) pending.remove(0)
            copy
        }

        val owner = prefs.getString("gitee_owner", "") ?: ""
        val repo = prefs.getString("gitee_repo", "") ?: ""
        val branch = prefs.getString("gitee_branch", "master") ?: "master"
        val path = prefs.getString("gitee_path", "island.json") ?: "island.json"
        val token = prefs.getString("gitee_token", "") ?: ""
        if (owner.isEmpty() || repo.isEmpty()) return

        val existing = GiteeClient.getContent(owner, repo, path, branch, token)
        val merged = IslandState.merge(existing?.text, batch, clipboard = null)
        val ok = GiteeClient.putContent(owner, repo, path, branch, token, merged)
        prefs.edit()
            .putLong("last_push_ts", System.currentTimeMillis())
            .putBoolean("last_push_ok", ok)
            .putString("last_push_detail", if (ok) "ok" else "failed")
            .apply()
        if (!ok && existing?.text != null) {
            // sha 冲突或网络抖动：稍后重试一次
            Thread.sleep(2000)
            val retryOk = GiteeClient.putContent(owner, repo, path, branch, token, merged)
            prefs.edit()
                .putLong("last_push_ts", System.currentTimeMillis())
                .putBoolean("last_push_ok", retryOk)
                .putString("last_push_detail", if (retryOk) "retry ok" else "retry failed")
                .apply()
        }
    }

    private fun rememberNotificationProbe(packageName: String, title: String, text: String, stage: String) {
        prefs.edit()
            .putLong("last_notification_probe_ts", System.currentTimeMillis())
            .putString("last_notification_probe_package", packageName)
            .putString("last_notification_probe_title", title)
            .putString("last_notification_probe_text", text.take(160))
            .putString("last_notification_probe_stage", stage)
            .apply()
    }

    override fun onDestroy() {
        workerThread.quitSafely()
        super.onDestroy()
    }
}
