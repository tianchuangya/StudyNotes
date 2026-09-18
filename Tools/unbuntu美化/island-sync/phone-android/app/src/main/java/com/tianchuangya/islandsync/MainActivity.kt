package com.tianchuangya.islandsync

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.widget.Button
import android.widget.EditText
import android.widget.Toast

/**
 * 配置页（暗色玻璃风格）：通知后台 / Gitee 仓库 / App 更新 / 配置备份 / 关于作者。
 */
class MainActivity : Activity() {

    private lateinit var ownerEdit: EditText
    private lateinit var repoEdit: EditText
    private lateinit var branchEdit: EditText
    private lateinit var pathEdit: EditText
    private lateinit var tokenEdit: EditText
    private lateinit var watchEdit: EditText
    private lateinit var updateUrlEdit: EditText
    private var updateChecking = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPostNotificationPermissionIfNeeded()

        val prefs = getSharedPreferences(IslandNotificationListener.PREFS, MODE_PRIVATE)
        val restored = BackupVault.restoreIfNeeded(this, prefs)

        setContentView(R.layout.activity_main)
        bindFields()
        loadValues(prefs)
        bindButtons(prefs)

        if (restored)
            Toast.makeText(this, R.string.auto_restore_ok, Toast.LENGTH_LONG).show()

