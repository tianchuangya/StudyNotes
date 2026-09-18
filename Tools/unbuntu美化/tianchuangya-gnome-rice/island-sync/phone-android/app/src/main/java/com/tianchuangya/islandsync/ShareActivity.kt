package com.tianchuangya.islandsync

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.Toast
import org.json.JSONObject

/**
 * 系统分享入口：任意应用「分享 → 灵动岛同步」即可把文本推送到电脑剪贴板。
 * （Android 10+ 限制后台读剪贴板，所以走分享菜单这条路。）
 */
class ShareActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val text = intent?.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        if (text.isBlank()) {
            finish()
            return
        }

        val prefs: SharedPreferences = getSharedPreferences(IslandNotificationListener.PREFS, MODE_PRIVATE)
        val owner = prefs.getString("gitee_owner", "") ?: ""
        val repo = prefs.getString("gitee_repo", "") ?: ""
        val branch = prefs.getString("gitee_branch", "master") ?: "master"
        val path = prefs.getString("gitee_path", "island.json") ?: "island.json"
        val token = prefs.getString("gitee_token", "") ?: ""

        if (owner.isEmpty() || repo.isEmpty()) {
            Toast.makeText(this, R.string.share_not_configured, Toast.LENGTH_LONG).show()
            finish()
            return
        }

        Toast.makeText(this, R.string.share_pushing, Toast.LENGTH_SHORT).show()
        Thread {
            val existing = GiteeClient.getContent(owner, repo, path, branch, token)
            val existingText = existing?.text
            val state = if (existingText.isNullOrBlank()) JSONObject() else JSONObject(existingText)
            state.put(
                "clipboard",
                JSONObject().put("text", text).put("ts", System.currentTimeMillis()).put("from", "phone"),
            )
            state.put("updated", System.currentTimeMillis())
            val ok = GiteeClient.putContent(owner, repo, path, branch, token, state.toString())
            runOnUiThread {
                Toast.makeText(
                    this,
                    if (ok) R.string.share_done else R.string.share_failed,
                    Toast.LENGTH_SHORT,
                ).show()
                finish()
            }
        }.start()
    }
}
