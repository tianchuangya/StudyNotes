package com.tianchuangya.islandsync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.content.pm.PackageInstaller
import android.widget.Toast

/** 接收 PackageInstaller 的安装结果并提示用户 */
class UpdateStatusReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE) ?: ""
        val toast = when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                // 需要用户点系统确认框：拉起确认 Activity
                val confirm = intent.getParcelableExtra<PendingIntent>(Intent.EXTRA_INTENT)
                try {
                    confirm?.send()
                    "请在弹出的窗口中确认安装"
                } catch (e: Exception) {
                    "无法拉起安装确认：${e.message}"
                }
            }
            PackageInstaller.STATUS_SUCCESS -> "更新安装成功，正在重启应用…"
            PackageInstaller.STATUS_FAILURE_ABORTED -> "已取消安装"
            PackageInstaller.STATUS_FAILURE_BLOCKED -> "安装被系统拦截：$message"
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE -> "APK 与设备不兼容"
            PackageInstaller.STATUS_FAILURE_INVALID -> "APK 文件无效"
            PackageInstaller.STATUS_FAILURE_CONFLICT -> "版本冲突"
            PackageInstaller.STATUS_FAILURE_STORAGE -> "存储空间不足"
            else -> "安装失败：$message"
        }
        Toast.makeText(context, toast, Toast.LENGTH_LONG).show()

        if (status == PackageInstaller.STATUS_SUCCESS) {
            // 安装成功会杀掉进程，这里做一次友好重启
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (launch != null) context.startActivity(launch)
        }
    }

    companion object {
        const val ACTION_INSTALL_STATUS = "com.tianchuangya.islandsync.INSTALL_STATUS"
    }
}