        // 启动时静默检查远程更新（有新版本才弹窗询问）
        val savedUpdateUrl = prefs.getString("update_json_url", "") ?: ""
        if (savedUpdateUrl.isNotBlank()) {
            Thread {
                val info = Updater.checkForUpdate(this, savedUpdateUrl, "")
                if (info != null) {
                    runOnUiThread { offerUpdate(info) }
                }
            }.start()
        }
    }

    private fun bindFields() {
        ownerEdit = findViewById(R.id.et_owner)
        repoEdit = findViewById(R.id.et_repo)
        branchEdit = findViewById(R.id.et_branch)
        pathEdit = findViewById(R.id.et_path)
        tokenEdit = findViewById(R.id.et_token)
        watchEdit = findViewById(R.id.et_watch)
        updateUrlEdit = findViewById(R.id.et_update_url)
    }

    private fun loadValues(prefs: android.content.SharedPreferences) {
        ownerEdit.setText(prefs.getString("gitee_owner", "") ?: "")
        repoEdit.setText(prefs.getString("gitee_repo", "") ?: "")
        branchEdit.setText(prefs.getString("gitee_branch", "master") ?: "master")
        pathEdit.setText(prefs.getString("gitee_path", "island.json") ?: "island.json")
        tokenEdit.setText(prefs.getString("gitee_token", "") ?: "")
        watchEdit.setText(watchedPackagesText(prefs))
        updateUrlEdit.setText(
            prefs.getString("update_json_url", "")?.takeIf { it.isNotBlank() }
                ?: getString(R.string.default_update_url))
    }

    private fun bindButtons(prefs: android.content.SharedPreferences) {
        findViewById<Button>(R.id.btn_save).setOnClickListener {
            saveCurrentFieldsToPrefs(prefs)
            BackupVault.backup(this, prefs)
            Toast.makeText(this, R.string.saved, Toast.LENGTH_SHORT).show()
        }

        findViewById<Button>(R.id.btn_manage_apps).setOnClickListener {
            AppPickerDialog.show(this, prefs) {
                watchEdit.setText(watchedPackagesText(prefs))
            }
        }

        findViewById<Button>(R.id.btn_diagnose).setOnClickListener {
            showNotificationDiagnostics(prefs)
        }

        findViewById<Button>(R.id.btn_grant_listener).setOnClickListener {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        }

        findViewById<Button>(R.id.btn_app_detail).setOnClickListener {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            })
        }

        findViewById<Button>(R.id.btn_battery).setOnClickListener {
            runCatching {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            }.onFailure {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            }
        }

        findViewById<Button>(R.id.btn_start_service).setOnClickListener {
            val serviceIntent = Intent(this, IslandForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            Toast.makeText(this, R.string.service_started, Toast.LENGTH_SHORT).show()
        }

        findViewById<Button>(R.id.btn_test_push).setOnClickListener {
            saveCurrentFieldsToPrefs(prefs)
            val owner = ownerEdit.text.toString().trim()
            val repo = repoEdit.text.toString().trim()
            if (owner.isEmpty() || repo.isEmpty()) {
                Toast.makeText(this, R.string.need_repo, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            Toast.makeText(this, R.string.pushing, Toast.LENGTH_SHORT).show()
            Thread {
                val branch = branchEdit.text.toString().trim().ifEmpty { "master" }
                val path = pathEdit.text.toString().trim().ifEmpty { "island.json" }
                val token = tokenEdit.text.toString().trim()
                val test = org.json.JSONObject()
                    .put("updated", System.currentTimeMillis())
                    .put("notifications", org.json.JSONArray()
                        .put(org.json.JSONObject()
                            .put("id", "test-${System.currentTimeMillis()}")
                            .put("app", "wechat")
                            .put("title", "灵动岛测试")
                            .put("text", "如果你在电脑上看到这条弹窗，链路就通了！")
                            .put("ts", System.currentTimeMillis())))
                val ok = GiteeClient.putContent(owner, repo, path, branch, token, test.toString())
                runOnUiThread {
                    Toast.makeText(
                        this,
                        if (ok) R.string.push_ok else R.string.push_failed,
                        Toast.LENGTH_LONG,
                    ).show()
                }
            }.start()
        }

        findViewById<Button>(R.id.btn_check_update).setOnClickListener {
            saveCurrentFieldsToPrefs(prefs)
            checkForUpdateManually()
        }

        findViewById<Button>(R.id.btn_reset_update_url).setOnClickListener {
            val defaultUrl = getString(R.string.default_update_url)
            updateUrlEdit.setText(defaultUrl)
            prefs.edit().putString("update_json_url", defaultUrl).apply()
            Toast.makeText(this, R.string.reset_done, Toast.LENGTH_SHORT).show()
        }

        findViewById<Button>(R.id.btn_about).setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle(getString(R.string.about_author))
                .setMessage(getString(R.string.about_content))
                .setPositiveButton(android.R.string.ok, null)
                .show()
        }
    }

    private fun requestPostNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun updateJsonUrl(): String = updateUrlEdit.text.toString().trim()

    private fun checkForUpdateManually() {
        if (updateChecking) {
            Toast.makeText(this, R.string.update_checking, Toast.LENGTH_SHORT).show()
            return
        }
        val url = updateJsonUrl()
        if (url.isBlank()) {
            Toast.makeText(this, R.string.update_need_url, Toast.LENGTH_LONG).show()
            return
        }
        updateChecking = true
        Toast.makeText(this, R.string.update_checking, Toast.LENGTH_SHORT).show()
        Thread {
            val info = try {
                Updater.checkForUpdate(this, url, "")
            } catch (e: Exception) {
                null
            }
            runOnUiThread {
                updateChecking = false
                if (info == null) {
                    val current = "v${Updater.installedVersionName(this)}"
                    Toast.makeText(this, getString(R.string.already_latest, current), Toast.LENGTH_LONG).show()
                } else {
                    offerUpdate(info)
                }
            }
        }.start()
    }

    private fun offerUpdate(info: Updater.UpdateInfo) {
        val notes = if (info.notes.isBlank()) "无" else info.notes
        AlertDialog.Builder(this)
            .setTitle(getString(R.string.update_available_title, info.versionName))
            .setMessage(getString(R.string.update_available_body, notes))
            .setPositiveButton(R.string.update_download_install) { _, _ -> startUpdate(info) }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun startUpdate(info: Updater.UpdateInfo) {
        if (!Updater.canRequestInstall(this)) {
            Toast.makeText(this, R.string.install_perm_needed, Toast.LENGTH_LONG).show()
            Updater.openInstallPermissionSettings(this)
            return
        }
        Toast.makeText(this, R.string.update_downloading, Toast.LENGTH_SHORT).show()
        Thread {
            try {
                var lastReported = -25
                val apk = Updater.downloadAndVerify(this, info, "") { percent ->
                    if (percent - lastReported >= 25) {
                        lastReported = percent
                        runOnUiThread {
                            Toast.makeText(this, getString(R.string.update_progress, percent), Toast.LENGTH_SHORT).show()
                        }
                    }
                }
                runOnUiThread { Toast.makeText(this, R.string.update_verifying_ok, Toast.LENGTH_SHORT).show() }
                Updater.install(this, apk)
            } catch (e: Exception) {
                runOnUiThread {
                    Toast.makeText(this, getString(R.string.update_failed, e.message), Toast.LENGTH_LONG).show()
                }
            }
        }.start()
    }

    private fun saveCurrentFieldsToPrefs(prefs: android.content.SharedPreferences) {
        prefs.edit()
            .putString("gitee_owner", ownerEdit.text.toString().trim())
            .putString("gitee_repo", repoEdit.text.toString().trim())
            .putString("gitee_branch", branchEdit.text.toString().trim().ifEmpty { "master" })
            .putString("gitee_path", pathEdit.text.toString().trim().ifEmpty { "island.json" })
            .putString("gitee_token", tokenEdit.text.toString().trim())
            .putString("watch_apps", watchEdit.text.toString().trim())
            .putStringSet("watched_packages", parseWatchedPackages(watchEdit.text.toString()))
            .putString("update_json_url", updateUrlEdit.text.toString().trim())
            .commit()
    }

    private fun watchedPackagesText(prefs: android.content.SharedPreferences): String {
        val saved = prefs.getStringSet("watched_packages", null)
        if (!saved.isNullOrEmpty())
            return saved.sorted().joinToString(",")
        val legacy = prefs.getString("watch_apps", "wechat,qq") ?: "wechat,qq"
        return if (legacy == "wechat,qq")
            IslandNotificationListener.DEFAULT_WATCH_PACKAGES.sorted().joinToString(",")
        else legacy
    }

    private fun parseWatchedPackages(text: String): Set<String> {
        val items = text.split(",").map { it.trim() }.filter { it.isNotEmpty() }.toSet()
        return items.ifEmpty { IslandNotificationListener.DEFAULT_WATCH_PACKAGES }
    }

    private fun showNotificationDiagnostics(prefs: android.content.SharedPreferences) {
        val listenerEnabled = isNotificationListenerEnabled()
        val watched = parseWatchedPackages(watchEdit.text.toString()).sorted().joinToString("\n")
        val probeTs = prefs.getLong("last_notification_probe_ts", 0L)
        val pushTs = prefs.getLong("last_push_ts", 0L)
        val message = """
            通知使用权：${if (listenerEnabled) "已开启" else "未开启/系统未生效"}

            最近监听记录：
            时间：${formatTime(probeTs)}
            阶段：${prefs.getString("last_notification_probe_stage", "无")}
            包名：${prefs.getString("last_notification_probe_package", "无")}
            标题：${prefs.getString("last_notification_probe_title", "无")}
            内容：${prefs.getString("last_notification_probe_text", "无")}

            最近推送：
            时间：${formatTime(pushTs)}
            结果：${if (prefs.getBoolean("last_push_ok", false)) "成功" else "未成功/暂无"}
            详情：${prefs.getString("last_push_detail", "无")}

            当前勾选包名：
            $watched

            如果这里“通知使用权已开启”，但发 QQ/微信后“最近监听记录”完全不变，说明小米/HyperOS 没有把通知交给本 App。请打开自启动、后台无限制、省电策略无限制，并在最近任务里锁定本 App。
        """.trimIndent()

        AlertDialog.Builder(this)
            .setTitle(R.string.diagnose_listener)
            .setMessage(message)
            .setPositiveButton(R.string.refresh) { _, _ -> showNotificationDiagnostics(prefs) }
            .setNeutralButton(R.string.test_push) { _, _ ->
                Toast.makeText(this, R.string.pushing, Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(android.R.string.ok, null)
            .show()
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return enabled.split(":").any {
            val component = android.content.ComponentName.unflattenFromString(it)
            TextUtils.equals(component?.packageName, packageName)
        }
    }

    private fun formatTime(ts: Long): String {
        if (ts <= 0) return "无"
        return java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
            .format(java.util.Date(ts))
    }
}
