# 移交文档 — Ubuntu 美化项目（GLM-5.3 → Codex）

> 日期：2026-09-02。环境：Ubuntu 24.04 / GNOME Shell 46 / X11 / Intel Meteor Lake 核显。
> 本文档是全量交接，接手者请先读完再动手。

## 0. 最重要的操作纪律（前车之鉴）

- **绝对不要**手动运行 `gnome-shell --replace`、`kill -SEGV <shell>` 之类的命令去重载扩展。
  本项目上一轮因此崩过一次桌面，且手动启动的 shell 缺会话环境（扩展全部不激活、
  `disable-user-extensions` 会被置 true 造成"所有扩展消失"的假象）。
- 加载扩展新代码的正确方式：让用户按 **Alt+F2 → 输入 r → 回车**（X11 特有），或注销重登。
- 需要 GUI 自动化验证时，本机有免 root 的 xdotool：
  `LD_LIBRARY_PATH=$HOME/xdotool-root/usr/lib/x86_64-linux-gnu ~/xdotool-root/usr/bin/xdotool <cmd>`
  截图用 `ffmpeg -f x11grab -i :0 -frames:v 1 out.png`（分辨率 2880x1800）。
  这两个是调试用的临时产物，可删。

## 1. 项目总览与路径

| 内容 | 路径 |
|---|---|
| 美化项目主包（成果同步处） | `~/桌面/unbuntu美化/tianchuangya-gnome-rice/` |
| 灵动岛互通（新，独立文件夹） | `~/桌面/unbuntu美化/island-sync/` |
| 悬浮球扩展（已安装副本） | `~/.local/share/gnome-shell/extensions/curtain-wallpaper@local/` |
| 灵动岛扩展（已安装副本，未启用） | `~/.local/share/gnome-shell/extensions/island-sync@local/` |
| blur-my-shell 定制版（运行副本） | `~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/` |
| blur-my-shell 源码树（已同步补丁） | `~/blur-my-shell/src/` |
| Shell 主题 | `~/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css` |
| GTK3/4 玻璃 | `~/.config/gtk-3.0/gtk.css`、`~/.config/gtk-4.0/gtk.css` |
| 管线参数脚本 | `~/.local/share/codex-gnome-liquid-glass/configure-liquid-glass-pipeline.js` |
| 上一轮修改记录 | `~/桌面/unbuntu美化/tianchuangya-gnome-rice/docs/修改记录-2026-09-02.md` |

## 2. 已完成任务

### 2.1 悬浮球 Bug（原始需求 #1）✅ 已修复并验证
- 根因：旧版拖拽判定 5px 阈值 + `global.stage` 级 captured-event 追踪，触摸板抖动
  把点击误判为拖拽；release 被菜单抓取吞掉后无法自恢复 → "用过剪贴板后左键失效"。
- v2 重写：GNOME 官方 dnd 同款机制（`global.stage.grab(ball)` + `'event'` 信号，
  **注意必须连 'event' 不能连 'captured-event'，抓取期间捕获阶段不发生**）；
  阈值 = `St.Settings.drag_threshold`(8px) + 4px 余量；3.5s 安全超时。
- 新增：右键菜单（换壁纸/开壁纸夹/剪贴板/重置位置/锁屏）；剪贴板小按钮移出球点击区
  （原来压着球右下角 1/4）；切换回弹动画；**顶栏文字自适应壁纸亮度**
  （GdkPixbuf 采样壁纸顶部条带 luma>0.58 → `#panel` 挂 `cw-light-wallpaper` 类切深色字）。
- 验证记录：健康会话中点击/右键菜单/菜单项/拖拽/剪贴板后回归 **全部 PASS**
  （journal 有 `[CW] press btn=1` → `pull: next=...` 日志为证）。

### 2.2 液态玻璃重构（需求 #2）✅ 已部署，待重启生效+目检
- 调研结论（用户给的三个链接已消化）：
  - Apple 材质 = 模糊管可读性 + 边缘高光/折射管玻璃感 + 自适应（vibrancy/overLight）；
  - cocos 论坛帖：位移贴图折射配方（RG=128+N*127、strengthUV≈0.03、色散≈0.03、
    边缘高光用位移图梯度做渐变环）；
  - liquid-glass-react：displacementScale 70 / blur 0.0625 / aberration 2 / overLight。
