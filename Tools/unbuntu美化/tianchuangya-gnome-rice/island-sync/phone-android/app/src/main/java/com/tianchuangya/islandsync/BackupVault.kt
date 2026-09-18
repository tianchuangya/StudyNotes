package com.tianchuangya.islandsync

import android.content.ContentValues
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * 可跨覆盖安装/卸载重装恢复的加密配置存档。
 *
 * 说明：
 * - Android Keystore 密钥会随 App 卸载一起删除，不适合“卸载后恢复”。
 * - 这里用 Android ID + 应用固定盐派生 AES-GCM 密钥；备份文件不是明文，
 *   同一台手机重装后可恢复，换手机则需要重新配置。
 * - 文件保存到公共 Documents/IslandSync，卸载 App 不会删除。
 */
object BackupVault {
    private const val FILE_NAME = "island-sync-settings.enc"
    private const val RELATIVE_DIR = "Documents/IslandSync/"
    private const val VERSION = 1
    private val SALT = "tianchuangya-island-sync-v1".toByteArray(Charsets.UTF_8)

    fun restoreIfNeeded(context: Context, prefs: SharedPreferences): Boolean {
        if (!prefs.getString("gitee_owner", "").isNullOrBlank() ||
            !prefs.getString("gitee_repo", "").isNullOrBlank() ||
            !prefs.getString("gitee_token", "").isNullOrBlank()
        ) return false
        return restore(context, prefs)
    }

    fun backup(context: Context, prefs: SharedPreferences): Boolean = try {
        val watched = prefs.getStringSet("watched_packages", emptySet()) ?: emptySet()
        val payload = JSONObject()
            .put("version", VERSION)
            .put("gitee_owner", prefs.getString("gitee_owner", "") ?: "")
            .put("gitee_repo", prefs.getString("gitee_repo", "") ?: "")
            .put("gitee_branch", prefs.getString("gitee_branch", "master") ?: "master")
            .put("gitee_path", prefs.getString("gitee_path", "island.json") ?: "island.json")
            .put("gitee_token", prefs.getString("gitee_token", "") ?: "")
            .put("watch_apps", prefs.getString("watch_apps", "") ?: "")
            .put("watched_packages", JSONArray(watched.sorted()))
            .put("backup_ts", System.currentTimeMillis())

        writeBytes(context, encrypt(context, payload.toString()))
        true
    } catch (_: Exception) {
        false
    }

    fun restore(context: Context, prefs: SharedPreferences): Boolean {
        return try {
            val bytes = readBytes(context) ?: return false
            val json = JSONObject(decrypt(context, bytes))
            val watched = mutableSetOf<String>()
            val arr = json.optJSONArray("watched_packages")
            if (arr != null) {
                for (i in 0 until arr.length())
                    watched.add(arr.getString(i))
            }

            prefs.edit()
                .putString("gitee_owner", json.optString("gitee_owner", ""))
                .putString("gitee_repo", json.optString("gitee_repo", ""))
                .putString("gitee_branch", json.optString("gitee_branch", "master").ifBlank { "master" })
                .putString("gitee_path", json.optString("gitee_path", "island.json").ifBlank { "island.json" })
                .putString("gitee_token", json.optString("gitee_token", ""))
                .putString("watch_apps", json.optString("watch_apps", ""))
                .putStringSet("watched_packages", watched)
                .apply()
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun encrypt(context: Context, plainText: String): ByteArray {
        val iv = ByteArray(12).also { SecureRandom().nextBytes(it) }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(context), GCMParameterSpec(128, iv))
        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        return JSONObject()
            .put("v", VERSION)
            .put("iv", Base64.encodeToString(iv, Base64.NO_WRAP))
            .put("data", Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .toString()
            .toByteArray(Charsets.UTF_8)
    }

    private fun decrypt(context: Context, bytes: ByteArray): String {
        val wrapper = JSONObject(String(bytes, Charsets.UTF_8))
        val iv = Base64.decode(wrapper.getString("iv"), Base64.NO_WRAP)
        val data = Base64.decode(wrapper.getString("data"), Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(context), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(data), Charsets.UTF_8)
    }

    private fun key(context: Context): SecretKeySpec {
        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            ?: context.packageName
        val spec = PBEKeySpec(androidId.toCharArray(), SALT, 120_000, 256)
        val bytes = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
        return SecretKeySpec(bytes, "AES")
    }

    private fun writeBytes(context: Context, bytes: ByteArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            findBackupUri(context)?.let { resolver.delete(it, null, null) }
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, FILE_NAME)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                put(MediaStore.MediaColumns.RELATIVE_PATH, RELATIVE_DIR)
            }
            val uri = resolver.insert(MediaStore.Files.getContentUri("external"), values)
                ?: error("Cannot create backup file")
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: error("Cannot open backup file")
        } else {
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "IslandSync")
            dir.mkdirs()
            File(dir, FILE_NAME).writeBytes(bytes)
        }
    }

    private fun readBytes(context: Context): ByteArray? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val uri = findBackupUri(context) ?: return null
            return context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
        }
        val file = File(
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "IslandSync"),
            FILE_NAME,
        )
        return if (file.exists()) file.readBytes() else null
    }

    private fun findBackupUri(context: Context): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
            return null
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val args = arrayOf(FILE_NAME, RELATIVE_DIR)
        context.contentResolver.query(collection, projection, selection, args, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(0)
                return Uri.withAppendedPath(collection, id.toString())
            }
        }
        return null
    }
}
