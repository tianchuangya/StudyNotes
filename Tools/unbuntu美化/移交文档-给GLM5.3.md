# 移交文档：Codex → GLM 5.3

更新时间：2026-09-03 00:52 CST  
用户：tianchuangya  
主题：Ubuntu GNOME 液态玻璃美化 + 灵动岛手机互通 + 悬浮球入口整合

---

## 0. 当前最重要结论

用户现在的主要问题不是电脑端链路，而是手机端真实 QQ/微信通知没有触发灵动岛。

已经验证/推断：

- 手机端“发送测试通知”可以让电脑端弹出灵动岛，说明：
  - Gitee 仓库链路基本通；
  - 电脑端 `island-sync@local` 轮询基本通；
  - 电脑端灵动岛 UI 基本通。
- 真实 QQ/微信消息不到电脑，最大嫌疑是：
  - 小米/HyperOS 没有把系统通知交给 `NotificationListenerService`；
  - 或者通知使用权/自启动/后台保活/电池策略没放开；
  - 或者 QQ/微信实际包名未被手机端勾选。

我已经在最新版 APK 中加入了“通知监听诊断”，下一步让用户安装新版 APK 后用它判断真实原因。

---

## 1. 关键目录与产物

### 1.1 主项目目录

```text
/home/tianchuangya/桌面/unbuntu美化/
```

### 1.2 独立灵动岛项目

```text
/home/tianchuangya/桌面/unbuntu美化/island-sync/
```

结构重点：

```text
island-sync/
├── pc-extension/island-sync@local/      # GNOME Shell 电脑端扩展
├── phone-android/                       # Android 手机端工程
├── README.md
└── island.json.example
```

### 1.3 一键美化包

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/
```

压缩包：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice.tar.gz
```

### 1.4 最新 APK

```text
/home/tianchuangya/桌面/unbuntu美化/apk/island-sync-debug.apk
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/apk/island-sync-debug.apk
```

最后一次构建时间约：2026-09-02 20:13～20:14 CST  
最后一次构建状态：`BUILD SUCCESSFUL`

构建命令：

```bash
cd /home/tianchuangya/桌面/unbuntu美化/island-sync/phone-android
/home/tianchuangya/.local/share/gradle-8.4/bin/gradle :app:assembleDebug
```

本机 Android SDK 配置：

```text
/home/tianchuangya/桌面/unbuntu美化/island-sync/phone-android/local.properties
sdk.dir=/home/tianchuangya/.local/share/android-sdk
```

---

## 2. 我已经完成的工作

## 2.1 GNOME 电脑端灵动岛扩展 `island-sync@local`

运行目录：

```text
/home/tianchuangya/.local/share/gnome-shell/extensions/island-sync@local/
```

同步副本：

```text
/home/tianchuangya/桌面/unbuntu美化/island-sync/pc-extension/island-sync@local/
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/island-sync/pc-extension/island-sync@local/
```

已完成改动：

1. 修复扩展启动/设置 schema 相关问题。
2. 增加电脑端顶栏手机图标菜单：
   - 立即同步；
   - 显示测试灵动岛；
   - 推送剪贴板到手机；
   - 上次同步状态。
3. 灵动岛 UI 支持：
   - 顶部药丸弹出；
   - 点击展开玻璃卡片；
   - 卡片内按钮：打开应用/复制内容/关闭。
4. 弹窗可拖动：
   - 拖动药丸或卡片标题栏移动；
   - 位置保存到：

```text
~/.config/island-sync-position
```

5. 弹窗尺寸改为按屏幕比例计算：
   - 卡片宽度约屏幕宽度 30%～42%；
   - 高度约屏幕高度 40%～54%；
   - 不再依赖固定小像素，避免高分屏内容/按钮溢出。
6. 长文本处理：
   - 正文自动换行；
   - 限制最大高度；
   - 避免按钮被挤出卡片。
7. “打开应用”按钮只在 `launch-map` 存在对应启动命令时显示。
8. Gitee 写入成功判断从只认 `200 OK` 改成接受所有 `2xx`，避免 `201 Created` 被误判失败。
9. 电脑端 `watch-apps` 默认值改为 `[]`：
   - 意味着电脑端默认接受手机端已筛选的通知；
   - 避免手机端勾选新 App 后被电脑端二次过滤吞掉。
10. 通知标题显示支持 `appLabel/packageName` 字段。

已重载并检查过：

```bash
gnome-extensions disable island-sync@local || true
gnome-extensions enable island-sync@local || true
gnome-extensions info island-sync@local
```

