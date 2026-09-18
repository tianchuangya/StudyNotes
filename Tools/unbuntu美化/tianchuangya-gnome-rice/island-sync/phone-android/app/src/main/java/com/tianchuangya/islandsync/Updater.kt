package com.tianchuangya.islandsync

import android.content.pm.PackageInstaller
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * 远程更新：从 GitHub 仓库读取 update.json（版本信息 + APK 直链 + SHA256），
 * 下载校验后交给系统 PackageInstaller 安装（弹出系统确认框，无需 root）。
 *
 * update.json 格式（由电脑端 publish-update.sh 自动生成并发布）：
 * {
 *   "versionCode": 2,
 *   "versionName": "1.1",
 *   "url": "https://github.com/<owner>/<repo>/releases/download/v1.1/island-sync-1.1.apk",
 *   "sha256": "<apk 摘要，小写十六进制>",
 *   "notes": "更新说明"
 * }
 */
object Updater {

    data class UpdateInfo(
        val versionCode: Int,
        val versionName: String,
        val url: String,
        val sha256: String,
        val notes: String,
    )

    /** 拉取 update.json；失败返回 null */
    fun fetchUpdateInfo(updateJsonUrl: String, token: String): UpdateInfo? {
        return try {
            val body = httpGet(updateJsonUrl, token) ?: return null
            val json = JSONObject(body)
            UpdateInfo(
                versionCode = json.optInt("versionCode", 0),
                versionName = json.optString("versionName", ""),
                url = json.optString("url", ""),
                sha256 = json.optString("sha256", "").lowercase(),
                notes = json.optString("notes", ""),
            )
        } catch (e: Exception) {
            null
        }
    }

    fun installedVersionCode(context: Context): Int =
        context.packageManager.getPackageInfo(context.packageName, 0).let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) it.longVersionCode.toInt()
            else @Suppress("DEPRECATION") it.versionCode
        }

    fun installedVersionName(context: Context): String =
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "?"

    /** 有新版本返回 UpdateInfo，否则返回 null */
    fun checkForUpdate(context: Context, updateJsonUrl: String, token: String): UpdateInfo? {
        if (updateJsonUrl.isBlank()) return null
        val info = fetchUpdateInfo(updateJsonUrl, token) ?: return null
        return if (info.versionCode > installedVersionCode(context) && info.url.isNotBlank()) info else null
    }

    /**
     * 下载 APK 到应用缓存目录并校验 SHA256。
     * 返回校验通过的文件；失败抛异常（message 为用户可读原因）。
     */
    fun downloadAndVerify(
        context: Context,
        info: UpdateInfo,
        token: String,
        onProgress: (Int) -> Unit,
    ): File {
        val dest = File(context.cacheDir, "update-${info.versionName}.apk")
        dest.parentFile?.mkdirs()

        val connection = URL(info.url).openConnection() as HttpURLConnection
        connection.connectTimeout = 15_000
        connection.readTimeout = 60_000
        connection.instanceFollowRedirects = true
        if (token.isNotBlank()) {
            connection.setRequestProperty("Authorization", "Bearer $token")
        }
        val code = connection.responseCode
        if (code !in 200..299) throw Exception("下载失败：HTTP $code")

        val total = connection.contentLengthLong
        val digest = MessageDigest.getInstance("SHA-256")
        connection.inputStream.use { input ->
            File(dest.path + ".part").outputStream().use { output ->
                val buffer = ByteArray(64 * 1024)
                var readTotal = 0L
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    output.write(buffer, 0, read)
                    digest.update(buffer, 0, read)
                    readTotal += read
                    if (total > 0) onProgress((readTotal * 100 / total).toInt())
                }
                output.flush()
            }
        }

        val downloaded = File(dest.path + ".part")
        if (info.sha256.isNotBlank()) {
            val actual = digest.digest().joinToString("") { "%02x".format(it) }
            if (actual != info.sha256) {
                downloaded.delete()
                throw Exception("SHA256 校验失败，已丢弃下载文件")
            }
        }
        downloaded.renameTo(dest) ?: throw Exception("下载文件移动失败")
        return dest
    }

    /**
     * 通过 PackageInstaller 提交安装会话，系统会弹出确认框。
     * 前提：用户已在系统设置里授予本应用「安装未知应用」权限，
     * 未授权时请先调 ensureInstallPermission()。
     */
    fun install(context: Context, apk: File) {
        val packageInstaller = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        val sessionId = packageInstaller.createSession(params)
        val session = packageInstaller.openSession(sessionId)
        try {
            session.openWrite("island-sync-apk", 0, apk.length()).use { out ->
                apk.inputStream().use { input ->
                    input.copyTo(out, 64 * 1024)
                }
                session.fsync(out)
            }
            val intent = Intent(context, UpdateStatusReceiver::class.java).apply {
                action = UpdateStatusReceiver.ACTION_INSTALL_STATUS
            }
            val pending = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                android.app.PendingIntent.getBroadcast(
                    context, sessionId, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE,
                )
            } else {
                android.app.PendingIntent.getBroadcast(
                    context, sessionId, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT,
                )
            }
            session.commit(pending.intentSender)
        } finally {
            session.close()
        }
    }

    fun canRequestInstall(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else true
    }

    fun openInstallPermissionSettings(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startActivity(
                Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES")
                    .setData(Uri.parse("package:${context.packageName}")),
            )
        }
    }

    private fun httpGet(url: String, token: String): String? {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 10_000
        connection.readTimeout = 15_000
        connection.instanceFollowRedirects = true
        if (token.isNotBlank()) connection.setRequestProperty("Authorization", "Bearer $token")
        val code = connection.responseCode
        if (code !in 200..299) return null
        return connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
    }
}