- 落地参数（用户第二轮反馈后调整）：
  - **Dock = 透明清玻璃**：静态折射管线 `liquid_glass_dock`，tint 0 / blur 2 /
    strength 0.24 / fringing 0.015 / gloss 0.30；`static-blur=true`（Dock 在最底层，
    壁纸副本采样空间关系正确）；CSS 白边+内高光+泛光。
  - **顶栏 = 轻磨砂**：动态模糊 sigma 3、brightness 0.78（用户要求"加一点模糊字清楚"）。
  - **弹出面板 = 浅磨砂**：动态模糊 sigma 6、brightness **0.75**、CSS 蒙层
    **rgba(12,14,20,0.22)**（用户嫌黑，从 0.66/0.36 调浅）。
  - **BoxPointer 尖角修复**：`.popup-menu-boxpointer` 全系 `-arrow-*` 清零。
  - **headerbar 玻璃**：GTK3+GTK4，rgba(13,17,26,0.40) + 斜向光泽 + 四向内高光。
- blur-my-shell 定制版补丁（已同步 `~/blur-my-shell/src/` 和 rice 包 `blur-my-shell-patches/`）：
  - 新增 `conveniences/dynamic_corner.js`：corner.glsl 链为动态模糊层最外层效果，
    随 allocation 同步宽高 → 解决 GNOME 46 `Shell.BlurEffect` 只画矩形的问题；
  - `components/popup/blur_surface.js`：动态路径挂载/清理上述辅助；
  - `components/dash_to_dock.js`：同样圆角化 + **指针轮询自适应**
    （Dock 附近 24ms / 远离 250ms，原来常驻 42Hz 空耗）。

### 2.3 性能治理（需求 #3）✅ 已完成
- CoverflowAltTab `_subSwitchers is null`（每次 Alt+Tab 抛错）加空值守卫；
- 禁用 `system-monitor@gcampax`（与 Vitals 重复轮询）；清除失效条目
  `rounded-window-corners@fxgn`；
- 主题 CSS 第 4 值 box-shadow 修正（消除 "Ignoring excess values" 日志刷屏）；
- 遗留排查线索（浏览器滚动卡顿若仍在）：① 暂禁 `rounded-windows@marcosgt`（X11
  全窗口 shader，本轮未动）对比；② 关 runcat（常驻动画阻碍 GPU 空闲）；
  ③ 顶栏模糊单独关：`gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur false`。

### 2.4 灵动岛互通 island-sync（需求 #4）🔶 代码全写完，未联调
- **电脑端** `island-sync@local`（已部署 `~/.local/share/.../island-sync@local/`，
  schema 已编译，**未加入 enabled-extensions，未实测**）：
  - 顶部居中玻璃药丸（EASE_OUT_BACK 弹出）→ 点击展开卡片（打开微信/QQ/复制内容/关闭）；
  - Soup 轮询 Gitee contents API（默认 10s，GET → base64 解码 → JSON）；
  - 剪贴板：手机→电脑自动写入（识别 `clipboard.from=='phone'` 且 ts 更新）；
    电脑→手机走面板菜单"推送剪贴板"（读-改-写 PUT，带 sha）；
  - 面板指示器菜单（上次同步状态/立即同步/推送剪贴板）；
  - 设置 10 项：owner/repo/branch/path/token/poll-interval/island-duration/
    clipboard-sync/launch-map/watch-apps。
- **手机端** `phone-android/`（完整 Android Studio Kotlin 工程，零第三方依赖，
  **未编译**）：MainActivity 配置页+测试推送；IslandNotificationListener
  （通知监听，wechat/qq 过滤，1.5s 合并防连发刷屏）；GiteeClient（contents API
  读/PUT+sha+重试）；IslandForegroundService（specialUse FGS + START_STICKY）；
  BootReceiver 开机自启；ShareActivity（系统分享→推剪贴板，绕 Android 10+
  后台剪贴板限制）。
- 文档：`island-sync/README.md` 有完整三步配置说明；`island.json.example` 数据格式。

### 2.5 图标（需求 #5）❌ 未完成
- `tianchuangya-gnome-rice/scripts/install-whitesur-icons.sh` 已写好（装 WhiteSur +
  给其 index.theme 追加 AnimeApps 回退链 + 切换 gsettings），但会话中 GitHub/Gitee
  均连不通，**未执行**。网络恢复后让用户跑一次即可。

## 3. 当前未决事项（按优先级）

1. **[用户操作] 重启 shell**：Alt+F2 → r（或注销重登）。之后一次性生效：
   悬浮球回归（见 4.1）、玻璃新参数、顶栏模糊、BoxPointer 修复。
2. **[验证] 重启后逐项目检**：球点击/右键/拖拽；顶栏模糊+浅壁纸下顶栏深色字；
   快捷设置/日历/电源菜单（浅磨砂、无尖角）；Dock 清玻璃；headerbar（新开 GTK 应用）。
3. **[启用] 灵动岛扩展**：`gsettings` 加 `island-sync@local` 到 enabled-extensions
   （install.sh 里有现成命令，或扩展管理器里开）。设置里填 Gitee 仓库+令牌。