最后状态为：

```text
已启用: 是
状态: ACTIVE
```

---

## 2.2 Android 手机端 `island-sync`

工程目录：

```text
/home/tianchuangya/桌面/unbuntu美化/island-sync/phone-android/
```

关键源码：

```text
app/src/main/java/com/tianchuangya/islandsync/MainActivity.kt
app/src/main/java/com/tianchuangya/islandsync/IslandNotificationListener.kt
app/src/main/java/com/tianchuangya/islandsync/GiteeClient.kt
app/src/main/java/com/tianchuangya/islandsync/ShareActivity.kt
app/src/main/java/com/tianchuangya/islandsync/BackupVault.kt
app/src/main/AndroidManifest.xml
app/src/main/res/values/strings.xml
```

已完成改动：

### A. 应用列表管理

新增“管理同步应用”功能：

- 从手机已安装 Launcher 应用中读取列表；
- 用户可勾选要同步的 App；
- 默认同步：

```text
com.tencent.mm
com.tencent.mobileqq
com.tencent.mobileqqi
com.tencent.tim
```

注意：

- 这避免以后测试其他 App 时还要改代码；
- 手机端按真实包名过滤；
- 上传到 Gitee 的通知会带：

```json
{
  "app": "qq",
  "packageName": "com.tencent.mobileqq",
  "appLabel": "QQ"
}
```

### B. QQ/微信包名兼容

`IslandNotificationListener.packageNameToApp()` 已支持：

```text
com.tencent.mm          -> wechat
com.tencent.mobileqq   -> qq
com.tencent.mobileqqi  -> qq
com.tencent.tim        -> qq
```

### C. 通知监听诊断

新增按钮：

```text
通知监听诊断
```

它会显示：

- 通知使用权是否开启；
- 最近一次监听到的通知包名；
- 最近一次监听到的通知标题；
- 最近一次监听到的通知内容；
- 最近一次监听阶段：
  - `received`：监听服务收到了；
  - `filtered`：收到了但被包名过滤；
- 最近一次推送 Gitee 的时间和结果。

实现方式：

- `IslandNotificationListener.onNotificationPosted()` 入口处先记录 probe；
- 即便后续被过滤也能看到痕迹；
- 推送 Gitee 成功/失败也写入 SharedPreferences。

诊断意义：

- 如果用户发 QQ/微信消息后诊断页完全没变化，说明手机系统没有把通知交给 App；
- 如果显示 `filtered`，说明包名没勾选；
- 如果显示收到但推送失败，说明是 Gitee/token/网络问题；
- 如果显示收到且推送成功但电脑没弹，再查电脑端轮询。

### D. 小米/HyperOS 排障入口

新增按钮：

```text
打开应用详情/权限设置
打开电池优化设置
```

用于让用户快速进入小米系统设置。建议用户手动设置：

- 允许自启动；
- 电池策略设为无限制；
- 最近任务里锁定「灵动岛同步」；
- 通知使用权关掉再开一次；
- 允许通知；
- 如果系统有“后台弹出界面/后台运行/省电策略”之类，也要放开。

### E. 加密配置存档

新增文件：

```text
BackupVault.kt
```

功能：

- 保存配置时自动写入加密备份；
- App 启动时如果私有配置为空，会尝试自动恢复；
- App 内新增：
  - 备份配置到加密存档；
  - 从加密存档恢复配置。

备份文件位于手机公共文档目录：

```text
Documents/IslandSync/island-sync-settings.enc
```

备份内容：

- Gitee owner/repo/branch/path；
- Gitee 私人令牌；
- 已勾选同步应用包名列表。

加密方式：

- AES-GCM；
- 密钥由 Android ID + 应用固定盐派生。

设计取舍：

- 没用 Android Keystore，因为 Keystore 密钥随 App 卸载删除，无法支持“卸载后重装恢复”；
- 当前方案支持同一台手机卸载重装恢复；
- 换手机默认不能直接解密旧备份。

### F. 剪贴板策略说明

目前稳定功能：

- 手机 → 电脑：
  - 通过 Android 系统分享菜单把文本分享给「灵动岛同步」；
  - App 写入 Gitee；
  - 电脑端轮询后写入电脑剪贴板。
- 电脑 → 手机：
  - 电脑端顶栏菜单“推送剪贴板到手机”。

没有直接做“后台每复制一条就自动弹按钮询问是否发送”，原因：

- Android 10+ 限制后台读取剪贴板；
- 强做会很不稳定，尤其在小米/HyperOS 上更容易失效。

