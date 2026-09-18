package com.tianchuangya.islandsync

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.drawable.Drawable
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.CheckBox
import android.widget.EditText
import android.widget.Filter
import android.widget.Filterable
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast

/**
 * 「管理同步应用」：
 *  · 应用图标 + 名称 + 包名 + 大小
 *  · 搜索 / 排序（名称、已勾选优先、未勾选优先、应用大小）
 *  · 全选 / 取消全选
 */
class AppPickerDialog private constructor(
    private val activity: Activity,
    private val prefs: android.content.SharedPreferences,
    private val onSaved: (() -> Unit)?,
) {
    data class AppRow(
        val label: String,
        val pkg: String,
        val icon: Drawable?,
        val sizeBytes: Long,
        var checked: Boolean,
    )

    private val rows = mutableListOf<AppRow>()
    private val pad = (14 * activity.resources.displayMetrics.density).toInt()
    private lateinit var adapter: RowAdapter
    private lateinit var listView: ListView

    companion object {
        fun show(activity: Activity, prefs: android.content.SharedPreferences, onSaved: (() -> Unit)? = null) {
            AppPickerDialog(activity, prefs, onSaved).present()
        }
    }

    fun present() {
        val pm = activity.packageManager
        val launchIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val loaded = pm.queryIntentActivities(launchIntent, 0)
            .map {
                val pkg = it.activityInfo.packageName
                val size = try {
                    java.io.File(pm.getApplicationInfo(pkg, 0).sourceDir).length()
                } catch (e: Exception) { 0L }
                AppRow(
                    label = it.loadLabel(pm).toString(),
                    pkg = pkg,
                    icon = it.loadIcon(pm),
                    sizeBytes = size,
                    checked = false,
                )
            }
            .distinctBy { it.pkg }
            .sortedBy { it.label.lowercase() }
        val saved = prefs.getStringSet("watched_packages", null)
            ?: IslandNotificationListener.DEFAULT_WATCH_PACKAGES.toSet()
        loaded.forEach { it.checked = it.pkg in saved }
        rows.addAll(loaded)

        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad / 2, pad / 2, pad / 2, 0)
        }

        val search = EditText(activity).apply {
            hint = activity.getString(R.string.search_apps)
            setSingleLine(true)
            setBackgroundResource(R.drawable.input_bg)
            setPadding(pad / 2, pad / 3, pad / 2, pad / 3)
        }
        root.addView(search)

        val controls = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        controls.addView(actionLabel(activity.getString(R.string.select_all)) {
            rows.forEach { it.checked = true }
            adapter.notifyDataSetChanged()
        })
        controls.addView(actionLabel(activity.getString(R.string.select_none)) {
            rows.forEach { it.checked = false }
            adapter.notifyDataSetChanged()
        })
        controls.addView(sortLabel(), LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(controls)

        adapter = RowAdapter()
        listView = ListView(activity).apply {
            divider = null
            adapter = this@AppPickerDialog.adapter
            setOnItemClickListener { _, _, position, _ ->
                val row = this@AppPickerDialog.adapter.getItem(position)
                row.checked = !row.checked
                this@AppPickerDialog.adapter.notifyDataSetChanged()
            }
        }
        root.addView(listView, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            (activity.resources.displayMetrics.heightPixels * 0.55).toInt(),
        ))

        search.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
            override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
            override fun afterTextChanged(s: Editable?) {
                adapter.filter.filter(s?.toString() ?: "")
            }
        })

        AlertDialog.Builder(activity)
            .setTitle(R.string.manage_apps)
            .setView(root)
            .setPositiveButton(R.string.save) { _, _ ->
                val finalSet = rows.filter { it.checked }.map { it.pkg }.toSet()
                    .ifEmpty { IslandNotificationListener.DEFAULT_WATCH_PACKAGES.toSet() }
                prefs.edit()
                    .putStringSet("watched_packages", finalSet)
                    .putString("watch_apps", finalSet.joinToString(","))
                    .apply()
                Toast.makeText(activity, R.string.saved, Toast.LENGTH_SHORT).show()
                onSaved?.invoke()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private var sortMode = 0

    private fun sortLabel(): TextView {
        val modes = listOf(
            activity.getString(R.string.sort_name),
            activity.getString(R.string.sort_checked),
            activity.getString(R.string.sort_unchecked),
            activity.getString(R.string.sort_size),
        )
        return TextView(activity).apply {
            text = modes[sortMode]
            textSize = 13f
            setTextColor(0xFF9AA3B8.toInt())
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            setPadding(pad / 3, pad / 3, pad / 3, pad / 3)
            setOnClickListener {
                sortMode = (sortMode + 1) % modes.size
                text = modes[sortMode]
                applySort()
            }
        }
    }

    private fun actionLabel(text: String, onClick: () -> Unit): TextView =
        TextView(activity).apply {
            this.text = text
            textSize = 13f
            setTextColor(0xFF5B7CFF.toInt())
            gravity = Gravity.CENTER
            setPadding(pad / 3, pad / 3, pad / 3, pad / 3)
            setOnClickListener { onClick() }
        }

    private fun applySort() {
        val sorted = when (sortMode) {
            1 -> rows.sortedByDescending { it.checked }
            2 -> rows.sortedBy { it.checked }
            3 -> rows.sortedByDescending { it.sizeBytes }
            else -> rows.sortedBy { it.label.lowercase() }
        }
        rows.clear()
        rows.addAll(sorted)
        adapter.notifyDataSetChanged()
    }

    private inner class RowAdapter : BaseAdapter(), Filterable {

        private var filtered: List<AppRow> = rows
        private val density = activity.resources.displayMetrics.density
        private val pad2 = (12 * density).toInt()

        private val filter = object : Filter() {
            override fun performFiltering(constraint: CharSequence?): FilterResults {
                val q = constraint?.toString()?.trim() ?: ""
                val result = if (q.isEmpty()) rows
                else rows.filter { it.label.contains(q, true) || it.pkg.contains(q, true) }
                return FilterResults().apply { values = result; count = result.size }
            }

            override fun publishResults(constraint: CharSequence?, results: FilterResults?) {
                @Suppress("UNCHECKED_CAST")
                filtered = results?.values as? List<AppRow> ?: rows
                notifyDataSetChanged()
            }
        }

        override fun getFilter(): Filter = filter
        override fun getCount(): Int = filtered.size
        override fun getItem(position: Int): AppRow = filtered[position]
        override fun getItemId(position: Int): Long = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val holder: ViewHolder
            val view: View
            if (convertView == null) {
                view = LinearLayout(activity).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(pad2 / 2, pad2 / 3, pad2 / 2, pad2 / 3)
                }
                val icon = ImageView(activity)
                val texts = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(pad2 / 3, 0, pad2 / 3, 0)
                    addView(TextView(activity).apply { textSize = 14f; setTextColor(0xFFF2F4FA.toInt()) })
                    addView(TextView(activity).apply { textSize = 11f; setTextColor(0xFF9AA3B8.toInt()) })
                }
                val check = CheckBox(activity).apply { isClickable = false; isFocusable = false }
                view.addView(icon)
                view.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
                view.addView(check)
                holder = ViewHolder(
                    icon = icon,
                    title = texts.getChildAt(0) as TextView,
                    subtitle = texts.getChildAt(1) as TextView,
                    check = check,
                )
                view.tag = holder
            } else {
                view = convertView
                holder = view.tag as ViewHolder
            }

            val row = filtered[position]
            holder.icon.setImageDrawable(row.icon)
            holder.title.text = row.label
            holder.subtitle.text = "${row.pkg} · ${formatSize(row.sizeBytes)}"
            holder.check.isChecked = row.checked
            return view
        }

        private fun formatSize(bytes: Long): String = when {
            bytes <= 0 -> "未知大小"
            bytes < 1024 * 1024 -> "${bytes / 1024} KB"
            else -> String.format("%.1f MB", bytes / 1024.0 / 1024.0)
        }
    }

    private class ViewHolder(
        val icon: ImageView,
        val title: TextView,
        val subtitle: TextView,
        val check: CheckBox,
    )
}