4. **[构建] APK**：用户本机 Android Studio 打开 `island-sync/phone-android/` 构建。
   工程无 gradle wrapper（未打包二进制），Android Studio 同步会自动生成。
5. **[联调] 端到端**：Gitee 私库 + 私人令牌（projects 权限）→ 手机测试推送 →
   电脑弹灵动岛 → 点击打开微信/QQ → 剪贴板双向。
6. **[图标] 网络恢复后跑 WhiteSur 安装脚本**。

## 4. 已知 Bug / 风险清单

### 4.1 悬浮球曾消失（已修，待重启确认）
最后一轮编辑时 `_pull()` 里残留了重复代码块（SyntaxError@418 → 扩展 ERROR 状态 →
球消失）。已修复并 `node --check` + `gjs` 双重验证通过，已部署到安装目录。
**重启前球不会回来**；若重启后仍 ERROR，查
`journalctl --user -b 0 | grep curtain`。

### 4.2 island-sync 待修小问题
- `APP_ICONS` 已由 Codex 改成系统稳定存在的 `chat-message-new-symbolic` /
  `user-available-symbolic`，不会再显示缺图图标。后续若追求二次元风格，可再自备 SVG。
- `launch-map` 默认值已由 Codex 改为 `{"wechat":"gtk-launch wechat","qq":"gtk-launch qq"}`，
  比直接 `spawnCommandLine("wechat")` 更稳。
- 首次运行若仓库里没有 island.json：GET 404 时 `_poll` 静默失败（指示器显示
  同步失败），需要先用手机 App「发送测试通知」创建文件（README 已写）。
- Gitee contents API 有速率限制；10s 轮询一般安全，改 5s 需观察 403。
- 两端同时写 JSON 会 sha 冲突：手机端有 2s 重试，电脑端 PUT 失败只报通知，
  联调时若频繁冲突可考虑加文件锁（按 updated 时间戳定输赢）。

Codex 已补充：
- `metadata.json` 增加 `settings-schema`，修复 `getSettings()` 启动 ERROR；
- 电脑端新增 `prefs.js`，扩展设置界面可直接填写 Gitee 参数和 token；
- 面板菜单新增「显示测试灵动岛」，可不依赖手机/Gitee 先测 UI；
- GJS 侧 `Pango.EllipsizeMode`、base64 写入编码已修；
- Gitee contents API 已修为“无 sha 用 POST 创建，有 sha 用 PUT 更新”；
- 已用 `shitianchuangya/test_lsland_sync` 初始化 `island.json`，并完成一次 PUT 测试通知；
- Android 端补 `ShareActivity` 的 `Intent` import、Android 13+ 通知权限请求、
  前台服务启动的版本兼容。
- Android APK 已由 Codex 命令行构建成功，输出：
  `~/桌面/unbuntu美化/apk/island-sync-debug.apk`。
  构建时还修复了按钮未绑定 `setOnClickListener` 的实质 bug，并补了项目内 launcher 图标。

### 4.3 玻璃参数是"纸面最优"
最后一轮参数（蒙层 0.22 / brightness 0.75 / Dock tint 0）**尚未在真实桌面目检过**，
用户对深浅敏感，重启后大概率还要微调。快速调参：
- 弹窗蒙层：`~/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css` 里搜
  `rgba(12, 14, 20, 0.22)`（Codex v2 注释块附近），改完 Alt+F2→r；
- 弹窗模糊/亮度：`GSETTINGS_SCHEMA_DIR=~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas gsettings set org.gnome.shell.extensions.blur-my-shell.popup brightness <0.6-0.9>`；
- Dock 管线：改 `configure-liquid-glass-pipeline.js` 后直接运行（脚本自带头注释）。

### 4.4 会话健康快照（2026-09-02 10:00 时点）
- shell 由 systemd 正常拉起（`systemctl --user is-active org.gnome.Shell@x11.service` = active）；
- `disable-user-extensions` = false（曾因异常会话被置 true，已复位——若再见"扩展
  全消失"先查这个）；
- 29 个扩展启用；`dynamic-panel@*` 两个版本都在 disabled 列表，正常。

## 5. 用户偏好备忘（沟通用）
- 中文交流；桌面是二次元风格（AnimeApps 图标、战双 fcitx 皮肤、随机动漫壁纸）；
  整体仿 Apple Liquid Glass；要"透明+边缘泛光折射"不要"纯深色底"；
- 壁纸目录 `~/壁纸`（21 张）；悬浮球默认位（2612,663），位置存
  `~/.config/curtain-wallpaper-position`；
- 用户明确提出：弹出层可以稍浑浊（承载文字），Dock 要清透；字体颜色要跟壁纸
  自适应，不要固定白；
- 小工具建议已给但未装：GSConnect（其实与 island-sync 功能重叠，装了可能重复，
  先问用户）、Just Perfection、EasyEffects。