推荐后续路线：

- 手机端前台时可以监听剪贴板并提示“发送到电脑”；
- 后台时继续走系统分享菜单或通知快捷按钮；
- 电脑端剪贴板历史 UI 增加“手机剪贴板”分区，避免每条手机剪贴板自动覆盖电脑剪贴板。

---

## 2.3 悬浮球 `curtain-wallpaper@local`

运行目录：

```text
/home/tianchuangya/.local/share/gnome-shell/extensions/curtain-wallpaper@local/
```

一键包副本：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/extensions/curtain-wallpaper@local/
```

已完成工作：

1. 悬浮球点击直接随机切换 `~/壁纸` 中壁纸，弃用卡顿的 3D 动画。
2. 支持拖动，位置保存：

```text
~/.config/curtain-wallpaper-position
```

3. 修复点击/拖动误判和鼠标 release 丢失导致的“点击无反应”问题。
4. 增加右键菜单：
   - 换一张壁纸；
   - 打开壁纸文件夹；
   - 剪贴板历史；
   - 灵动岛设置；
   - 重载灵动岛扩展；
   - 打开灵动岛教程；
   - 重置悬浮球位置；
   - 锁屏。
5. 新增 `restart-curtain-wallpaper` 应急重载脚本。

悬浮球扩展已重载，最后状态：

```text
已启用: 是
状态: ACTIVE
```

---

## 2.4 GNOME 液态玻璃主题 / Blur My Shell / Dock

相关运行文件：

```text
/home/tianchuangya/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css
/home/tianchuangya/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/
```

一键包副本：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/theme/gnome-shell.css
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/blur-my-shell-patches/
```

已完成工作：

1. Dock 透明/玻璃效果调参。
2. Blur My Shell 的 Dash/Dock static blur 已关闭：

```bash
GSETTINGS_SCHEMA_DIR=~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas \
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur false
```

这样 Dock 不再死用桌面壁纸缓存，而是尽量实时采样后面的场景。

3. Dock blur 参数：

```text
sigma ≈ 4
brightness ≈ 0.72
```

4. Quick Settings / 弹出层圆角残留矩形问题：
   - CSS 做了大量 BoxPointer/PopupMenu 透明和圆角裁剪清理；
   - Blur My Shell 的 `dynamic_corner.js` 做了补丁。

关键补丁：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/blur-my-shell-patches/dynamic_corner.js
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/blur-my-shell-patches/blur_surface.js
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/blur-my-shell-patches/dash_to_dock.js
```

5. `install.sh` 已加入复制这些 patch 的逻辑。

重要限制：

- GNOME Shell CSS 本身无法像浏览器 `backdrop-filter` 那样真正做“实时折射下面窗口内容”；
- 必须依赖 Blur My Shell/Clutter effect；
- 如果用户仍看到某些地方像“贴了一张桌面壁纸”，可能是扩展层级和 GNOME Shell compositor 限制，不是 CSS 单独能解决。

---

## 2.5 一键包 `tianchuangya-gnome-rice`

目录：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice/
```

已包含：

- GNOME Shell 主题 `LiquidGlassTransparent`；
- AnimeApps 图标；
- nier 鼠标；
- Fcitx5 配置与皮肤；
- 微信 Fcitx5 启动环境修复；
- 微信 Linux 版安装检测；
- XFCE Terminal 背景图和配色；
- YesPlayMusic 自动安装逻辑；
- Ubuntu Dock 位置/透明配置；
- Dynamic Music Pill 顶栏音乐位置；
- 悬浮球扩展；
- 灵动岛扩展；
- Blur My Shell 动态玻璃补丁；
- 最新 APK 副本；
- README 和教程文档。

一键包压缩文件已重新生成：

```text
/home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice.tar.gz
```

---

## 3. 当前待完成 / 待验证

## 3.1 用户安装新版 APK 后验证真实 QQ/微信通知

这是下一步最关键事项。

用户安装：

```text
/home/tianchuangya/桌面/unbuntu美化/apk/island-sync-debug.apk
```

测试步骤：

1. 打开「灵动岛同步」App。
2. 点“授权读取系统通知”，确认已开启。
3. 点“管理同步应用”，确认微信、QQ 已勾选。
4. 点“启动常驻后台服务”。
5. 小米/HyperOS 设置：
   - 允许自启动；
   - 电池无限制；
   - 最近任务锁定 App；
   - 通知使用权关掉再打开一次。
6. 用小号给 QQ/微信发消息。
7. 回 App 点“通知监听诊断”。

