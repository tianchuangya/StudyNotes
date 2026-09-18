package com.tianchuangya.islandsync

import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Gitee contents API 封装：
 *  读  GET  /api/v5/repos/{owner}/{repo}/contents/{path}?ref={branch}&access_token=
 *  写  PUT  /api/v5/repos/{owner}/{repo}/contents/{path}  body={access_token,branch,sha,content(base64),message}
 */
object GiteeClient {

    data class Content(val sha: String?, val text: String?)

    private fun contentUrl(owner: String, repo: String, path: String, branch: String, token: String): String {
        val encoded = path.split("/").joinToString("/") { URLEncoder.encode(it, "UTF-8") }
        var url = "https://gitee.com/api/v5/repos/$owner/$repo/contents/$encoded?ref=" +
            URLEncoder.encode(branch, "UTF-8")
        if (token.isNotEmpty()) url += "&access_token=" + URLEncoder.encode(token, "UTF-8")
        return url
    }

    /** 返回 null 表示网络失败；Content(sha=null, text=null) 表示文件不存在（首次推送） */
    fun getContent(owner: String, repo: String, path: String, branch: String, token: String): Content? {
        return try {
            val connection = URL(contentUrl(owner, repo, path, branch, token)).openConnection() as HttpURLConnection
            connection.connectTimeout = 10_000
            connection.readTimeout = 15_000
            connection.requestMethod = "GET"
            val code = connection.responseCode
            if (code == 404) {
                Content(sha = null, text = null)
            } else if (code in 200..299) {
                val body = BufferedReader(InputStreamReader(connection.inputStream, Charsets.UTF_8)).use { it.readText() }
                val json = JSONObject(body)
                val text = if (json.optString("content").isNotEmpty()) {
                    String(Base64.decode(json.getString("content"), Base64.DEFAULT), Charsets.UTF_8)
                } else null
                Content(sha = json.optString("sha", null), text = text)
            } else null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 把完整 JSON 文本写入仓库。mutate 的返回值为新的 JSON 文本。
     * 内部先读取现有 sha，再 PUT 覆盖。
     */
    fun putContent(
        owner: String, repo: String, path: String, branch: String, token: String,
        newText: String,
    ): Boolean {
        return try {
            val existing = getContent(owner, repo, path, branch, token)
            val payload = JSONObject().apply {
                put("access_token", token)
                put("branch", branch)
                put("message", "island-sync: update")
                put("content", Base64.encodeToString(newText.toByteArray(Charsets.UTF_8), Base64.NO_WRAP))
                if (existing?.sha != null) put("sha", existing.sha)
            }
            val connection = URL(contentUrl(owner, repo, path, branch, token).substringBefore("?"))
                .openConnection() as HttpURLConnection
            connection.connectTimeout = 10_000
            connection.readTimeout = 20_000
            connection.requestMethod = if (existing?.sha != null) "PUT" else "POST"
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json;charset=UTF-8")
            connection.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
            connection.responseCode in 200..299
        } catch (e: Exception) {
            false
        }
    }
}

/** 同步到仓库的数据结构 */
object IslandState {
    const val MAX_NOTIFICATIONS = 20

    fun merge(
        oldText: String?,
        newNotifications: JSONArray,
        clipboard: JSONObject?,
    ): String {
        val state = JSONObject(if (oldText.isNullOrBlank()) "{}" else oldText)
        val list = JSONArray()
        val seen = HashSet<String>()
        val oldList = state.optJSONArray("notifications") ?: JSONArray()
        for (i in 0 until oldList.length()) {
            val item = oldList.getJSONObject(i)
            val id = item.optString("id")
            if (seen.add(id)) list.put(item)
        }
        for (i in 0 until newNotifications.length()) {
            val item = newNotifications.getJSONObject(i)
            val id = item.optString("id")
            if (seen.add(id)) list.put(item)
        }
        while (list.length() > MAX_NOTIFICATIONS) list.remove(0)
        state.put("updated", System.currentTimeMillis())
        state.put("notifications", list)
        if (clipboard != null) state.put("clipboard", clipboard)
        return state.toString()
    }
}