根据诊断结果判断：

| 诊断结果 | 说明 | 下一步 |
|---|---|---|
| 最近监听记录完全不变 | 小米/HyperOS 没把通知交给 App | 查通知使用权、自启动、电池、后台锁定 |
| 阶段显示 `filtered` | App 收到通知但包名没勾选 | 管理同步应用里勾选对应包名 |
| 收到通知但推送失败 | Gitee/token/网络问题 | 检查 Gitee 配置 |
| 收到且推送成功，但电脑不弹 | 电脑端轮询/过滤/UI 问题 | 查 GNOME 扩展日志 |

电脑端日志查看：

```bash
journalctl --user -b --no-pager | rg -n "Island Sync|island-sync|JS ERROR|Extension island-sync" | tail -120
```

电脑端手动同步：

```text
顶栏手机图标 → 立即同步
```

---

## 3.2 小米 K90 Max / HyperOS 适配继续研究

用户设备：小米 K90 Max。

需要继续关注：

- HyperOS 是否对 `NotificationListenerService` 有额外限制；
- 是否需要引导用户打开：
  - 自启动；
  - 后台弹出界面；
  - 省电策略无限制；
  - 锁定最近任务；
  - 通知使用权重新授权；
  - 允许通知；
  - 关联启动/后台运行。

如果诊断证明系统没调用 `onNotificationPosted()`，代码本身无法绕过系统限制，只能引导权限或考虑其他方案。

可能替代方案：

- 使用 AccessibilityService 监听通知栏文字；
- 使用手机端前台常驻悬浮窗/通知读取辅助；
- 使用厂商 Push/通知转发 API；
- 使用局域网 WebSocket + 手机前台服务；
- 这些方案权限更重，需要用户明确接受。

---

## 3.3 手机剪贴板更好的交互

用户诉求：

- 不希望每复制一条都自动上传到电脑；
- 希望电脑端剪贴板历史里能切换到“手机剪贴板”；
- 希望手机复制后可以选择是否发送到电脑。

当前状态：

- 已实现系统分享菜单发送文本到电脑；
- 未实现后台自动读剪贴板弹按钮，原因是 Android 10+ 后台剪贴板限制。

推荐下一步：

1. Android App 前台时监听剪贴板变化；
2. 检测到复制后弹一个 App 内按钮“发送到电脑”；
3. 后台时继续使用系统分享菜单；
4. 电脑端 GNOME 剪贴板弹窗加入“手机剪贴板”分区；
5. Gitee JSON 增加：

```json
{
  "phone_clipboards": [
    {
      "id": "clip-xxx",
      "text": "...",
      "ts": 123456789,
      "device": "phone"
    }
  ]
}
```

电脑端显示时不自动覆盖电脑剪贴板，用户点选后再复制/粘贴。

---

## 3.4 文件传输功能

用户提过希望灵动岛拓展文件传输入口，目前未实现。

建议先做设计，不要直接塞入现有 Gitee JSON：

- 小文本/小图片可以走 Gitee contents 或 release/issue 附件；
- 大文件不适合走 Gitee contents API；
- 更合理方案：
  - 局域网 HTTP/WebDAV；
  - Syncthing；
  - KDE Connect/GSConnect；
  - 临时二维码上传；
  - SFTP。

如果继续用自研：

- 手机端开本地 HTTP server；
- 电脑端通过同网段 IP 拉取；
- 或电脑端开 server，手机推送。

---

## 3.5 灵动岛 UI 后续

已修：

- 弹窗可拖动；
- 尺寸按屏幕比例；
- 长文本换行；
- 按钮不溢出。

待继续打磨：

- 展开卡片更漂亮的液态玻璃；
- 对不同分辨率更细的 min/max；
- 卡片拖动手感；
- 多条通知堆叠；
- 通知历史；
- 按 app 图标显示真实图标。

---

## 3.6 Dock / Quick Settings 圆角残留

已做：

- CSS 清理 BoxPointer 透明；
- Blur My Shell dynamic corner patch；
- Dock static blur 关闭。

待用户肉眼验证：

- Dock 是否还像“贴桌面壁纸”；
- Quick Settings 是否还有尖角残留；
- 如果仍有，可能要继续进入 Blur My Shell 源码排查 actor clipping，而不是再堆 CSS。

---

## 4. 重要命令速查

### 4.1 重载电脑端灵动岛

```bash
gnome-extensions disable island-sync@local || true
gnome-extensions enable island-sync@local || true
gnome-extensions info island-sync@local
```

### 4.2 重载悬浮球

```bash
restart-curtain-wallpaper
```

或：

```bash
gnome-extensions disable curtain-wallpaper@local || true
gnome-extensions enable curtain-wallpaper@local || true
```

### 4.3 编译 APK

```bash
cd /home/tianchuangya/桌面/unbuntu美化/island-sync/phone-android
/home/tianchuangya/.local/share/gradle-8.4/bin/gradle :app:assembleDebug
```

构建产物：

```text
app/build/outputs/apk/debug/app-debug.apk
```

同步到用户安装位置：

```bash
cp /home/tianchuangya/桌面/unbuntu美化/island-sync/phone-android/app/build/outputs/apk/debug/app-debug.apk \
   /home/tianchuangya/桌面/unbuntu美化/apk/island-sync-debug.apk
```

### 4.4 重新打包一键包

```bash
cd /home/tianchuangya/桌面/unbuntu美化
tar --exclude='tianchuangya-gnome-rice/.git' -czf tianchuangya-gnome-rice.tar.gz tianchuangya-gnome-rice
```

### 4.5 查看 GNOME 扩展日志

```bash
journalctl --user -b --no-pager | rg -n "Island Sync|island-sync|JS ERROR|Extension island-sync" | tail -120
```

---

## 5. 安全注意事项

用户曾提供过 Gitee 私人令牌。不要把真实 token 写入：

- README；
- Markdown 教程；
- 一键包默认配置；
- git 仓库；
- 压缩包中的示例文件。

目前文档中只保留：

```text
你的私人令牌
```

占位符。

如需再次搜索真实 token，使用：

```bash
rg -n "7d0ebd37a6854435fabe5bc06deaa180|qian" \
  /home/tianchuangya/桌面/unbuntu美化/island-sync \
  /home/tianchuangya/桌面/unbuntu美化/tianchuangya-gnome-rice \
  --glob '!**/build/**' --glob '!**/.gradle/**'
```

之前跑过一次未发现明文命中。

---

## 6. 给 GLM 5.3 的建议接手顺序

建议不要一上来大改 UI，先把真实通知链路查实。

推荐顺序：

1. 让用户安装最新 APK：

```text
/home/tianchuangya/桌面/unbuntu美化/apk/island-sync-debug.apk
```

2. 按 README 测“通知监听诊断”。
3. 根据诊断判断问题层级：
   - 系统没调用 listener；
   - 手机端过滤；
   - 手机端 Gitee 推送失败；
   - 电脑端轮询失败。
4. 如果是小米系统没调用 listener，先做 HyperOS 权限引导，不要盲改 Gitee/电脑端。
5. 确认 QQ/微信真实通知同步后，再做：
   - 手机剪贴板分区；
   - 灵动岛通知历史；
   - 文件传输入口；
   - 更完整的悬浮球控制中心。

---

## 7. 当前状态一句话

电脑端灵动岛、悬浮球、美化包、APK 构建都已进入可用状态；真实 QQ/微信不同步现在需要新版 APK 的“通知监听诊断”来确认是否被小米/HyperOS 系统权限拦截。


---

## 8. 【2026-09-03 凌晨追加】GLM 5.3 回归后完成的工作

1. **电脑端修复**：`island-sync@local` 三处 `St.Clipboard.get_default(global.display)`
   改为无参调用（GNOME 46 会告警 "Too many arguments"）。需要一次 shell 重载生效
   （仅消除告警，功能此前不受影响）。
2. **APK 远程更新（新功能）**：
   - 手机端新增 `Updater.kt`（读 update.json → 版本对比 → 下载 → SHA256 校验 →
     PackageInstaller 安装）+ `UpdateStatusReceiver.kt`（安装结果 Toast + 成功重启）；
   - MainActivity 新增「更新源」输入框、「检查 App 更新」按钮、启动时静默检查；
   - Manifest 增加 `REQUEST_INSTALL_PACKAGES` 与状态接收器；
   - 已编译通过并产出新 APK（`apk/island-sync-debug.apk`，versionCode 1）。
3. **电脑端发布工具**：`island-sync/release/publish-update.sh`
   （构建→SHA256→GitHub Release 传 APK→contents API 提交 update.json），
   配置模板 `publish.conf.example`，教程 `release/README-发布配置.md`。
4. **待用户操作**：建 GitHub 更新仓库 + token → 填 `publish.conf`；手机 App 里
   填 update.json 直链。真实 QQ/微信通知链路排查（第 3.1 节）仍然优先。
